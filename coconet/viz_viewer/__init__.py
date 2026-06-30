"""Open the CoCoNet chart viewer for a model output CSV."""

from __future__ import annotations

import argparse
import logging
import subprocess
import sys
import webbrowser
from pathlib import Path

from coconet.app_paths import viz_dist_dir
from coconet.logging_utils import configure_logging
from coconet.viz_server import VizServer

logger = logging.getLogger(__name__)


def run_viewer(output_file: Path, *, use_pywebview: bool = True) -> None:
    """Start the chart viewer for ``output_file`` and block until it is closed."""
    output_file = output_file.expanduser().resolve()
    if not output_file.is_file():
        raise FileNotFoundError(f"Output file not found: {output_file}")

    dist_dir = viz_dist_dir()
    server = VizServer(dist_dir, output_file)
    server.start()

    try:
        if use_pywebview and _try_pywebview(server.url):
            return
        logger.info("Opening chart viewer in the default browser.")
        webbrowser.open(server.url)
        input("Press Enter to close the chart viewer server…")
    finally:
        server.stop()


def _try_pywebview(url: str) -> bool:
    try:
        import webview
    except ImportError:
        return False

    webview.create_window("CoCoNet Charts", url, width=1320, height=920)
    webview.start()
    return True


def launch_chart_viewer(output_file: Path) -> None:
    """Launch the chart viewer without blocking the caller (desktop GUI helper)."""
    output_file = output_file.expanduser().resolve()
    if not output_file.is_file():
        raise FileNotFoundError(f"Output file not found: {output_file}")

    dist_dir = viz_dist_dir()
    if not dist_dir.is_dir():
        raise FileNotFoundError(
            "Chart viewer assets are missing. Build them with "
            "`cd viz && npm ci && npm run build`, or rebuild the desktop app."
        )

    if getattr(sys, "frozen", False):
        command = [sys.executable, "--viz-viewer", str(output_file)]
    else:
        command = [sys.executable, "-m", "coconet.viz_viewer", str(output_file)]

    subprocess.Popen(command, close_fds=True)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Open the CoCoNet chart viewer.")
    parser.add_argument(
        "output_file",
        type=Path,
        help="Path to a CoCoNet output.csv file.",
    )
    parser.add_argument(
        "--browser-only",
        action="store_true",
        help="Open in the system browser instead of an embedded window.",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        help="Logging level (default: INFO).",
    )
    return parser


def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    configure_logging(args.log_level)
    run_viewer(args.output_file, use_pywebview=not args.browser_only)
