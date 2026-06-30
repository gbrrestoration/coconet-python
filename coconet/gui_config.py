"""Interactive CoCoNet scenario configuration for the desktop GUI."""

from __future__ import annotations

import tkinter as tk
from dataclasses import fields
from pathlib import Path
from tkinter import filedialog, messagebox, ttk
from typing import Any

import yaml

from coconet.config import CoconetConfig, _parse_scalar

# Paths and run options are edited elsewhere in the GUI.
GUI_EXCLUDED_FIELDS = frozenset(
    {
        "reefs_file",
        "coastline_file",
        "output_file",
        "parameter_file",
        "log_level",
        "ensemble_threads",
    }
)

CONFIG_FIELD_GROUPS: tuple[tuple[str, tuple[str, ...]], ...] = (
    (
        "Schedule",
        (
            "SSP",
            "ensemble_runs",
            "start_year",
            "spinup_backtrack_years",
            "save_year",
            "projection_year",
            "search_year",
            "end_year",
        ),
    ),
    (
        "Catchment & fishing",
        (
            "start_catchment_restore",
            "restore_timeframe",
            "start_modified_zoning",
            "rezoned_reefs",
            "start_modified_fishing",
            "catch_reduction",
            "start_lower_sizelimit",
            "start_upper_sizelimit",
            "start_CoTSlimit",
        ),
    ),
    (
        "CoTS control",
        (
            "start_CoTS_control",
            "eco_threshold",
            "CoTS_threshold",
            "coral_threshold",
            "CoTS_vessels_GBR",
            "CoTS_vessels_FN",
            "CoTS_vessels_N",
            "CoTS_vessels_C",
            "CoTS_vessels_S",
            "CoTS_vessels_sector",
        ),
    ),
    (
        "Intervention area",
        (
            "intervene_lon_min",
            "intervene_lon_max",
            "intervene_lat_min",
            "intervene_lat_max",
        ),
    ),
    (
        "Emperor release",
        (
            "start_emperor_release",
            "release_reefs",
            "release_threshold",
            "release_number",
        ),
    ),
    (
        "Regional shading",
        ("start_regional_shading", "regional_shading_reduction"),
    ),
    (
        "Rubble consolidation",
        (
            "start_rubble_consolidation",
            "consolidation_reefs",
            "consolidation_threshold",
            "consolidation_hectares",
        ),
    ),
    (
        "Coral seeding",
        (
            "start_coral_seeding",
            "seed_reefs",
            "seed_threshold",
            "seed_hectares",
            "hybrid_fraction",
            "dominance",
        ),
    ),
    (
        "Coral slicks",
        (
            "start_coral_slick",
            "slick_reefs",
            "slick_threshold",
            "slick_hectares",
        ),
    ),
    (
        "Reef shading & pH",
        (
            "start_reef_shading",
            "shading_reefs",
            "reef_shading_reduction",
            "start_pH_protection",
            "pH_reefs",
            "pH_protection",
        ),
    ),
    (
        "Advanced",
        ("search_mode", "perfect_intervention", "unregulated_fishing"),
    ),
)

FIELD_LABELS: dict[str, str] = {
    "SSP": "Climate scenario (SSP)",
    "ensemble_runs": "Ensemble runs",
    "start_year": "Start year",
    "spinup_backtrack_years": "Spinup backtrack (years)",
    "save_year": "Save year",
    "projection_year": "Projection year",
    "search_year": "Search year",
    "end_year": "End year",
    "start_catchment_restore": "Catchment restoration start year",
    "restore_timeframe": "Catchment restoration timescale (years)",
    "start_modified_zoning": "Future zoning start year",
    "rezoned_reefs": "Reefs included in future rezoning",
    "start_modified_fishing": "Catch reduction start year",
    "catch_reduction": "Fractional catch reduction",
    "start_lower_sizelimit": "Lower fish size limit start year",
    "start_upper_sizelimit": "Upper fish size limit start year",
    "start_CoTSlimit": "CoTS fishing exclusion start year",
    "start_CoTS_control": "CoTS control start year",
    "eco_threshold": "Ecological threshold (CoTS per ha)",
    "CoTS_threshold": "CoTS threshold (CoTS per ha)",
    "coral_threshold": "Coral threshold (CoTS per ha)",
    "CoTS_vessels_GBR": "CoTS vessels across GBR",
    "CoTS_vessels_FN": "CoTS vessels in far-north",
    "CoTS_vessels_N": "CoTS vessels in north",
    "CoTS_vessels_C": "CoTS vessels in central",
    "CoTS_vessels_S": "CoTS vessels in south",
    "CoTS_vessels_sector": "CoTS vessels in active sector",
    "intervene_lon_min": "Minimum intervention longitude",
    "intervene_lon_max": "Maximum intervention longitude",
    "intervene_lat_min": "Minimum intervention latitude",
    "intervene_lat_max": "Maximum intervention latitude",
    "start_emperor_release": "Emperor release start year",
    "release_reefs": "Number of release reefs",
    "release_threshold": "Max adult emperors per ha for release",
    "release_number": "Juvenile emperors released per reef",
    "start_regional_shading": "Regional shading start year",
    "regional_shading_reduction": "Regional DHW reduction",
    "start_rubble_consolidation": "Rubble consolidation start year",
    "consolidation_reefs": "Annual consolidated reefs",
    "consolidation_threshold": "Minimum rubble cover threshold",
    "consolidation_hectares": "Annual consolidated area (ha)",
    "start_coral_seeding": "Coral seeding start year",
    "seed_reefs": "Annual seeded reefs",
    "seed_threshold": "Maximum coral cover for seeding",
    "seed_hectares": "Annual seeded coral area (ha)",
    "hybrid_fraction": "Hybridisation fraction",
    "dominance": "Thermal tolerance dominance in hybrids",
    "start_coral_slick": "Coral slicks start year",
    "slick_reefs": "Annual slick release reefs",
    "slick_threshold": "Maximum coral cover for slicks",
    "slick_hectares": "Annual slick coral area (ha)",
    "start_reef_shading": "Reef shading start year",
    "shading_reefs": "Annual locally shaded reefs",
    "reef_shading_reduction": "Fractional local DHW reduction",
    "start_pH_protection": "Ocean acidification treatment start year",
    "pH_reefs": "Annual pH treatment reefs",
    "pH_protection": "Fractional pH protection",
    "search_mode": "Search mode (0=off, 1=on)",
    "perfect_intervention": "Perfect intervention mode",
    "unregulated_fishing": "Unregulated fishing",
}


