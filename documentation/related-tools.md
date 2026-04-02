---
title: Related tools
description: Viewer app, chart generation, and container image for CoCoNet Python.
---

## React viewer (`viz/`)

A **Vite + React** application for exploring `output.csv` in the browser. See `viz/package.json` for scripts (typically `npm install` / `npm run dev`). Parsing logic lives under `viz` sources (for example TypeScript helpers that read the CSV layout produced by the model).

## Static charts (`gen-charts/`)

A small **Node** CLI that ingests `output.csv` and produces **PNG** charts using Vega-Lite and resvg. Useful for reports and thumbnails without running the viewer.

## Docker

The repository ships a container workflow (`.github/workflows/docker-publish.yml`) that publishes images to **GitHub Container Registry** (`ghcr.io`) on pushes to the default branch and version tags. Use the image for reproducible runs in CI or cloud environments; mount your `config/`, `legacy/`, or output directories as volumes as needed.

## Documentation site

This **Jekyll** site under `documentation/` is built in CI and deployed to **GitHub Pages**. Local preview:

```bash
cd documentation
bundle install
bundle exec jekyll serve --livereload
```

For GitHub project Pages, pass your repository name as `baseurl` when previewing subdirectory paths:

```bash
bundle exec jekyll serve --baseurl "/coconet-python"
```

The GitHub Actions workflow sets `baseurl` automatically from `${{ github.event.repository.name }}`.
