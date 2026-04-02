---
title: Inputs and outputs
description: Spatial CSV inputs, coastline file, main output schema, and search-mode files.
---

Paths such as **`reefs_file`**, **`coastline_file`**, and **`output_file`** are set on **`CoconetConfig`**—via YAML, environment variables, the **CLI** flags **`--reefs-file`**, **`--coastline-file`**, **`--output-file`**, or **`load_coconet_config`** / direct assignment when using the **library**. See [Getting started]({% link getting-started.md %}).

## Reef CSV (`reefs_file`)

Default: `legacy/reefs2024.csv`.

The loader in `coconet/model.py` (`_load_reefs`) reads a **wide** CSV with **fixed column positions** (0-based indices) for core attributes—for example reef identifier, latitude, longitude, region, shelf position, sector, rezone flag, priority, and site counts. Treat the legacy file as the **reference layout**; changing column order without updating the loader will break the model.

## Coastline CSV (`coastline_file`)

Default: `legacy/coastline.csv`.

Two numeric columns interpreted as **longitude** and **latitude** for a simplified coastline polyline used in distance-related logic.

## Main output: `output_file`

Default: `output.csv`.

### Metadata block

The file begins with a **legacy-aligned metadata section**: lines echo scenario parameters (climate scenario, ensemble count, schedule years, CoTS, fishing, interventions, etc.), mirroring the style of NetLogo output templates. See `_set_up_output_files` in `coconet/model.py` for the exact order and labels.

### Data header and rows

After the metadata block, a single header row defines comma-separated columns, followed by **one row per reef per reporting timestep** (ensemble × year).

Header (as written by the model):

`Ensemble`, `Year`, `Reef_ID`, `Region`, `Shelf_position`, `Rezone_year`, `Priority`, `Longitude`, `Latitude`, `km_offshore`, `Reef_sites`,

Then coral reef means by functional group: `C_sa`, `C_ta`, `C_mo`, `C_po`, `C_fa`, `C_tt`, `C_out_degree`, `DHW`,

Bleaching mortality (`bleach_*`), `Maximum_cyclone_category`, cyclone mortality (`cyclone_*`), predation mortality (`predate_*`),

CoTS age structure at reef resolution: `S_1` … `S_6`, `S_manta`, `Control_dives`, `Benthic_invert`, `Triggerfish`,

Emperor and coral-trout age classes `E_1` … `E_5`, `E_catch_kg`, `G_1` … `G_5`, `G_catch_kg`.

`write_output()` appends rows for every reef for the current `ensemble` and `year`.

## Search mode

When `search_mode == 1` and the calendar year is at or beyond `search_year`, the model may write benefit / priority-related data (e.g. `priority_reef_benefit.csv` or worker shards merged by the main process). Inspect `_maybe_write_priority_benefit` and related helpers in `coconet/model.py` for filenames and merge behaviour.

## Spin-up checkpoints

`SpinupCheckpoint` holds an **in-memory** NumPy snapshot after ensemble **0** spin-up. It is used to seed parallel worker processes; it is **not** a user-facing on-disk checkpoint format.

## Downstream tooling

- **`viz/`** — browser viewer that parses `output.csv`.
- **`gen-charts/`** — generates static charts from the same CSV.

See [Related tools]({% link related-tools.md %}).