def editable_config_fields() -> tuple[str, ...]:
    grouped = {name for _, names in CONFIG_FIELD_GROUPS for name in names}
    defaults = {f.name for f in fields(CoconetConfig)} - GUI_EXCLUDED_FIELDS
    missing = sorted(defaults - grouped)
    if missing:
        raise RuntimeError(f"GUI config groups missing fields: {missing}")
    return tuple(name for _, names in CONFIG_FIELD_GROUPS for name in names)


def default_config_values() -> dict[str, Any]:
    base = CoconetConfig()
    return {
        name: getattr(base, name)
        for name in editable_config_fields()
    }


def format_config_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return ""
    return str(value)


def parse_config_field(name: str, text: str, default: Any) -> Any:
    stripped = text.strip()
    if isinstance(default, bool):
        if stripped == "":
            return default
        lowered = stripped.lower()
        if lowered in {"true", "1", "yes", "on"}:
            return True
        if lowered in {"false", "0", "no", "off"}:
            return False
        raise ValueError(f"{name}: expected true/false, got {text!r}")
    if isinstance(default, int) and not isinstance(default, bool):
        if stripped == "":
            return default
        parsed = _parse_scalar(stripped)
        if not isinstance(parsed, int):
            raise ValueError(f"{name}: expected integer, got {text!r}")
        return parsed
    if isinstance(default, float):
        if stripped == "":
            return default
        parsed = _parse_scalar(stripped)
        if not isinstance(parsed, (int, float)):
            raise ValueError(f"{name}: expected number, got {text!r}")
        return float(parsed)
    return stripped


def scenario_from_mapping(values: dict[str, Any]) -> dict[str, Any]:
    defaults = default_config_values()
    scenario: dict[str, Any] = {}
    errors: list[str] = []
    for name, default in defaults.items():
        if name not in values:
            continue
        raw = values[name]
        if isinstance(raw, str):
            try:
                scenario[name] = parse_config_field(name, raw, default)
            except ValueError as exc:
                errors.append(str(exc))
        else:
            scenario[name] = raw
    if errors:
        raise ValueError("\n".join(errors))
    return scenario


def load_yaml_mapping(path: Path) -> dict[str, Any]:
    loaded = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(loaded, dict):
        raise ValueError(f"{path}: expected a YAML mapping at the top level.")
    return loaded


def yaml_from_scenario(scenario: dict[str, Any]) -> str:
    ordered = {name: scenario[name] for name in editable_config_fields() if name in scenario}
    extra = sorted(set(scenario) - set(ordered))
    for name in extra:
        ordered[name] = scenario[name]
    return yaml.safe_dump(ordered, sort_keys=False, default_flow_style=False)


