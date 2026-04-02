---
title: Command-line interface
description: coconet entry point, flags, profiling, and logging.
---

The console script **`coconet`** is declared in `pyproject.toml` as `coconet.cli:main`.

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

Requires `pyinstrument` (`uv sync --extra profile` or `pip install coconet[profile]`).

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
2. `CoconetConfig.from_file(config_file=args.config, parameter_file=args.parameter_file)`.
3. Apply CLI overrides for output path, reef/coastline files, log level, `ensemble_threads`.
4. Re-configure logging from the final `config.log_level` if needed.
5. Construct `CoconetModel` and call `run()` (optionally under the profiler).

## Logging format

Configured in `coconet/logging_utils.py`: timestamp, level, logger name, message.

See also: [Configuration]({% link configuration.md %}), [Python API]({% link python-api.md %}).
