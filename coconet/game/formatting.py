"""Display helpers shared by the desktop and web Reef Rescuer clients."""


def format_elapsed(seconds: int) -> str:
    minutes, secs = divmod(max(0, seconds), 60)
    return f"{minutes}:{secs:02d}"


def format_survival_display(survival_seconds: int, high_score_seconds: int) -> str:
    minute = survival_seconds // 60
    intensity = f" · Minute {minute}" if minute > 0 else ""
    return (
        f"Time {format_elapsed(survival_seconds)} · "
        f"Best {format_elapsed(high_score_seconds)}{intensity}"
    )
