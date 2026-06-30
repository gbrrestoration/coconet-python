from __future__ import annotations

import random
from dataclasses import replace

from coconet.game.sim import (
    advance_pending_gains,
    apply_intervention,
    initial_reef_state,
    maybe_random_threat,
    simulate_step,
)
from coconet.game.ui import format_elapsed, format_survival_display


def test_format_elapsed() -> None:
    assert format_elapsed(0) == "0:00"
    assert format_elapsed(65) == "1:05"


def test_format_survival_display() -> None:
    assert format_survival_display(0, 0) == "Time 0:00 · Best 0:00"
    assert format_survival_display(65, 120) == "Time 1:05 · Best 2:00 · Minute 1"


def test_coral_seeding_increases_cover() -> None:
    state = initial_reef_state()
    deployed, event = apply_intervention(state, "coral_seeding")
    assert deployed.coral_cover == state.coral_cover
    assert event.kind == "intervention"

    after_one, _ = advance_pending_gains(deployed)
    after_two, _ = advance_pending_gains(after_one)
    assert after_two.coral_cover > state.coral_cover


def test_bleaching_triggers_at_high_dhw() -> None:
    hot = replace(initial_reef_state(), dhw=10.0)
    updated, event = maybe_random_threat(hot, rng=random.Random(3))
    assert event is not None
    assert event.kind == "bleaching"
    assert updated.coral_cover < hot.coral_cover


def test_simulate_step_returns_events_sometimes() -> None:
    state = initial_reef_state()
    _, events = simulate_step(state, rng=random.Random(1))
    assert isinstance(events, list)
