from __future__ import annotations

import threading
import time

import pytest

from coconet.run_control import RunController, RunStopped


def test_run_controller_stop_raises_at_checkpoint() -> None:
    control = RunController()
    control.stop()
    with pytest.raises(RunStopped):
        control.checkpoint()


def test_run_controller_pause_blocks_until_resume() -> None:
    control = RunController()
    control.pause()
    released = threading.Event()

    def waiter() -> None:
        control.checkpoint()
        released.set()

    thread = threading.Thread(target=waiter)
    thread.start()
    time.sleep(0.05)
    assert not released.is_set()
    control.resume()
    thread.join(timeout=1.0)
    assert released.is_set()


def test_run_controller_reset_clears_stop() -> None:
    control = RunController()
    control.stop()
    control.reset()
    control.checkpoint()
