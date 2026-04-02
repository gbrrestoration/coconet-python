---
title: CoCoNet (Python) documentation
description: Overview of the CoCoNet Python simulation and this documentation site.
---

**CoCoNet (Python)** is a headless port of the legacy NetLogo **CoCoNet v3** model used for Great Barrier Reef–scale scenarios: coral communities, crown-of-thorns starfish (CoTS), key fish groups, bleaching and cyclones, fisheries, and a wide range of management interventions. The code is designed for **two distinct entry points**—a **CLI** for file- and flag-driven runs, and a **library** published on PyPI as **`coconet-python`** for programmatic control—plus **file-based configuration** and **parity-oriented comparison** with the original NetLogo implementation.

## Two entry points

| Entry point | Best for | How you run |
| --- | --- | --- |
| **CLI** | Shells, Docker (official image), CI that passes paths and flags | Console script **`coconet`** or **`python -m coconet`**; YAML, legacy parameter CSV, `COCONET_*` env vars, and CLI flags. Optional profiling. |
| **Library** | Custom Python apps, services, notebooks, orchestration | **`pip install coconet-python`** → **`from coconet import load_coconet_config, run_coconet`** (and advanced use of `CoconetConfig` / `CoconetModel`). |

Details: [Getting started]({% link getting-started.md %}), [CLI]({% link cli.md %}), [Python API]({% link python-api.md %}).

## Who this is for

- **Modellers and analysts** running scenarios from YAML, legacy parameter CSVs, or environment variables (often via the **CLI**).
- **Developers** embedding CoCoNet in Python pipelines, tests, or cloud jobs (typically via the **library**).
- **Anyone validating** Python outputs against the legacy model using aligned metadata and CSV schema.

## Start here

1. [Getting started]({% link getting-started.md %}) — install, first run, project layout; **CLI vs library**.
2. [Configuration reference]({% link configuration.md %}) — every `CoconetConfig` field and how it is loaded.
3. [Scenario parameter semantics]({% link scenario-parameters.md %}) — legacy CSV labels and what each control does (README-level detail).
4. [Command-line interface]({% link cli.md %}) — **CLI entry point**: flags, profiling, overrides.
5. [Python API]({% link python-api.md %}) — **library entry point**: `load_coconet_config`, `run_coconet`, `CoconetModel`.
6. [Inputs and outputs]({% link inputs-and-outputs.md %}) — reef CSV, coastline, `output.csv` columns.
7. [Model overview]({% link model-overview.md %}) — ensembles, schedule, interventions at a glance.
8. [Architecture]({% link architecture.md %}) — how the engine maps to NetLogo semantics.
9. [Porting notes]({% link porting-notes.md %}) — validation and parity focus.
10. [Related tools]({% link related-tools.md %}) — viewer, charts, Docker.

**Maintainers:** [Publishing to PyPI]({% link publishing.md %}) — trusted publishing (OIDC) from GitHub Actions.

## Published site

This site is built with **Jekyll** and deployed to **GitHub Pages** on pushes to the default branch (see the workflow under `.github/workflows/` in the repository). After you enable Pages with the “GitHub Actions” source, the site is available at:

`https://<owner>.github.io/<repository>/`

(Exact URL is shown in the workflow run and in the repository **Settings → Pages**.)
