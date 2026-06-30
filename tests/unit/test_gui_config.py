from __future__ import annotations

from dataclasses import fields
from pathlib import Path

import pytest
import yaml

from coconet.config import CoconetConfig
from coconet.gui_config import (
    CONFIG_FIELD_GROUPS,
    GUI_EXCLUDED_FIELDS,
    editable_config_fields,
    load_yaml_mapping,
    parse_config_field,
    scenario_from_mapping,
    yaml_from_scenario,
)


def test_editable_fields_cover_all_non_gui_excluded_config_fields() -> None:
    config_fields = {f.name for f in fields(CoconetConfig)}
    editable = set(editable_config_fields())
    expected = config_fields - GUI_EXCLUDED_FIELDS
    assert editable == expected


def test_config_field_groups_are_unique() -> None:
    seen: set[str] = set()
    for _, names in CONFIG_FIELD_GROUPS:
        for name in names:
            assert name not in seen
            seen.add(name)


def test_parse_config_field_bool_and_numbers() -> None:
    assert parse_config_field("unregulated_fishing", "true", False) is True
    assert parse_config_field("ensemble_runs", "3", 20) == 3
    assert parse_config_field("SSP", "2.6", 2.6) == 2.6


def test_scenario_from_mapping_rejects_invalid_integer() -> None:
    with pytest.raises(ValueError, match="ensemble_runs"):
        scenario_from_mapping({"ensemble_runs": "not-a-number"})


def test_yaml_roundtrip(tmp_path: Path) -> None:
    scenario = scenario_from_mapping({"ensemble_runs": "2", "end_year": "1990"})
    path = tmp_path / "scenario.yaml"
    path.write_text(yaml_from_scenario(scenario), encoding="utf-8")
    loaded = load_yaml_mapping(path)
    assert loaded["ensemble_runs"] == 2
    assert yaml.safe_load(yaml_from_scenario(scenario)) == loaded
