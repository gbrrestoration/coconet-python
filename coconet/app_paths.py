"""Resolve paths for development checkouts and PyInstaller bundles."""

from __future__ import annotations

import sys
from pathlib import Path


def repo_root() -> Path:
    """Repository / install root (parent of the ``coconet`` package)."""
    if getattr(sys, "frozen", False):
        return Path(getattr(sys, "_MEIPASS", Path(sys.executable).resolve().parent))
    return Path(__file__).resolve().parent.parent


def bundled_path(*parts: str) -> Path:
    """Path to a file shipped with the app (legacy data, example config)."""
    return repo_root().joinpath(*parts)


def viz_dist_dir() -> Path:
    """Directory containing the built React chart viewer (``viz/dist``)."""
    bundled = bundled_path("viz")
    if bundled.is_dir():
        return bundled
    return Path(__file__).resolve().parent.parent / "viz" / "dist"
