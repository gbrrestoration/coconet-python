---
title: Getting started
description: Install CoCoNet Python, run your first simulation, and understand repository layout.
---

## Requirements

- **Python 3.11+**
- Dependencies (see `pyproject.toml`): NumPy 2.2+, pandas 2.2+, PyYAML 6+, threadpoolctl 3.5+

## Install and run (uv)

From the repository root:

```bash
uv sync
uv run coconet --parameter-file legacy/I_2p6.csv --output-file output.csv
```

With a YAML config:

```bash
uv run coconet --config config/example.yaml --output-file output.csv
```

## Install and run (pip)

```bash
pip install .
coconet --config config/example.yaml --output-file output.csv
```

Optional profiling dependencies:

```bash
uv sync --extra profile
# or: pip install "coconet[profile]"
```

## Environment overrides

Any `CoconetConfig` field can be overridden with the `COCONET_` prefix (case-insensitive suffix matching the field name):

```bash
export COCONET_ENSEMBLE_RUNS=2
export COCONET_END_YEAR=1990
uv run coconet --parameter-file legacy/I_2p6.csv
```

See [Configuration]({% link configuration.md %}) for precedence (YAML → legacy CSV → environment).

## Repository layout

| Path | Purpose |
| --- | --- |
| `coconet/` | Package: `config.py`, `model.py`, `cli.py`, `netlogo.py`, `logging_utils.py` |
| `config/` | Example YAML (e.g. `example.yaml`) |
| `legacy/` | Original NetLogo model, reef and coastline CSVs, scenario parameter files |
| `documentation/` | This Jekyll documentation site |
| `viz/` | Optional React viewer for exploring `output.csv` |
| `gen-charts/` | Optional Node tooling to render charts from output |

## Typical workflow

1. Choose **parameter file** (legacy CSV) and/or **YAML** for scenario settings.
2. Point **reefs** and **coastline** inputs at CSVs (defaults use `legacy/`).
3. Run **`coconet`** (or construct `CoconetConfig` + `CoconetModel` in Python).
4. Consume **`output.csv`** (and optionally `priority_reef_benefit.csv` in search mode).

Details: [Inputs and outputs]({% link inputs-and-outputs.md %}), [CLI]({% link cli.md %}), [Python API]({% link python-api.md %}).
