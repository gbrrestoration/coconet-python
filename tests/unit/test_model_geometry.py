from __future__ import annotations

from coconet.model import CoconetConfig, CoconetModel


def test_targets_in_cone_zero_distance_empty() -> None:
    m = CoconetModel(
        CoconetConfig(
            reefs_file="tests/fixtures/reefs_two.csv",
            coastline_file="tests/fixtures/coastline_clip.csv",
            output_file="unused.csv",
        )
    )
    m.setup(init_output=False)
    idx, dist = m._targets_in_cone(0, 0.0, 0.0, 90.0)
    assert idx.size == 0
    assert dist.size == 0


def test_targets_in_radius_excludes_source() -> None:
    m = CoconetModel(
        CoconetConfig(
            reefs_file="tests/fixtures/reefs_two.csv",
            coastline_file="tests/fixtures/coastline_clip.csv",
            output_file="unused.csv",
        )
    )
    m.setup(init_output=False)
    d0 = float(m.dist_matrix[0, 1])
    nbrs = m._targets_in_radius(0, d0 + 1.0)
    assert 0 not in set(nbrs.tolist())
    assert {int(x) for x in nbrs.tolist()} == {1}


def test_reef_kernel_reads_expected_columns() -> None:
    m = CoconetModel(
        CoconetConfig(
            reefs_file="tests/fixtures/reefs_two.csv",
            coastline_file="tests/fixtures/coastline_clip.csv",
            output_file="unused.csv",
        )
    )
    m.setup(init_output=False)
    base = m._kernel_base_coral(15, 10)
    k = m._reef_kernel(0, base)
    row = m.reef_numeric[0]
    assert k.con1 == float(row[base])
    assert k.dis2 == float(row[base + 7])
