---
title: Command-line interface
description: The CLI entry point (coconet / python -m coconet)—files, flags, profiling, and logging for shell and container workflows.
---

This page documents the **CLI entry point**: runs driven by **file paths, flags, environment variables**, and optional **profiling**. It is what you use in terminals, in the **official Docker image**, and in CI jobs that do not need a custom Python driver.

For **programmatic** control (notebooks, services, other Python tools), use the **library** instead: **`pip install coconet-python`** and see [Python API]({% link python-api.md %}).

## How to invoke

| Invocation | Notes |
| --- | --- |
| **`coconet ...`** | Console script from `pyproject.toml` → `coconet.cli:main`. |
| **`python -m coconet ...`** | Same behaviour; uses `coconet/__main__.py`. |

Internally the CLI builds configuration with **`load_coconet_config`** (see `coconet.api`) and runs the model with **`run_coconet(..., configure_logs=False)`** after it has configured logging itself.

## Arguments

| Option | Effect |
| --- | --- |
| `--config PATH` | Optional YAML file merged into `CoconetConfig`. |
| `--parameter-file PATH` | Legacy NetLogo-style parameter CSV (`Label, value` rows). |
| `--output-file PATH` | Overrides `output_file` on the config. |
| `--reefs-file PATH` | Overrides reef input CSV (`reefs_file`). |
| `--coastline-file PATH` | Overrides coastline CSV (`coastline_file`). |
| `--log-level LEVEL` | `CRITICAL`, `ERROR`, `WARNING`, `INFO`, `DEBUG`. If set here, overrides `COCONET_LOG_LEVEL` and config. |
| `--ensemble-threads N` | Parallel ensemble execution: `1` serial, `0` auto, `N` caps workers. |

## Profiling (optional extra)

Requires `pyinstrument` (`uv sync --extra profile` or `pip install "coconet-python[profile]"`).

| Option | Effect |
| --- | --- |
| `--profile` | Enable CPU profiling for the full model run. |
| `--profile-format` | `html` (default), `text`, or `speedscope`. |
| `--profile-output PATH` | Output path; defaults to `coconet-profile.html`, `.txt`, or `.speedscope.json`. |
| `--profile-interval SECONDS` | Sampling interval (default `0.01`). |
| `--profile-html-resample-interval SECONDS` | Passed to HTML renderer when format is `html`. |

On very long runs, HTML output may resample heavily; the CLI logs a hint when sample count is large.

## Loading sequence

1. Bootstrap logging from `--log-level` or `COCONET_LOG_LEVEL` or `INFO`.
2. **`load_coconet_config`** with `config_file`, `parameter_file`, and CLI-only overrides (`output_file`, `reefs_file`, `coastline_file`, `log_level`, `ensemble_threads` when provided).
3. Re-configure logging from the final **`config.log_level`** if needed.
4. **`run_coconet(config, configure_logs=False)`** (optionally wrapped by the profiler).

So: **YAML + legacy CSV + `COCONET_*` env** are merged inside **`load_coconet_config`**; CLI flags then override specific path and execution fields only.

## Logging format

Configured in `coconet/logging_utils.py`: timestamp, level, logger name, message.

See also: [Configuration]({% link configuration.md %}), [Python API]({% link python-api.md %}).
