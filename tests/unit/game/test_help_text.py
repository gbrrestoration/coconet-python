from __future__ import annotations

from coconet.game.help_text import HOW_TO_PLAY_STEPS, HOW_TO_PLAY_TITLE, how_to_play_payload


def test_how_to_play_payload() -> None:
    payload = how_to_play_payload()
    assert payload["title"] == HOW_TO_PLAY_TITLE
    assert payload["steps"] == list(HOW_TO_PLAY_STEPS)
    assert len(payload["steps"]) >= 5
