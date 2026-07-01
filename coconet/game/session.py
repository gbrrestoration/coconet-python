"""Server-side Reef Rescuer session state for the standalone web game."""

from __future__ import annotations

import random
import secrets
import threading
import time
from dataclasses import dataclass, field
from typing import Any

from coconet.game.facts import REEF_FACTS
from coconet.game.formatting import format_elapsed, format_survival_display
from coconet.game.sim import (
    INTERVENTION_COSTS,
    INTERVENTION_LABELS,
    InterventionKind,
    ReefState,
    SimEvent,
    apply_intervention,
    format_meters,
    initial_reef_state,
    is_reef_collapsed,
    simulate_step,
)

SIM_INTERVAL_SECONDS = 4.0
FACT_INTERVAL_SECONDS = 5.0


def serialize_reef(state: ReefState) -> dict[str, Any]:
    return {
        "coral_cover": state.coral_cover,
        "fish_biodiversity": state.fish_biodiversity,
        "dhw": state.dhw,
        "cots_pressure": state.cots_pressure,
        "management_points": state.management_points,
        "interventions_used": state.interventions_used,
        "threats_weathered": state.threats_weathered,
        "score": state.score,
    }


def intervention_catalog() -> list[dict[str, Any]]:
    return [
        {
            "kind": kind,
            "label": INTERVENTION_LABELS[kind],
            "cost": INTERVENTION_COSTS[kind],
        }
        for kind in INTERVENTION_LABELS
    ]


@dataclass
class GameSession:
    session_id: str
    reef: ReefState = field(default_factory=initial_reef_state)
    rng: random.Random = field(default_factory=random.Random)
    fact_index: int = 0
    high_score_seconds: int = 0
    game_over: bool = False
    game_elapsed_seconds: int = 0
    segment_started_at: float | None = None
    last_event_message: str = "Survive as long as you can — threats intensify every minute."
    last_sim_at: float = field(default_factory=time.monotonic)
    last_fact_at: float = field(default_factory=time.monotonic)

    @classmethod
    def create(cls) -> GameSession:
        session_id = secrets.token_urlsafe(16)
        now = time.monotonic()
        return cls(
            session_id=session_id,
            segment_started_at=now,
            last_sim_at=now,
            last_fact_at=now,
        )

    def survival_seconds(self, now: float | None = None) -> int:
        now = time.monotonic() if now is None else now
        extra = 0
        if self.segment_started_at is not None and not self.game_over:
            extra = int(now - self.segment_started_at)
        return self.game_elapsed_seconds + extra

    def advance(self, now: float | None = None) -> None:
        now = time.monotonic() if now is None else now
        if self.game_over:
            return

        while now - self.last_sim_at >= SIM_INTERVAL_SECONDS:
            sim_time = self.last_sim_at + SIM_INTERVAL_SECONDS
            self._simulate_once(sim_time)
            self.last_sim_at += SIM_INTERVAL_SECONDS
            if self.game_over:
                break

        while now - self.last_fact_at >= FACT_INTERVAL_SECONDS:
            self.fact_index = (self.fact_index + 1) % len(REEF_FACTS)
            self.last_fact_at += FACT_INTERVAL_SECONDS

    def intervene(self, kind: InterventionKind) -> SimEvent:
        if self.game_over:
            return SimEvent("Game over — restart to play again.", "error")
        self.reef, event = apply_intervention(self.reef, kind)
        self.last_event_message = event.message
        if is_reef_collapsed(self.reef):
            self._set_game_over()
        return event

    def restart(self) -> None:
        self._record_survival()
        self.reef = initial_reef_state()
        self.game_over = False
        now = time.monotonic()
        self.game_elapsed_seconds = 0
        self.segment_started_at = now
        self.last_sim_at = now
        self.last_fact_at = now
        self.last_event_message = "New round — survive longer than your best time."

    def to_payload(self, now: float | None = None) -> dict[str, Any]:
        now = time.monotonic() if now is None else now
        self.advance(now)
        survival = self.survival_seconds(now)
        return {
            "session_id": self.session_id,
            "reef": serialize_reef(self.reef),
            "meters": format_meters(self.reef),
            "fact": REEF_FACTS[self.fact_index],
            "event_message": self.last_event_message,
            "game_over": self.game_over,
            "survival_seconds": survival,
            "high_score_seconds": self.high_score_seconds,
            "elapsed_display": format_survival_display(survival, self.high_score_seconds),
            "interventions": intervention_catalog(),
        }

    def _simulate_once(self, sim_time: float) -> None:
        elapsed = self.survival_seconds(sim_time)
        self.reef, events = simulate_step(self.reef, rng=self.rng, elapsed_seconds=elapsed)
        if events:
            self.last_event_message = events[-1].message
        if is_reef_collapsed(self.reef):
            self._set_game_over()

    def _set_game_over(self) -> None:
        if self.game_over:
            return
        self.game_over = True
        before_best = self.high_score_seconds
        survival = self._finalize_survival_time()
        record_note = " New best survival!" if survival > before_best else ""
        self.last_event_message = (
            f"Reef collapsed after {format_elapsed(survival)}.{record_note} "
            f"Best: {format_elapsed(self.high_score_seconds)}."
        )

    def _record_survival(self) -> None:
        if self.game_over:
            return
        self._pause_timer()
        self.high_score_seconds = max(self.high_score_seconds, self.game_elapsed_seconds)

    def _finalize_survival_time(self) -> int:
        self._pause_timer()
        survival = self.game_elapsed_seconds
        self.high_score_seconds = max(self.high_score_seconds, survival)
        return survival

    def _pause_timer(self) -> None:
        if self.segment_started_at is None:
            return
        self.game_elapsed_seconds += int(time.monotonic() - self.segment_started_at)
        self.segment_started_at = None


class SessionStore:
    """Thread-safe in-memory session registry."""

    def __init__(self) -> None:
        self._sessions: dict[str, GameSession] = {}
        self._lock = threading.Lock()

    def create(self) -> GameSession:
        session = GameSession.create()
        with self._lock:
            self._sessions[session.session_id] = session
        return session

    def get(self, session_id: str) -> GameSession | None:
        with self._lock:
            return self._sessions.get(session_id)
