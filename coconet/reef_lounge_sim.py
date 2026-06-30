"""Lightweight reef threat / intervention simulation for Reef Lounge."""

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
    coral_cover: float = 72.0
    fish_biodiversity: float = 68.0
    dhw: float = 3.0
    cots_pressure: float = 15.0
    management_points: int = 3
    dhw_suppression_ticks: int = 0
    interventions_used: int = 0
    threats_weathered: int = 0

    @property
    def score(self) -> int:
        return round(self.coral_cover + self.fish_biodiversity + self.interventions_used * 4)


def is_reef_collapsed(state: ReefState) -> bool:
    """True when both coral cover and fish biodiversity have been lost."""
    return state.coral_cover <= 0 and state.fish_biodiversity <= 0


@dataclass(frozen=True, slots=True)
class SimEvent:
    message: str
    kind: str


def _clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def initial_reef_state() -> ReefState:
    return ReefState()


def ambient_tick(state: ReefState, *, rng: random.Random | None = None) -> tuple[ReefState, SimEvent | None]:
    """Background warming, slow recovery, and management budget refresh."""
    rng = rng or random.Random()
    dhw_rise = 0.35 if state.dhw_suppression_ticks > 0 else 0.65
    dhw_rise += rng.uniform(-0.05, 0.15)
    new_dhw = max(0.0, state.dhw + dhw_rise)
    suppression = max(0, state.dhw_suppression_ticks - 1)

    coral = _clamp(state.coral_cover + 0.4)
    fish = _clamp(state.fish_biodiversity + 0.2)
    points = min(5, state.management_points)
    if state.coral_cover >= 35 and state.fish_biodiversity >= 30:
        points = min(5, points + 1)

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
) -> tuple[ReefState, SimEvent | None]:
    rng = rng or random.Random()
    roll = rng.random()

    if state.dhw >= 8.0 and roll < 0.55:
        return _apply_bleaching(state)
    if roll < 0.12:
        return _apply_cyclone(state)
    if (state.cots_pressure >= 45 or roll < 0.1) and rng.random() < 0.35:
        return _apply_cots_outbreak(state)
    return state, None


def _apply_bleaching(state: ReefState) -> tuple[ReefState, SimEvent]:
    severity = min(22.0, 8.0 + (state.dhw - 8.0) * 1.8)
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


def _apply_cyclone(state: ReefState) -> tuple[ReefState, SimEvent]:
    coral_loss = 16.0 + state.dhw * 0.3
    fish_loss = 9.0
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


def _apply_cots_outbreak(state: ReefState) -> tuple[ReefState, SimEvent]:
    coral_loss = 10.0 + state.cots_pressure * 0.12
    fish_loss = 11.0 + state.cots_pressure * 0.08
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
        updated = replace(updated, coral_cover=_clamp(updated.coral_cover + 18))
        msg = "Thermally tolerant coral seeding boosted cover."
    elif kind == "coral_slick":
        updated = replace(updated, coral_cover=_clamp(updated.coral_cover + 10))
        msg = "A coral slick settled larvae onto depleted reef areas."
    elif kind == "fishing_regulation":
        updated = replace(updated, fish_biodiversity=_clamp(updated.fish_biodiversity + 12))
        msg = "Catch reductions helped emperor and trout populations recover."
    elif kind == "emperor_release":
        updated = replace(updated, fish_biodiversity=_clamp(updated.fish_biodiversity + 15))
        msg = "Juvenile emperors were released on priority reefs."
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


def simulate_step(state: ReefState, *, rng: random.Random | None = None) -> tuple[ReefState, list[SimEvent]]:
    rng = rng or random.Random()
    events: list[SimEvent] = []
    state, ambient_event = ambient_tick(state, rng=rng)
    if ambient_event is not None:
        events.append(ambient_event)
    state, threat = maybe_random_threat(state, rng=rng)
    if threat is not None:
        events.append(threat)
    return state, events


def format_meters(state: ReefState) -> str:
    return (
        f"Coral cover {state.coral_cover:.0f}% · Fish {state.fish_biodiversity:.0f}% · "
        f"DHW {state.dhw:.1f} · CoTS pressure {state.cots_pressure:.0f}% · "
        f"Mgmt points {state.management_points}"
    )
