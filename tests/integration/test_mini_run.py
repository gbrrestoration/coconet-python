from __future__ import annotations

import pytest
from coconet.api import load_coconet_config, run_coconet


@pytest.mark.integration
def test_run_coconet_mini_network(tmp_path, fixture_dir, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("COCONET_SSP", raising=False)
    out = tmp_path / "integration.csv"
    cfg = load_coconet_config(
        scenario={
            "reefs_file": str(fixture_dir / "reefs_two.csv"),
            "coastline_file": str(fixture_dir / "coastline_clip.csv"),
            "output_file": str(out),
            "ensemble_runs": 0,
            "ensemble_threads": 1,
            "start_year": 1956,
            "end_year": 1957,
            "save_year": 9999,
            "spinup_backtrack_years": 0,
            "projection_year": 3000,
            "search_year": 9999,
            "log_level": "WARNING",
        },
    )
    result = run_coconet(cfg)
    assert result.output_file == str(out)
    assert out.is_file()
    text = out.read_text()
    assert "Climate scenario" in text
    assert "Ensemble runs" in text
