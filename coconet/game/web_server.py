"""HTTP server for the standalone Reef Rescuer web game."""

from __future__ import annotations

import argparse
import json
import logging
import mimetypes
import os
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

from coconet.game.help_text import how_to_play_payload
from coconet.game.leaderboard import LeaderboardStore, default_scores_path
from coconet.game.session import SessionStore, intervention_catalog
from coconet.game.sim import INTERVENTION_COSTS

logger = logging.getLogger(__name__)
STATIC_DIR = Path(__file__).resolve().parent / "static"


def _json_response(handler: BaseHTTPRequestHandler, payload: dict[str, Any], *, status: int = 200) -> None:
    data = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(data)


def _read_json_body(handler: BaseHTTPRequestHandler) -> dict[str, Any]:
    length = int(handler.headers.get("Content-Length", "0"))
    if length <= 0:
        return {}
    raw = handler.rfile.read(length)
    parsed = json.loads(raw.decode("utf-8"))
    if not isinstance(parsed, dict):
        msg = "Expected a JSON object"
        raise ValueError(msg)
    return parsed


def make_handler(
    store: SessionStore,
    leaderboard: LeaderboardStore,
) -> type[BaseHTTPRequestHandler]:
    static_root = STATIC_DIR.resolve()

    class ReefRescuerHandler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args: object) -> None:
            logger.debug("%s - %s", self.address_string(), format % args)

        def do_GET(self) -> None:
            parsed = urlparse(self.path)
            route = parsed.path.rstrip("/") or "/"

            if route == "/api/health":
                _json_response(self, {"status": "ok"})
                return
            if route == "/api/interventions":
                _json_response(self, {"interventions": intervention_catalog()})
                return
            if route == "/api/help":
                _json_response(self, how_to_play_payload())
                return
            if route == "/api/leaderboard":
                _json_response(self, leaderboard.payload())
                return
            if route.startswith("/api/sessions/"):
                session_id = route.removeprefix("/api/sessions/")
                session = store.get(session_id)
                if session is None:
                    self.send_error(HTTPStatus.NOT_FOUND, "Session not found")
                    return
                _json_response(self, session.to_payload())
                return

            rel = route.lstrip("/") or "index.html"
            target = (static_root / unquote(rel)).resolve()
            if not str(target).startswith(str(static_root)):
                self.send_error(HTTPStatus.FORBIDDEN, "Forbidden")
                return
            if target.is_dir():
                target = target / "index.html"
            if not target.is_file():
                target = static_root / "index.html"
            self._serve_path(target)

        def do_POST(self) -> None:
            parsed = urlparse(self.path)
            route = parsed.path.rstrip("/")

            try:
                if route == "/api/sessions":
                    session = store.create()
                    _json_response(self, session.to_payload(), status=HTTPStatus.CREATED)
                    return

                if route == "/api/leaderboard/check":
                    body = _read_json_body(self)
                    survival_seconds = body.get("survival_seconds")
                    if not isinstance(survival_seconds, int) or survival_seconds < 0:
                        _json_response(
                            self,
                            {"error": "survival_seconds must be a non-negative integer"},
                            status=HTTPStatus.BAD_REQUEST,
                        )
                        return
                    _json_response(self, leaderboard.check(survival_seconds))
                    return

                if route == "/api/leaderboard":
                    body = _read_json_body(self)
                    name = body.get("name")
                    survival_seconds = body.get("survival_seconds")
                    if not isinstance(name, str):
                        _json_response(
                            self,
                            {"error": "name is required"},
                            status=HTTPStatus.BAD_REQUEST,
                        )
                        return
                    if not isinstance(survival_seconds, int) or survival_seconds < 0:
                        _json_response(
                            self,
                            {"error": "survival_seconds must be a non-negative integer"},
                            status=HTTPStatus.BAD_REQUEST,
                        )
                        return
                    _json_response(self, leaderboard.submit(name, survival_seconds))
                    return

                if route.endswith("/restart") and route.startswith("/api/sessions/"):
                    session_id = route.removeprefix("/api/sessions/").removesuffix("/restart")
                    session = store.get(session_id)
                    if session is None:
                        self.send_error(HTTPStatus.NOT_FOUND, "Session not found")
                        return
                    session.restart()
                    _json_response(self, session.to_payload())
                    return

                if route.endswith("/interventions") and route.startswith("/api/sessions/"):
                    session_id = route.removeprefix("/api/sessions/").removesuffix("/interventions")
                    session = store.get(session_id)
                    if session is None:
                        self.send_error(HTTPStatus.NOT_FOUND, "Session not found")
                        return
                    body = _read_json_body(self)
                    kind = body.get("kind")
                    if not isinstance(kind, str) or kind not in INTERVENTION_COSTS:
                        _json_response(
                            self,
                            {"error": f"Unknown intervention: {kind!r}"},
                            status=HTTPStatus.BAD_REQUEST,
                        )
                        return
                    event = session.intervene(kind)  # type: ignore[arg-type]
                    payload = session.to_payload()
                    payload["event"] = {"message": event.message, "kind": event.kind}
                    _json_response(self, payload)
                    return
            except json.JSONDecodeError:
                _json_response(self, {"error": "Invalid JSON"}, status=HTTPStatus.BAD_REQUEST)
                return
            except ValueError as exc:
                _json_response(self, {"error": str(exc)}, status=HTTPStatus.BAD_REQUEST)
                return

            self.send_error(HTTPStatus.NOT_FOUND, "Not found")

        def _serve_path(self, path: Path) -> None:
            data = path.read_bytes()
            ctype = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

    return ReefRescuerHandler


def run_server(
    *,
    host: str = "127.0.0.1",
    port: int = 8080,
    scores_file: Path | None = None,
) -> None:
    store = SessionStore()
    scores_path = scores_file or default_scores_path()
    leaderboard = LeaderboardStore(scores_path)
    handler = make_handler(store, leaderboard)
    server = ThreadingHTTPServer((host, port), handler)
    logger.info("Reef Rescuer web game listening on http://%s:%s", host, port)
    logger.info("Leaderboard file: %s", scores_path)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down Reef Rescuer web server")
    finally:
        server.server_close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the Reef Rescuer standalone web game.")
    parser.add_argument("--host", default="127.0.0.1", help="Bind address (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8080, help="Port (default: 8080)")
    parser.add_argument(
        "--scores-file",
        default=os.environ.get("REEF_RESCUER_SCORES_FILE"),
        help="JSON file for the top-10 leaderboard (default: ~/.reef-rescuer/leaderboard.json)",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
    )
    args = parser.parse_args()
    logging.basicConfig(level=getattr(logging, args.log_level))
    scores_file = Path(args.scores_file) if args.scores_file else None
    run_server(host=args.host, port=args.port, scores_file=scores_file)


if __name__ == "__main__":
    main()
