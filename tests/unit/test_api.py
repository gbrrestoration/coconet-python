from __future__ import annotations

from pathlib import Path

import pytest
from coconet.api import load_coconet_config


def test_load_coconet_config_scenario_merge(tmp_path: Path) -> None:
    yml = tmp_path / "c.yaml"
    yml.write_text("SSP: 2.6\n")
    cfg = load_coconet_config(config_file=yml, scenario={"SSP": 4.5})
    assert cfg.SSP == 4.5


def test_load_coconet_config_unknown_key_raises() -> None:
    with pytest.raises(TypeError, match="Unknown CoconetConfig"):
        load_coconet_config(scenario={"not_a_field": 1})
