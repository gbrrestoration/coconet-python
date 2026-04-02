from __future__ import annotations

from coconet.model import CoconetModel


def test_spinup_checkpoint_roundtrip(make_tiny_config) -> None:
    cfg = make_tiny_config()
    m1 = CoconetModel(cfg)
    m1.setup(init_output=False)
    m1.initialise_run()
    m1.E_i["0"][0] = 333.0
    m1.B_i[0] = 12.5
    cp = m1.export_spinup_checkpoint()

    m2 = CoconetModel(cfg)
    m2.setup(init_output=False)
    m2.E_i["0"][:] = 0.0
    m2.import_spinup_checkpoint(cp)

    assert m2.E_i["0"][0] == 333.0
    assert m2.B_i[0] == 12.5
