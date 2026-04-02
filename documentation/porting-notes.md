---
title: Porting notes
description: NetLogo source, parity principles, and validation strategy for the Python port.
---

## Source model

- Primary source: `legacy/CoCoNet V3_rubble.nlogo` (code section before the first `@#$#@#$#@` delimiter).
- Backup or optimized NetLogo variants were reviewed to confirm that logic differences are mostly profiling or refactoring.

## Porting approach

- Preserve the NetLogo **annual execution flow** (`setup`, `go`, nested ensemble / year loops).
- Preserve key NetLogo behaviours:
  - reseeding `random-seed ((ensemble + 1) * year)` in procedures,
  - ordered **reef iteration** (creation order),
  - `one-of`, `random`, `random-float` semantics,
  - cone / radius dispersal geometry for recruitment,
  - **intervention ordering** and thresholds.
- Keep **output schema** aligned with legacy output files.

## Configuration in Python

The Python model supports:

1. **Legacy parameter CSVs** (same style as NetLogo parameter files / output metadata block),
2. **YAML config files** for modern workflows,
3. **Environment variable overrides** with the `COCONET_` prefix.

You can drive these from the **CLI** (files and flags) or from the **library** (`load_coconet_config`, `CoconetConfig.from_file`); see [Getting started]({% link getting-started.md %}).

## Known implementation choices

- Internal state is held in **NumPy arrays** with explicit reef / site indexing.
- A synthetic NetLogo-style `who` numbering scheme is reconstructed so site-based `remainder who 11` rubble behaviour is retained.
- `predate_mort_*` variables are carried through output as in the legacy model (site values remain zero unless explicitly changed by logic).

## Validation strategy

Recommended parity checks:

1. Run legacy NetLogo and Python with the **same parameter CSV**.
2. Compare output distributions and time series for:
   - `C_*`, `C_reef`, `R_reef`,
   - `S_*`, `S_manta`,
   - `E_*`, `G_*`, catches,
   - bleaching / cyclone mortality summaries.
3. Validate **intervention scenarios** independently (control, seeding, shading, pH, fishing changes).

## See also

- [Architecture]({% link architecture.md %}) for RNG and state layout.
- Repository **README** for parameter semantics tied to legacy labels.
