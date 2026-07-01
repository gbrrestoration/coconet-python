"""Persistent top-10 survival leaderboard for Reef Rescuer."""

from __future__ import annotations

import json
import re
import threading
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from coconet.game.formatting import format_elapsed

LEADERBOARD_SIZE = 10
MAX_NAME_LENGTH = 24
_NAME_PATTERN = re.compile(r"^[\w .\-']+$", re.UNICODE)


@dataclass(frozen=True, slots=True)
class LeaderboardEntry:
    name: str
    survival_seconds: int
    recorded_at: float

    def to_payload(self, *, rank: int) -> dict[str, Any]:
        return {
            "rank": rank,
            "name": self.name,
            "survival_seconds": self.survival_seconds,
            "elapsed_display": format_elapsed(self.survival_seconds),
        }


def normalize_player_name(name: str) -> str:
    cleaned = " ".join(name.strip().split())
    if not cleaned:
        msg = "Name is required."
        raise ValueError(msg)
    if len(cleaned) > MAX_NAME_LENGTH:
        msg = f"Name must be {MAX_NAME_LENGTH} characters or fewer."
        raise ValueError(msg)
    if not _NAME_PATTERN.match(cleaned):
        msg = "Name may only contain letters, numbers, spaces, and . - '"
        raise ValueError(msg)
    return cleaned


def qualifies_for_leaderboard(entries: list[LeaderboardEntry], survival_seconds: int) -> bool:
    if survival_seconds <= 0:
        return False
    if len(entries) < LEADERBOARD_SIZE:
        return True
    return survival_seconds > min(entry.survival_seconds for entry in entries)


class LeaderboardStore:
    """Thread-safe JSON-backed top-10 store."""

    def __init__(self, path: Path) -> None:
        self._path = path
        self._lock = threading.Lock()
        self._entries: list[LeaderboardEntry] = []
        self._load()

    @property
    def path(self) -> Path:
        return self._path

    def top_entries(self) -> list[LeaderboardEntry]:
        with self._lock:
            return list(self._entries)

    def payload(self) -> dict[str, Any]:
        entries = self.top_entries()
        return {
            "entries": [entry.to_payload(rank=index + 1) for index, entry in enumerate(entries)],
            "size": LEADERBOARD_SIZE,
        }

    def check(self, survival_seconds: int) -> dict[str, Any]:
        with self._lock:
            qualifies = qualifies_for_leaderboard(self._entries, survival_seconds)
            cutoff = None
            if len(self._entries) >= LEADERBOARD_SIZE:
                cutoff = min(entry.survival_seconds for entry in self._entries)
            return {
                "qualifies": qualifies,
                "survival_seconds": survival_seconds,
                "cutoff_seconds": cutoff,
                "cutoff_display": format_elapsed(cutoff) if cutoff is not None else None,
            }

    def submit(self, name: str, survival_seconds: int) -> dict[str, Any]:
        player_name = normalize_player_name(name)
        if survival_seconds <= 0:
            msg = "Survival time must be greater than zero."
            raise ValueError(msg)

        with self._lock:
            if not qualifies_for_leaderboard(self._entries, survival_seconds):
                return {
                    "accepted": False,
                    "message": "Score is not in the top 10.",
                    **self._payload_unlocked(),
                }

            recorded_at = time.time()
            new_entry = LeaderboardEntry(
                name=player_name,
                survival_seconds=survival_seconds,
                recorded_at=recorded_at,
            )
            self._entries.append(new_entry)
            self._entries.sort(key=lambda entry: entry.survival_seconds, reverse=True)
            self._entries = self._entries[:LEADERBOARD_SIZE]
            self._save_unlocked()

            rank = next(
                (
                    index + 1
                    for index, entry in enumerate(self._entries)
                    if entry.recorded_at == recorded_at
                ),
                None,
            )
            return {
                "accepted": True,
                "rank": rank,
                "message": f"Added to the top scorers at rank {rank}.",
                **self._payload_unlocked(),
            }

    def _payload_unlocked(self) -> dict[str, Any]:
        return {
            "entries": [
                entry.to_payload(rank=index + 1) for index, entry in enumerate(self._entries)
            ],
            "size": LEADERBOARD_SIZE,
        }

    def _load(self) -> None:
        if not self._path.is_file():
            self._entries = []
            return
        raw = json.loads(self._path.read_text(encoding="utf-8"))
        items = raw.get("entries", [])
        if not isinstance(items, list):
            self._entries = []
            return
        loaded: list[LeaderboardEntry] = []
        for item in items:
            if not isinstance(item, dict):
                continue
            name = item.get("name")
            survival_seconds = item.get("survival_seconds")
            recorded_at = item.get("recorded_at", 0.0)
            if isinstance(name, str) and isinstance(survival_seconds, int):
                loaded.append(
                    LeaderboardEntry(
                        name=name,
                        survival_seconds=survival_seconds,
                        recorded_at=float(recorded_at),
                    )
                )
        loaded.sort(key=lambda entry: entry.survival_seconds, reverse=True)
        self._entries = loaded[:LEADERBOARD_SIZE]

    def _save_unlocked(self) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "entries": [asdict(entry) for entry in self._entries],
        }
        temp_path = self._path.with_suffix(".tmp")
        temp_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        temp_path.replace(self._path)


def default_scores_path() -> Path:
    env_path = __import__("os").environ.get("REEF_RESCUER_SCORES_FILE")
    if env_path:
        return Path(env_path)
    return Path.home() / ".reef-rescuer" / "leaderboard.json"
