"""Shared fixtures for CoCoNet tests.

Mini CSV fixtures mirror the legacy column layout so :meth:`CoconetModel.setup`
exercises real loading and allocation code without pulling the full reef network.
"""

from __future__ import annotations

from collections.abc import Callable
from pathlib import Path

import pytest
from coconet.config import CoconetConfig

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES = REPO_ROOT / "tests" / "fixtures"


@pytest.fixture(scope="session")
def fixture_dir() -> Path:
    return FIXTURES


@pytest.fixture
def make_tiny_config(tmp_path: Path, fixture_dir: Path) -> Callable[..., CoconetConfig]:
    """Factory for :class:`CoconetConfig` pointing at mini reefs/coastline and a temp output path."""

    def _make(**overrides: object) -> CoconetConfig:
        cfg = CoconetConfig(
            reefs_file=str(fixture_dir / "reefs_two.csv"),
            coastline_file=str(fixture_dir / "coastline_clip.csv"),
            output_file=str(tmp_path / "run_output.csv"),
            ensemble_runs=0,
            ensemble_threads=1,
            start_year=1956,
            end_year=1957,
            save_year=9999,
            spinup_backtrack_years=0,
            projection_year=3000,
            search_year=9999,
        )
        for key, value in overrides.items():
            setattr(cfg, key, value)
        return cfg

    return _make
