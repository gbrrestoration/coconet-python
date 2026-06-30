"""Local HTTP server for the bundled CoCoNet chart viewer."""

from __future__ import annotations

import logging
import mimetypes
import socket
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

logger = logging.getLogger(__name__)


def find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def _make_handler(
    dist_dir: Path,
    output_file: Path | None,
) -> type[BaseHTTPRequestHandler]:
    dist_root = dist_dir.resolve()
    resolved_output = output_file.resolve() if output_file is not None else None

    class VizHttpHandler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args: object) -> None:
            logger.debug("%s - %s", self.address_string(), format % args)

        def do_GET(self) -> None:
            parsed = urlparse(self.path)
            route = parsed.path.rstrip("/") or "/"

            if route == "/api/model-output":
                self._serve_model_output()
                return
            if route == "/api/health":
                self._send_bytes(b"ok", "text/plain")
                return

            rel = route.lstrip("/") or "index.html"
            target = (dist_root / unquote(rel)).resolve()
            if not str(target).startswith(str(dist_root)):
                self.send_error(403, "Forbidden")
                return
            if target.is_dir():
                target = target / "index.html"
            if not target.is_file():
                target = dist_root / "index.html"
            self._serve_path(target)

        def _serve_model_output(self) -> None:
            if resolved_output is None or not resolved_output.is_file():
                self.send_error(404, "Model output not available")
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/csv; charset=utf-8")
            self.send_header("X-Coconet-Filename", resolved_output.name)
            self.send_header("X-Coconet-File-Size", str(resolved_output.stat().st_size))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            with resolved_output.open("rb") as handle:
                while chunk := handle.read(1024 * 1024):
                    self.wfile.write(chunk)

        def _serve_path(self, path: Path) -> None:
            data = path.read_bytes()
            ctype = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
            self._send_bytes(data, ctype)

        def _send_bytes(self, data: bytes, content_type: str) -> None:
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

    return VizHttpHandler


class VizServer:
    """Serve the built ``viz`` app and expose the model output CSV."""

    def __init__(self, dist_dir: Path, output_file: Path | None = None) -> None:
        if not dist_dir.is_dir():
            raise FileNotFoundError(f"Chart viewer assets not found: {dist_dir}")
        self.dist_dir = dist_dir.resolve()
        self.output_file = output_file.resolve() if output_file is not None else None
        self.port = find_free_port()
        handler = _make_handler(self.dist_dir, self.output_file)
        self._httpd = ThreadingHTTPServer(("127.0.0.1", self.port), handler)
        self._thread = threading.Thread(target=self._httpd.serve_forever, daemon=True)

    @property
    def url(self) -> str:
        return f"http://127.0.0.1:{self.port}/?embedded=1"

    def start(self) -> None:
        self._thread.start()
        logger.info("Chart viewer server listening on %s", self.url)

    def stop(self) -> None:
        self._httpd.shutdown()
        self._thread.join(timeout=3)
