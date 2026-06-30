from __future__ import annotations

from dataclasses import replace

from coconet.reef_lounge_sim import apply_intervention, initial_reef_state, is_reef_collapsed


def test_cots_control_reduces_pressure() -> None:
    stressed = replace(initial_reef_state(), cots_pressure=80, management_points=5)
    updated, _ = apply_intervention(stressed, "cots_control")
    assert updated.cots_pressure < stressed.cots_pressure


def test_intervention_requires_management_points() -> None:
    broke = replace(initial_reef_state(), management_points=0)
    updated, event = apply_intervention(broke, "coral_seeding")
    assert updated.coral_cover == broke.coral_cover
    assert event.kind == "error"


def test_is_reef_collapsed_when_coral_and_fish_are_zero() -> None:
    collapsed = replace(initial_reef_state(), coral_cover=0, fish_biodiversity=0)
    surviving = replace(initial_reef_state(), coral_cover=0, fish_biodiversity=10)
    assert is_reef_collapsed(collapsed)
    assert not is_reef_collapsed(surviving)
