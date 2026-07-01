"""Reef Rescuer mini-game simulation (independent of the CoCoNet model)."""

from __future__ import annotations

import random
from dataclasses import dataclass, replace
from typing import Literal

ThreatKind = Literal["cyclone", "bleaching", "cots"]
InterventionKind = Literal[
    "cots_control",
    "regional_shading",
    "reef_shading",
    "coral_seeding",
    "coral_slick",
    "fishing_regulation",
    "emperor_release",
    "rubble_consolidation",
    "catchment_restore",
    "ph_protection",
]

INTERVENTION_COSTS: dict[InterventionKind, int] = {
    "cots_control": 2,
    "regional_shading": 2,
    "reef_shading": 1,
    "coral_seeding": 2,
    "coral_slick": 1,
    "fishing_regulation": 1,
    "emperor_release": 2,
    "rubble_consolidation": 1,
    "catchment_restore": 2,
    "ph_protection": 2,
}

MANAGEMENT_POINT_CAP = 8
MANAGEMENT_POINTS_PER_TICK = 1
DELAYED_EFFECT_TICKS = 2

# Difficulty: base floor at game start, then +18% per full minute survived.
BASE_DIFFICULTY = 1.28
DIFFICULTY_PER_MINUTE = 0.18

CORAL_SEEDING_GAIN = 18.0
CORAL_SLICK_GAIN = 10.0
FISHING_REGULATION_GAIN = 12.0
EMPEROR_RELEASE_GAIN = 15.0

INTERVENTION_LABELS: dict[InterventionKind, str] = {
    "cots_control": "CoTS control",
    "regional_shading": "Regional shading",
    "reef_shading": "Reef shading",
    "coral_seeding": "Coral seeding (tt)",
    "coral_slick": "Coral slick",
    "fishing_regulation": "Fishing regulation",
    "emperor_release": "Emperor release",
    "rubble_consolidation": "Rubble consolidation",
    "catchment_restore": "Catchment restoration",
    "ph_protection": "Ocean pH protection",
}


@dataclass(frozen=True, slots=True)
class ReefState:
    coral_cover: float = 62.0
    fish_biodiversity: float = 58.0
    dhw: float = 5.5
    cots_pressure: float = 32.0
    management_points: int = 3
    dhw_suppression_ticks: int = 0
    interventions_used: int = 0
    threats_weathered: int = 0
    pending_coral: tuple[tuple[float, int], ...] = ()
    pending_fish: tuple[tuple[float, int], ...] = ()

    @property
    def score(self) -> int:
        return round(self.coral_cover + self.fish_biodiversity + self.interventions_used * 4)


def is_reef_collapsed(state: ReefState) -> bool:
    """True when both coral cover and fish biodiversity have been lost."""
    return state.coral_cover <= 0 and state.fish_biodiversity <= 0


def difficulty_multiplier(elapsed_seconds: int) -> float:
    """Ramp threat pressure from a raised base, +18% per full minute survived."""
    minutes = max(0, elapsed_seconds) // 60
    return BASE_DIFFICULTY + minutes * DIFFICULTY_PER_MINUTE


def _damage_scale(difficulty: float) -> float:
    return 1.0 + (difficulty - 1.0) * 0.65


@dataclass(frozen=True, slots=True)
class SimEvent:
    message: str
    kind: str


def _clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def initial_reef_state() -> ReefState:
    return ReefState()


def advance_pending_gains(state: ReefState) -> tuple[ReefState, list[SimEvent]]:
    """Apply staged coral and fish gains from recent interventions."""
    events: list[SimEvent] = []
    coral_delta = 0.0
    fish_delta = 0.0
    new_coral: list[tuple[float, int]] = []
    new_fish: list[tuple[float, int]] = []

    for remaining, ticks_left in state.pending_coral:
        per_tick = remaining / ticks_left
        coral_delta += per_tick
        ticks_left -= 1
        remaining -= per_tick
        if ticks_left > 0:
            new_coral.append((remaining, ticks_left))

    for remaining, ticks_left in state.pending_fish:
        per_tick = remaining / ticks_left
        fish_delta += per_tick
        ticks_left -= 1
        remaining -= per_tick
        if ticks_left > 0:
            new_fish.append((remaining, ticks_left))

    if coral_delta > 0:
        events.append(
            SimEvent(
                f"Coral planting taking hold: +{coral_delta:.0f}% cover.",
                "intervention_effect",
            )
        )
    if fish_delta > 0:
        events.append(
            SimEvent(
                f"Fish populations responding: +{fish_delta:.0f}% biodiversity.",
                "intervention_effect",
            )
        )

    updated = replace(
        state,
        coral_cover=_clamp(state.coral_cover + coral_delta),
        fish_biodiversity=_clamp(state.fish_biodiversity + fish_delta),
        pending_coral=tuple(new_coral),
        pending_fish=tuple(new_fish),
    )
    return updated, events


