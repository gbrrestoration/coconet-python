from __future__ import annotations

import logging

VALID_LOG_LEVELS = ("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG")


def normalize_log_level(level: str | None) -> str:
    if level is None:
        return "INFO"
    normalized = level.strip().upper()
    if normalized not in VALID_LOG_LEVELS:
        valid_levels = ", ".join(VALID_LOG_LEVELS)
        raise ValueError(f"Invalid log level '{level}'. Valid levels: {valid_levels}.")
    return normalized


def configure_logging(level: str | None) -> str:
    normalized_level = normalize_log_level(level)
    logging.basicConfig(
        level=getattr(logging, normalized_level),
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        force=True,
    )
    return normalized_level
