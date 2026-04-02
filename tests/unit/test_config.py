from __future__ import annotations

import os
from pathlib import Path

import pytest
from coconet.config import (
    CoconetConfig,
    effective_ensemble_workers,
    use_parallel_ensemble_run,
)


@pytest.mark.parametrize(
    ("threads", "runs", "expected"),
    [
        (0, 0, 1),
        (1, 5, 1),
        (0, 8, min(8, os.cpu_count() or 1)),
        (4, 100, 4),
        (100, 3, 3),
    ],
)
def test_effective_ensemble_workers(threads: int, runs: int, expected: int) -> None:
    assert effective_ensemble_workers(threads, runs) == expected


def test_use_parallel_ensemble_run() -> None:
    assert use_parallel_ensemble_run(1, 0) is False
    assert use_parallel_ensemble_run(1, 2) is False
    cpus = os.cpu_count() or 1
    assert use_parallel_ensemble_run(0, min(8, cpus) + 1) == (cpus > 1)


def test_config_from_yaml_override(tmp_path: Path) -> None:
    yml = tmp_path / "s.yaml"
    yml.write_text("SSP: 3.0\nensemble_runs: 0\n")
    cfg = CoconetConfig.from_file(config_file=yml)
    assert cfg.SSP == 3.0
    assert cfg.ensemble_runs == 0


def test_config_env_override(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("COCONET_SSP", "2.6")
    monkeypatch.setenv("COCONET_ENSEMBLE_RUNS", "5")
    monkeypatch.setenv("COCONET_START_YEAR", "1990")
    cfg = CoconetConfig.from_file()
    assert cfg.SSP == 2.6
    assert cfg.ensemble_runs == 5
    assert cfg.start_year == 1990


def test_parameter_file_mini(fixture_dir: Path) -> None:
    path = fixture_dir / "parameters_mini.csv"
    cfg = CoconetConfig.from_file(parameter_file=path)
    assert cfg.SSP == 4.5
    assert cfg.ensemble_runs == 2
    assert cfg.start_year == 2000
    assert cfg.end_year == 2001
