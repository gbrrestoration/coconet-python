from __future__ import annotations

from dataclasses import replace

from coconet.game.session import GameSession
from coconet.game.sim import initial_reef_state


def test_session_restart_resets_reef() -> None:
    session = GameSession.create()
    session.reef = replace(initial_reef_state(), coral_cover=10.0, fish_biodiversity=5.0)
    session.restart()
    assert session.reef.coral_cover == 62.0
    assert session.game_over is False


def test_session_intervention_updates_event() -> None:
    session = GameSession.create()
    event = session.intervene("reef_shading")
    assert event.kind == "intervention"
    assert session.last_event_message == event.message


def test_session_advances_sim_over_time() -> None:
    session = GameSession.create()
    start_dhw = session.reef.dhw
    now = session.last_sim_at + 4.5
    session.advance(now)
    assert session.reef.dhw >= start_dhw


def test_session_game_over_on_collapse() -> None:
    session = GameSession.create()
    session.reef = replace(initial_reef_state(), coral_cover=0.0, fish_biodiversity=0.0)
    session._set_game_over()
    assert session.game_over is True
    assert session.high_score_seconds >= 0


def test_session_payload_includes_interventions() -> None:
    session = GameSession.create()
    payload = session.to_payload()
    assert payload["session_id"] == session.session_id
    assert len(payload["interventions"]) == 10
    assert "elapsed_display" in payload
