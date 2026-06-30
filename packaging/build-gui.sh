#!/usr/bin/env bash
# Build the CoCoNet GUI app bundle on macOS or Linux.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building chart viewer assets..."
(cd viz && npm ci && npm run build)

uv sync --extra gui
uv run pyinstaller --noconfirm --clean packaging/coconet-gui.spec

echo ""
echo "Build complete:"
echo "  $ROOT/dist/CoCoNet/"
