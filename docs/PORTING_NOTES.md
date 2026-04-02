# CoCoNet NetLogo -> Python Porting Notes

## Source model

- Primary source: `legacy/CoCoNet V3_rubble.nlogo` (code section before first `@#$#@#$#@` delimiter).
- Backup/optimized variants were reviewed to confirm logic parity differences are mostly profiling or refactoring.

## Porting approach

- Preserve the NetLogo annual execution flow (`setup`, `go`, nested ensemble/year loops).
- Preserve key NetLogo behaviors:
  - reseeding `random-seed ((ensemble + 1) * year)` in procedures,
  - ordered reef iteration (creation order),
  - `one-of`, `random`, `random-float` semantics,
  - cone/radius dispersal geometry for recruitment,
  - intervention ordering and thresholds.
- Keep output schema aligned with legacy output files.

## Configuration

The Python model supports:

1. **Legacy parameter CSVs** (same style as NetLogo parameter files / output metadata block),
2. **YAML config files** for modern workflows,
3. **Environment variable overrides** with `COCONET_` prefix.

## Known implementation choices

- Internal state is held in NumPy arrays with explicit reef/site indexing.
- A synthetic NetLogo-style `who` numbering scheme is reconstructed so site-based `remainder who 11` rubble behavior is retained.
- `predate_mort_*` variables are carried through output as in legacy model (site values remain zero unless explicitly changed by logic).

## Validation strategy

Recommended parity checks:

1. Run legacy NetLogo and Python model with same parameter CSV.
2. Compare output distributions and timeseries for:
   - `C_*`, `C_reef`, `R_reef`,
   - `S_*`, `S_manta`,
   - `E_*`, `G_*`, catches,
   - bleaching/cyclone mortality summaries.
3. Validate intervention scenarios independently (control, seeding, shading, pH, fishing changes).