class _ScrollableFrame(ttk.Frame):
    def __init__(self, parent: tk.Misc) -> None:
        super().__init__(parent)
        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)
        canvas = tk.Canvas(self, highlightthickness=0)
        scrollbar = ttk.Scrollbar(self, orient=tk.VERTICAL, command=canvas.yview)
        self.inner = ttk.Frame(canvas)
        self.inner.bind(
            "<Configure>",
            lambda _event: canvas.configure(scrollregion=canvas.bbox("all")),
        )
        window_id = canvas.create_window((0, 0), window=self.inner, anchor=tk.NW)
        canvas.bind(
            "<Configure>",
            lambda event: canvas.itemconfigure(window_id, width=event.width),
        )
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.grid(row=0, column=0, sticky=tk.NSEW)
        scrollbar.grid(row=0, column=1, sticky=tk.NS)

        def _on_mousewheel(event: tk.Event) -> None:
            if getattr(event, "delta", 0):
                canvas.yview_scroll(int(-event.delta / 120), "units")

        def _bind(_event: tk.Event) -> None:
            canvas.bind_all("<MouseWheel>", _on_mousewheel)

        def _unbind(_event: tk.Event) -> None:
            canvas.unbind_all("<MouseWheel>")

        canvas.bind("<Enter>", _bind)
        canvas.bind("<Leave>", _unbind)


class ConfigEditorPanel(ttk.Frame):
    """Scrollable grouped editor for scenario YAML fields."""

    def __init__(self, parent: tk.Misc) -> None:
        super().__init__(parent)
        self._defaults = default_config_values()
        self._string_vars: dict[str, tk.StringVar] = {}
        self._bool_vars: dict[str, tk.BooleanVar] = {}

        toolbar = ttk.Frame(self)
        toolbar.pack(fill=tk.X, pady=(0, 8))
        ttk.Button(toolbar, text="Load from YAML…", command=self._load_from_yaml).pack(side=tk.LEFT)
        ttk.Button(toolbar, text="Save YAML as…", command=self._save_yaml).pack(
            side=tk.LEFT, padx=(8, 0)
        )
        ttk.Button(toolbar, text="Reset to defaults", command=self.load_defaults).pack(
            side=tk.LEFT, padx=(8, 0)
        )

        notebook = ttk.Notebook(self)
        notebook.pack(fill=tk.BOTH, expand=True)
        for group_name, field_names in CONFIG_FIELD_GROUPS:
            page = _ScrollableFrame(notebook)
            notebook.add(page, text=group_name)
            self._build_group(page.inner, field_names)

        self.load_defaults()

    def _build_group(self, parent: ttk.Frame, field_names: tuple[str, ...]) -> None:
        for row, name in enumerate(field_names):
            label = FIELD_LABELS.get(name, name)
            ttk.Label(parent, text=label).grid(row=row, column=0, sticky=tk.W, pady=3, padx=(0, 8))
            default = self._defaults[name]
            if isinstance(default, bool):
                var = tk.BooleanVar(value=default)
                self._bool_vars[name] = var
                ttk.Checkbutton(parent, variable=var).grid(row=row, column=1, sticky=tk.W, pady=3)
            else:
                var = tk.StringVar(value=format_config_value(default))
                self._string_vars[name] = var
                entry = ttk.Entry(parent, textvariable=var, width=28)
                entry.grid(row=row, column=1, sticky=tk.EW, pady=3)
            parent.columnconfigure(1, weight=1)

    def load_defaults(self) -> None:
        self.load_mapping(self._defaults)

    def load_mapping(self, values: dict[str, Any]) -> None:
        for name, default in self._defaults.items():
            value = values.get(name, default)
            if name in self._bool_vars:
                self._bool_vars[name].set(bool(value))
            elif name in self._string_vars:
                self._string_vars[name].set(format_config_value(value))

    def load_from_path(self, path: Path) -> None:
        mapping = load_yaml_mapping(path)
        unknown = sorted(set(mapping) - set(self._defaults) - GUI_EXCLUDED_FIELDS)
        if unknown:
            messagebox.showwarning(
                "Unknown YAML keys",
                "These keys were ignored:\n" + ", ".join(unknown),
            )
        merged = dict(self._defaults)
        for key, value in mapping.items():
            if key in self._defaults:
                merged[key] = value
        self.load_mapping(merged)

    def collect_raw_values(self) -> dict[str, Any]:
        values = dict(self._defaults)
        for name, var in self._string_vars.items():
            values[name] = var.get()
        for name, var in self._bool_vars.items():
            values[name] = var.get()
        return values

    def build_scenario(self) -> dict[str, Any]:
        return scenario_from_mapping(self.collect_raw_values())

    def _load_from_yaml(self) -> None:
        path = filedialog.askopenfilename(
            title="Load YAML config",
            filetypes=[("YAML", "*.yaml *.yml"), ("All files", "*.*")],
        )
        if not path:
            return
        try:
            self.load_from_path(Path(path))
        except Exception as exc:
            messagebox.showerror("Load failed", str(exc))

    def _save_yaml(self) -> None:
        try:
            scenario = self.build_scenario()
        except ValueError as exc:
            messagebox.showerror("Invalid values", str(exc))
            return
        path = filedialog.asksaveasfilename(
            title="Save YAML config",
            defaultextension=".yaml",
            filetypes=[("YAML", "*.yaml *.yml"), ("All files", "*.*")],
        )
        if not path:
            return
        Path(path).write_text(yaml_from_scenario(scenario), encoding="utf-8")
