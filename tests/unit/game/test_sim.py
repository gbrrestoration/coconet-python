from __future__ import annotations

import random
from dataclasses import replace

import pytest
from coconet.game.sim import (
    advance_pending_gains,
    ambient_tick,
    apply_intervention,
    difficulty_multiplier,
    initial_reef_state,
    is_reef_collapsed,
)


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


def test_difficulty_multiplier_increases_each_minute() -> None:
    assert difficulty_multiplier(0) == 1.28
    assert difficulty_multiplier(59) == 1.28
    assert difficulty_multiplier(60) == pytest.approx(1.46)
    assert difficulty_multiplier(120) == pytest.approx(1.64)


def test_higher_difficulty_raises_dhw_faster() -> None:
    state = initial_reef_state()
    low, _ = ambient_tick(state, rng=random.Random(0), difficulty=1.0)
    high, _ = ambient_tick(state, rng=random.Random(0), difficulty=2.0)
    assert high.dhw > low.dhw


def test_management_points_refresh_each_tick() -> None:
    spent = replace(initial_reef_state(), management_points=2)
    updated, _ = ambient_tick(spent, rng=random.Random(0), difficulty=2.5)
    assert updated.management_points == 3


def test_management_points_refresh_even_when_reef_is_stressed() -> None:
    stressed = replace(
        initial_reef_state(),
        coral_cover=5,
        fish_biodiversity=4,
        management_points=1,
    )
    updated, _ = ambient_tick(stressed, rng=random.Random(0), difficulty=3.0)
    assert updated.management_points == 2


def test_initial_management_points_are_three() -> None:
    assert initial_reef_state().management_points == 3


def test_coral_seeding_is_delayed() -> None:
    state = initial_reef_state()
    deployed, event = apply_intervention(state, "coral_seeding")
    assert deployed.coral_cover == state.coral_cover
    assert len(deployed.pending_coral) == 1
    assert event.kind == "intervention"

    after_one, events = advance_pending_gains(deployed)
    assert after_one.coral_cover > state.coral_cover
    assert after_one.coral_cover < state.coral_cover + 18
    assert events[-1].kind == "intervention_effect"

    after_two, _ = advance_pending_gains(after_one)
    assert after_two.coral_cover == pytest.approx(state.coral_cover + 18)
    assert after_two.pending_coral == ()


def test_fishing_regulation_is_delayed() -> None:
    state = initial_reef_state()
    deployed, _ = apply_intervention(state, "fishing_regulation")
    assert deployed.fish_biodiversity == state.fish_biodiversity

    after_one, _ = advance_pending_gains(deployed)
    after_two, _ = advance_pending_gains(after_one)
    assert after_two.fish_biodiversity == pytest.approx(state.fish_biodiversity + 12)
