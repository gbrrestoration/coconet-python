from __future__ import annotations

from pathlib import Path

import pytest
from coconet.game.leaderboard import (
    LeaderboardEntry,
    LeaderboardStore,
    normalize_player_name,
    qualifies_for_leaderboard,
)


def test_qualifies_when_fewer_than_ten_entries() -> None:
    entries = [LeaderboardEntry("A", 30, 0.0)]
    assert qualifies_for_leaderboard(entries, 5)


def test_qualifies_when_beats_worst_top_ten() -> None:
    entries = [LeaderboardEntry(f"P{i}", 100 - i, 0.0) for i in range(10)]
    assert qualifies_for_leaderboard(entries, 92)
    assert not qualifies_for_leaderboard(entries, 90)


def test_submit_and_persist(tmp_path: Path) -> None:
    path = tmp_path / "scores.json"
    store = LeaderboardStore(path)
    result = store.submit("Reef Ranger", 125)
    assert result["accepted"] is True
    assert result["rank"] == 1

    reloaded = LeaderboardStore(path)
    payload = reloaded.payload()
    assert payload["entries"][0]["name"] == "Reef Ranger"
    assert payload["entries"][0]["survival_seconds"] == 125


def test_rejects_score_outside_top_ten(tmp_path: Path) -> None:
    path = tmp_path / "scores.json"
    store = LeaderboardStore(path)
    for score in range(200, 100, -10):
        store.submit(f"Player{score}", score)
    result = store.submit("Slow", 5)
    assert result["accepted"] is False


def test_normalize_player_name_rejects_empty() -> None:
    with pytest.raises(ValueError):
        normalize_player_name("   ")
