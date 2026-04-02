---
title: CoCoNet (Python) documentation
description: Overview of the CoCoNet Python simulation and this documentation site.
---

**CoCoNet (Python)** is a headless port of the legacy NetLogo **CoCoNet v3** model used for Great Barrier Reef–scale scenarios: coral communities, crown-of-thorns starfish (CoTS), key fish groups, bleaching and cyclones, fisheries, and a wide range of management interventions. The code is designed for **CLI and library use**, **file-based configuration**, and **parity-oriented comparison** with the original NetLogo implementation.

## Who this is for

- **Modellers and analysts** running scenarios from YAML, legacy parameter CSVs, or environment variables.
- **Developers** embedding `CoconetModel` in pipelines, tests, or cloud jobs.
- **Anyone validating** Python outputs against the legacy model using aligned metadata and CSV schema.

## Start here

1. [Getting started]({% link getting-started.md %}) — install, first run, project layout.
2. [Configuration reference]({% link configuration.md %}) — every `CoconetConfig` field and how it is loaded.
3. [Scenario parameter semantics]({% link scenario-parameters.md %}) — legacy CSV labels and what each control does (README-level detail).
4. [Command-line interface]({% link cli.md %}) — flags, profiling, overrides.
5. [Python API]({% link python-api.md %}) — `CoconetConfig.from_file` and `CoconetModel.run()`.
6. [Inputs and outputs]({% link inputs-and-outputs.md %}) — reef CSV, coastline, `output.csv` columns.
7. [Model overview]({% link model-overview.md %}) — ensembles, schedule, interventions at a glance.
8. [Architecture]({% link architecture.md %}) — how the engine maps to NetLogo semantics.
9. [Porting notes]({% link porting-notes.md %}) — validation and parity focus.
10. [Related tools]({% link related-tools.md %}) — viewer, charts, Docker.

## Published site

This site is built with **Jekyll** and deployed to **GitHub Pages** on pushes to the default branch (see the workflow under `.github/workflows/` in the repository). After you enable Pages with the “GitHub Actions” source, the site is available at:

`https://<owner>.github.io/<repository>/`

(Exact URL is shown in the workflow run and in the repository **Settings → Pages**.)