def _queue_pending_gain(
    pending: tuple[tuple[float, int], ...],
    amount: float,
) -> tuple[tuple[float, int], ...]:
    return (*pending, (amount, DELAYED_EFFECT_TICKS))


def ambient_tick(
    state: ReefState,
    *,
    rng: random.Random | None = None,
    difficulty: float = 1.0,
) -> tuple[ReefState, SimEvent | None]:
    """Background warming, slow recovery, and management budget refresh."""
    rng = rng or random.Random()
    dhw_rise = 0.35 if state.dhw_suppression_ticks > 0 else 0.65
    dhw_rise += rng.uniform(-0.05, 0.15)
    dhw_rise *= difficulty
    new_dhw = max(0.0, state.dhw + dhw_rise)
    suppression = max(0, state.dhw_suppression_ticks - 1)

    recovery_scale = 1.0 + (difficulty - 1.0) * 0.45
    coral = _clamp(state.coral_cover + 0.4 / recovery_scale)
    fish = _clamp(state.fish_biodiversity + 0.2 / recovery_scale)
    points = min(
        MANAGEMENT_POINT_CAP,
        state.management_points + MANAGEMENT_POINTS_PER_TICK,
    )

    updated = replace(
        state,
        dhw=new_dhw,
        dhw_suppression_ticks=suppression,
        coral_cover=coral,
        fish_biodiversity=fish,
        management_points=points,
    )
    if suppression > 0 and state.dhw_suppression_ticks == 0:
        return updated, SimEvent("Catchment restoration is fading.", "ambient")
    return updated, None


def maybe_random_threat(
    state: ReefState,
    *,
    rng: random.Random | None = None,
    difficulty: float = 1.0,
) -> tuple[ReefState, SimEvent | None]:
    rng = rng or random.Random()
    roll = rng.random()

    bleach_chance = min(0.85, 0.55 * (1.0 + (difficulty - 1.0) * 0.45))
    if state.dhw >= 8.0 and roll < bleach_chance:
        return _apply_bleaching(state, difficulty)
    cyclone_chance = min(0.35, 0.14 * difficulty)
    if roll < cyclone_chance:
        return _apply_cyclone(state, difficulty)
    cots_roll_chance = min(0.24, 0.11 * difficulty)
    cots_trigger_chance = min(0.58, 0.38 * difficulty)
    if (state.cots_pressure >= 45 or roll < cots_roll_chance) and rng.random() < cots_trigger_chance:
        return _apply_cots_outbreak(state, difficulty)
    return state, None


def _apply_bleaching(state: ReefState, difficulty: float = 1.0) -> tuple[ReefState, SimEvent]:
    severity = min(22.0, 8.0 + (state.dhw - 8.0) * 1.8)
    severity *= _damage_scale(difficulty)
    coral_loss = severity * 0.7
    fish_loss = severity * 0.35
    updated = replace(
        state,
        coral_cover=_clamp(state.coral_cover - coral_loss),
        fish_biodiversity=_clamp(state.fish_biodiversity - fish_loss),
        threats_weathered=state.threats_weathered + 1,
    )
    return updated, SimEvent(
        f"Bleaching event at DHW {state.dhw:.1f}: coral -{coral_loss:.0f}%, fish -{fish_loss:.0f}%.",
        "bleaching",
    )


def _apply_cyclone(state: ReefState, difficulty: float = 1.0) -> tuple[ReefState, SimEvent]:
    scale = _damage_scale(difficulty)
    coral_loss = (16.0 + state.dhw * 0.3) * scale
    fish_loss = 9.0 * scale
    updated = replace(
        state,
        coral_cover=_clamp(state.coral_cover - coral_loss),
        fish_biodiversity=_clamp(state.fish_biodiversity - fish_loss),
        cots_pressure=_clamp(state.cots_pressure + 8, high=100),
        threats_weathered=state.threats_weathered + 1,
    )
    return updated, SimEvent(
        f"Cyclone impact: coral -{coral_loss:.0f}%, fish -{fish_loss:.0f}%.",
        "cyclone",
    )


