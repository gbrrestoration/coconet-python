"""Cooperative pause and stop signalling for long model runs."""

from __future__ import annotations

import threading


class RunStopped(Exception):
    """Raised when a run is cancelled via :class:`RunController`."""


class RunController:
    """Thread-safe pause/stop flags checked by the simulation loop."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._pause_cond = threading.Condition(self._lock)
        self._stopped = False
        self._paused = False

    def reset(self) -> None:
        with self._lock:
            self._stopped = False
            self._paused = False

    def stop(self) -> None:
        with self._lock:
            self._stopped = True
            self._paused = False
            self._pause_cond.notify_all()

    def pause(self) -> None:
        with self._lock:
            if not self._stopped:
                self._paused = True

    def resume(self) -> None:
        with self._lock:
            self._paused = False
            self._pause_cond.notify_all()

    def is_stopped(self) -> bool:
        with self._lock:
            return self._stopped

    def is_paused(self) -> bool:
        with self._lock:
            return self._paused

    def checkpoint(self) -> None:
        """Block while paused; raise :class:`RunStopped` if stop was requested."""
        with self._lock:
            while self._paused and not self._stopped:
                self._pause_cond.wait(timeout=0.25)
            if self._stopped:
                raise RunStopped()
