---
title: Model overview
description: Schedule, ensembles, coral and CoTS structure, and intervention hooks.
---

CoCoNet is a **reef- and site-resolved** simulation with an **annual** time step. The Python port follows the legacy NetLogo **setup → annual loop** structure and reproduces important ordering and RNG-related behaviour via `NetLogoRng` and explicit loop orders in `coconet/model.py`.

You execute the same engine from the **CLI** or the **PyPI library** (**`coconet-python`**); see [Getting started]({% link getting-started.md %}).

## Ensembles and spin-up

- **Ensemble 0** is **spin-up**: simulation can begin at `start_year - spinup_backtrack_years` and runs forward to build trajectory history.
- **Ensembles 1 … `ensemble_runs`** are **stochastic replicates**. Initial conditions for each replicate are derived from the spin-up state consistent with `save_year` and the annual loop logic (see code comments and README schedule table).
- If `ensemble_runs` is **0**, only ensemble 0 is executed.

## Parallel ensembles

When `use_parallel_ensemble_run` is true (`ensemble_runs > 1` and effective worker count > 1):

- Ensemble 0 runs on the **main** process.
- After spin-up, a **checkpoint** captures array state.
- Worker processes replay from that checkpoint for ensembles `1 … ensemble_runs`.
- **threadpoolctl** limits BLAS threads inside workers to avoid oversubscription.

`ensemble_threads`: `0` picks `min(CPU count, simulation ensemble count)`, `1` forces **serial** simulation ensembles on the main process, `N > 1` caps workers.

## Coral functional groups

Reef-level cover means use keys such as **`sa`**, **`ta`**, **`mo`**, **`po`**, **`fa`**, **`tt`** (staghorn acropora, tabular acropora, etc.—see code and README). Larval dispersal and spawn routines preserve a **fixed kernel iteration order** (`CORAL_SPAWN_KERNEL_ORDER`) so RNG draws stay aligned with NetLogo.

## CoTS and fisheries

CoTS dynamics use site- and reef-level state (`S_*` ages, `S_manta`, control dives). **CoTS control** runs only from `start_CoTS_control` onward, with separate passes for GBR-wide, regional, and sector-based vessel counts where configured.

Fisheries interventions modify catch caps, size limits, and outbreak-based closures as described in the repository README parameter tables.

## Drivers

- **Historical** cyclone and bleaching drivers apply before `projection_year`; **scenario** drivers apply from `projection_year` onward.
- **SSP** (shared socioeconomic pathway) enters bleaching severity, growth-related `pH` stress (`sqrt(SSP)` in relevant branches), and projection bleaching probability helpers.

## Interventions

Spatial interventions (seeding, shading, rubble consolidation, coral slicks, pH protection, emperor release, regional shading, etc.) gate on per-intervention **start years** and **budgets** (reefs per year, hectares, thresholds). Most respect the configured **intervention bounding box** except where regional CoTS control uses region codes instead.

Exact equations live on `CoconetModel` methods in `coconet/model.py`.

## Further reading

- README in the repository (detailed tables for each legacy parameter).
- [Configuration]({% link configuration.md %}) for field names and defaults.
- [Porting notes]({% link porting-notes.md %}) for parity checks.