def _apply_cots_outbreak(state: ReefState, difficulty: float = 1.0) -> tuple[ReefState, SimEvent]:
    scale = _damage_scale(difficulty)
    coral_loss = (10.0 + state.cots_pressure * 0.12) * scale
    fish_loss = (11.0 + state.cots_pressure * 0.08) * scale
    updated = replace(
        state,
        coral_cover=_clamp(state.coral_cover - coral_loss),
        fish_biodiversity=_clamp(state.fish_biodiversity - fish_loss),
        cots_pressure=_clamp(state.cots_pressure + 18, high=100),
        threats_weathered=state.threats_weathered + 1,
    )
    return updated, SimEvent(
        f"CoTS outbreak: coral -{coral_loss:.0f}%, fish -{fish_loss:.0f}%.",
        "cots",
    )


def apply_intervention(
    state: ReefState,
    kind: InterventionKind,
) -> tuple[ReefState, SimEvent]:
    cost = INTERVENTION_COSTS[kind]
    if state.management_points < cost:
        return state, SimEvent(f"Not enough management points for {INTERVENTION_LABELS[kind]}.", "error")

    updated = replace(
        state,
        management_points=state.management_points - cost,
        interventions_used=state.interventions_used + 1,
    )

    if kind == "cots_control":
        updated = replace(
            updated,
            cots_pressure=_clamp(updated.cots_pressure - 35, high=100),
            coral_cover=_clamp(updated.coral_cover + 4),
        )
        msg = "CoTS control vessels culled starfish and eased grazing pressure."
    elif kind == "regional_shading":
        updated = replace(updated, dhw=max(0.0, updated.dhw - 4.5))
        msg = "Regional shading lowered degree heating weeks."
    elif kind == "reef_shading":
        updated = replace(updated, dhw=max(0.0, updated.dhw - 2.5))
        msg = "Local reef shading reduced thermal stress."
    elif kind == "coral_seeding":
        updated = replace(
            updated,
            pending_coral=_queue_pending_gain(updated.pending_coral, CORAL_SEEDING_GAIN),
        )
        msg = "Coral seeding deployed — cover should rise over the next couple of ticks."
    elif kind == "coral_slick":
        updated = replace(
            updated,
            pending_coral=_queue_pending_gain(updated.pending_coral, CORAL_SLICK_GAIN),
        )
        msg = "Coral slick released — larvae should settle over the next couple of ticks."
    elif kind == "fishing_regulation":
        updated = replace(
            updated,
            pending_fish=_queue_pending_gain(updated.pending_fish, FISHING_REGULATION_GAIN),
        )
        msg = "Fishing regulations enacted — fish biodiversity should recover over the next couple of ticks."
    elif kind == "emperor_release":
        updated = replace(
            updated,
            pending_fish=_queue_pending_gain(updated.pending_fish, EMPEROR_RELEASE_GAIN),
        )
        msg = "Juvenile emperors released — fish biodiversity should rise over the next couple of ticks."
    elif kind == "rubble_consolidation":
        updated = replace(updated, coral_cover=_clamp(updated.coral_cover + 8))
        msg = "Rubble consolidation created new settlement substrate."
    elif kind == "catchment_restore":
        updated = replace(updated, dhw_suppression_ticks=4)
        msg = "Catchment restoration slowed flood loads and heat accumulation."
    else:  # ph_protection
        updated = replace(
            updated,
            dhw=max(0.0, updated.dhw - 3.0),
            coral_cover=_clamp(updated.coral_cover + 3),
        )
        msg = "Ocean acidification treatment buffered growth conditions."

    return updated, SimEvent(msg, "intervention")


def simulate_step(
    state: ReefState,
    *,
    rng: random.Random | None = None,
    elapsed_seconds: int = 0,
) -> tuple[ReefState, list[SimEvent]]:
    rng = rng or random.Random()
    difficulty = difficulty_multiplier(elapsed_seconds)
    events: list[SimEvent] = []
    state, ambient_event = ambient_tick(state, rng=rng, difficulty=difficulty)
    if ambient_event is not None:
        events.append(ambient_event)
    state, pending_events = advance_pending_gains(state)
    events.extend(pending_events)
    state, threat = maybe_random_threat(state, rng=rng, difficulty=difficulty)
    if threat is not None:
        events.append(threat)
    return state, events


def format_meters(state: ReefState) -> str:
    return (
        f"Coral cover {state.coral_cover:.0f}% · Fish {state.fish_biodiversity:.0f}% · "
        f"DHW {state.dhw:.1f} · CoTS pressure {state.cots_pressure:.0f}% · "
        f"Mgmt points {state.management_points}"
    )
