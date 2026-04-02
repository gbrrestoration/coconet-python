from __future__ import annotations

import numpy as np
import pytest
from coconet.config import CoconetConfig
from coconet.model import CoconetModel


def test_grow_fish_clips_barramundi_bounds(make_tiny_config) -> None:
    cfg = make_tiny_config()
    model = CoconetModel(cfg)
    model.setup(init_output=False)
    model.year = 2000
    model.ensemble = 0
    model.initialise_run()

    reef = 0
    sl = model._sites_for_reef(reef)
    model.B[sl] = 5000.0
    model.T[sl] = 30.0
    model.C_site[sl] = 0.8
    model.R_site[sl] = 0.1
    for k in ("0", "1", "2", "3", "4", "5"):
        model.E[k][reef] = 100.0
        model.G[k][reef] = 100.0
    model.C_reef[reef] = 0.5

    model.rng.seed(999)
    model.grow_fish(reef)

    assert np.all(model.B[sl] >= 100.0)
    assert np.all(model.B[sl] <= model.B_max * (model.C_site[sl] + model.R_site[sl]))
    assert np.all(model.T[sl] >= 1.0)
    assert np.all(model.T[sl] <= model.T_max * model.C_site[sl])


def test_projection_bleach_probability_ssp_branches() -> None:
    cfg = CoconetConfig()
    m = CoconetModel(cfg)
    m.cfg = cfg
    cfg.SSP = 2.6
    m.year = 2070
    assert m._projection_bleach_probability() == pytest.approx(0.47)
    cfg.SSP = 99.0
    assert m._projection_bleach_probability() == 0.0


def test_reef_in_intervention_bounds() -> None:
    cfg = CoconetConfig(
        reefs_file="tests/fixtures/reefs_two.csv",
        coastline_file="tests/fixtures/coastline_clip.csv",
        output_file="unused.csv",
    )
    m = CoconetModel(cfg)
    m.setup(init_output=False)
    lon0, lat0 = float(m.x[0]), float(m.y[0])
    expected = (
        lon0 > cfg.intervene_lon_min
        and lon0 < cfg.intervene_lon_max
        and lat0 > cfg.intervene_lat_min
        and lat0 < cfg.intervene_lat_max
    )
    assert bool(m._reef_in_intervention_bounds(0)) is expected
