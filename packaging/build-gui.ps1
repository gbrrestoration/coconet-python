# Build the CoCoNet GUI app bundle on Windows.
$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

Write-Host "Building chart viewer assets..."
Push-Location viz
npm ci
npm run build
Pop-Location

uv sync --extra gui
uv run pyinstaller --noconfirm --clean packaging/coconet-gui.spec

Write-Host ""
Write-Host "Build complete:"
Write-Host "  $(Join-Path $Root 'dist\CoCoNet')"
