---
title: Architecture
description: How the Python package maps to the legacy NetLogo model and execution flow.
---

## Components

| Piece | Responsibility |
| --- | --- |
| **`CoconetConfig`** | Typed scenario + I/O paths; YAML, legacy CSV, and environment merge. |
| **`CoconetModel`** | All dynamic state (NumPy arrays), annual procedures, output writers. |
| **`coconet.api`** | **Library entry point**: `load_coconet_config`, `run_coconet` (stable embedding for PyPI consumers). |
| **`NetLogoRng`** | Parity-oriented RNG behaviour aligned with NetLogo usage patterns. |
| **`coconet.cli`** | **CLI entry point**: argument parsing, logging bootstrap, optional pyinstrument profiling; calls **`load_coconet_config`** + **`run_coconet`**. |
| **`logging_utils`** | Normalized log levels and `basicConfig` setup. |

## State representation

Internal state is held in **NumPy** arrays indexed by **reef** and **site**. A synthetic NetLogo-style **`who`** scheme is reconstructed where legacy logic depended on site-level modulo patterns (e.g. rubble-related `remainder who 11` behaviour—see `PORTING_NOTES` / porting page).

## Execution graph (high level)

1. **`run()`** computes effective worker settings; calls **`setup(init_output=True)`** (loads spatial inputs, allocates arrays, writes output preamble).
2. Either **`_run_with_parallel_simulation_ensembles`** or **`_run_sequential_ensemble_loop`** drives ensembles.
3. For each ensemble: **`initialise_run()`** seeds year and state from spin-up rules; **`_run_ensemble_year_steps()`** advances `start_year…end_year` (with spin-up backtrack for ensemble 0); **`writeOUTPUT()`** is invoked each reporting step as in legacy flow (see model for exact hooks).
4. Optional **`_maybe_write_priority_benefit`** for search mode.

## Parity goals

The port aims to preserve:

- Annual ordering of procedures and reef iteration **order** (creation order).
- RNG reseeding conventions where NetLogo tied draws to ensemble and year.
- Dispersal geometry and intervention **thresholds** and **ordering**.
- **Output schema** alignment for CSV-driven comparison workflows.

Not every floating-point boundary will match NetLogo bit-for-bit; recommended validation is **statistical and structural** (distributions, time series, intervention on/off experiments) as outlined on the [Porting notes]({% link porting-notes.md %}) page.

## File references

Authoritative code paths:

- `coconet/model.py` — engine (~2000+ lines).
- `coconet/config.py` — configuration and legacy label map.
- `coconet/netlogo.py` — RNG and numeric helpers.
- `legacy/CoCoNet V3_rubble.nlogo` — source specification.
