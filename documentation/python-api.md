---
title: Python API
description: Using CoconetConfig and CoconetModel as a library.
---

The public package surface is intentionally small. `coconet/__init__.py` exports:

- **`CoconetConfig`**
- **`CoconetModel`**

Other modules (`cli`, `netlogo`, `logging_utils`, internal symbols on `model`) are available for advanced use but are not part of the stable `__all__`.

## Load configuration

```python
from pathlib import Path
from coconet import CoconetConfig, CoconetModel

cfg = CoconetConfig.from_file(
    config_file=Path("config/example.yaml"),
    parameter_file=None,  # or Path("legacy/I_2p6.csv")
    env_prefix="COCONET_",
)
cfg.output_file = "runs/my_run.csv"
cfg.ensemble_runs = 3
```

## Run the simulation

```python
from coconet.logging_utils import configure_logging

configure_logging(cfg.log_level)
model = CoconetModel(cfg)
model.run()
```

`CoconetModel.run()` performs full setup, optional parallel ensemble execution, and writes the configured `output_file` (and search-mode side outputs when applicable).

## Advanced imports

Examples of symbols other code may touch when extending or testing:

| Module | Examples |
| --- | --- |
| `coconet.config` | `effective_ensemble_workers`, `use_parallel_ensemble_run` |
| `coconet.netlogo` | `NetLogoRng`, `heading_from_dx_dy`, `nl_ceiling`, `nl_median`, `nl_round` |
| `coconet.model` | `CORAL_GROUPS`, `ReefKernel`, `SpinupCheckpoint` (in-memory spin-up snapshot for parallel workers) |

Treat anything outside `__all__` as **internal** unless you rely on a specific parity or test contract.

## Dependencies

Declared in `pyproject.toml`: NumPy, pandas, PyYAML, threadpoolctl (BLAS thread limiting inside worker processes).

See: [Architecture]({% link architecture.md %}), [Configuration]({% link configuration.md %}).
