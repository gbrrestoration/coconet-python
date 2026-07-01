"""Reef Rescuer mini-game, separate from the CoCoNet simulation model."""

from coconet.game.formatting import format_elapsed, format_survival_display

__all__ = ["ReefRescuerGame", "format_elapsed", "format_survival_display"]


def __getattr__(name: str):
    if name == "ReefRescuerGame":
        from coconet.game.ui import ReefRescuerGame

        return ReefRescuerGame
    msg = f"module {__name__!r} has no attribute {name!r}"
    raise AttributeError(msg)
