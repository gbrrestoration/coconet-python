from __future__ import annotations

import argparse
import contextlib
import io
import logging
import os
from pathlib import Path
from typing import TYPE_CHECKING, Any

from coconet.api import load_coconet_config, run_coconet
from coconet.logging_utils import configure_logging

if TYPE_CHECKING:
    from pyinstrument import Profiler


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run headless CoCoNet model.")
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Optional YAML config file with scenario parameters.",
    )
    parser.add_argument(
        "--parameter-file",
        type=Path,
        default=None,
        help="Legacy NetLogo-style parameter CSV file.",
    )
    parser.add_argument(
        "--output-file",
        type=Path,
        default=None,
        help="Output CSV file path.",
    )
    parser.add_argument(
        "--reefs-file",
        type=Path,
        default=None,
        help="Reef attribute / spatial input CSV. Overrides config and COCONET_REEFS_FILE.",
    )
    parser.add_argument(
        "--coastline-file",
        type=Path,
        default=None,
        help="Coastline input CSV. Overrides config and COCONET_COASTLINE_FILE.",
    )
    parser.add_argument(
        "--log-level",
        type=str,
        default=None,
        help="Logging level (CRITICAL, ERROR, WARNING, INFO, DEBUG).",
    )
    parser.add_argument(
        "--ensemble-threads",
        type=int,
        default=None,
        metavar="N",
        help="After ensemble-0 spinup, run simulation ensembles in parallel worker "
        "processes (spawn): 1 = serial on the main process; 0 = auto "
        "(min(CPU count, ensemble count)); N > 1 caps workers. "
        "Default from config / COCONET_ENSEMBLE_THREADS.",
    )
    prof = parser.add_argument_group(
        "profiling",
        "Optional CPU profiling via pyinstrument (install: uv sync --extra profile).",
    )
    prof.add_argument(
        "--profile",
        action="store_true",
        help="Profile the model run and write a dump to --profile-output.",
    )
    prof.add_argument(
        "--profile-format",
        choices=("html", "text", "speedscope"),
        default="html",
        help="Dump format: html (self-contained viewer), text (call tree), "
        "or speedscope (open at https://www.speedscope.app/). Default: html.",
    )
    prof.add_argument(
        "--profile-output",
        type=Path,
        default=None,
        help="Output file path. Default: coconet-profile.<html|txt|speedscope.json>.",
    )
    prof.add_argument(
        "--profile-interval",
        type=float,
        default=0.01,
        metavar="SECONDS",
        help="Seconds between CPU stack samples (pyinstrument default upstream is 0.001). "
        "Coarser sampling (e.g. 0.01) keeps sessions smaller so the HTML report often "
        "avoids heavy resampling. Use 0.001 for maximum detail.",
    )
    prof.add_argument(
        "--profile-html-resample-interval",
        type=float,
        default=None,
        metavar="SECONDS",
        help="When using HTML output, optional resample_interval for pyinstrument's "
        "HTMLRenderer (minimum time between retained samples in the viewer).",
    )
    return parser


def _default_profile_path(fmt: str) -> Path:
    if fmt == "html":
        return Path("coconet-profile.html")
    if fmt == "text":
        return Path("coconet-profile.txt")
    return Path("coconet-profile.speedscope.json")


def _write_profile_dump(
    profiler: Profiler,
    path: Path,
    fmt: str,
    *,
    html_resample_interval: float | None,
    logger: logging.Logger,
) -> None:
    if fmt == "html":
        session = profiler.last_session
        n_samples = len(session.frame_records) if session is not None else 0
        if n_samples > 100_000:
            logger.info(
                "Profile HTML: session has %s stack samples; the interactive viewer "
                "uses resampled data (pyinstrument limit ~100k). "
                "Use a larger --profile-interval and/or --profile-format speedscope "
                "for long runs.",
                n_samples,
            )
        # pyinstrument always prints a noisy resample notice to stderr when
        # resampling; we already log above and pass resample_interval when set.
        stderr_buf = io.StringIO()
        with contextlib.redirect_stderr(stderr_buf):
            content = profiler.output_html(resample_interval=html_resample_interval)
        extra = stderr_buf.getvalue().strip()
        if extra:
            logger.debug("%s", extra)
    elif fmt == "text":
        content = profiler.output_text(unicode=True, color=False)
    else:
        from pyinstrument.renderers import SpeedscopeRenderer

        content = profiler.output(SpeedscopeRenderer())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    bootstrap_level = args.log_level or os.getenv("COCONET_LOG_LEVEL") or "INFO"
    try:
        configure_logging(bootstrap_level)
    except ValueError as exc:
        parser.error(str(exc))
        return

    logger = logging.getLogger(__name__)
    logger.debug(
        "Loading configuration (config_file=%s, parameter_file=%s).",
        args.config,
        args.parameter_file,
    )

    cli_overrides: dict[str, Any] = {}
    if args.output_file is not None:
        cli_overrides["output_file"] = str(args.output_file)
    if args.reefs_file is not None:
        cli_overrides["reefs_file"] = str(args.reefs_file)
    if args.coastline_file is not None:
        cli_overrides["coastline_file"] = str(args.coastline_file)
    if args.log_level is not None:
        cli_overrides["log_level"] = args.log_level
    if args.ensemble_threads is not None:
        cli_overrides["ensemble_threads"] = args.ensemble_threads

    config = load_coconet_config(
        config_file=args.config,
        parameter_file=args.parameter_file,
        **cli_overrides,
    )

    try:
        effective_log_level = configure_logging(config.log_level)
    except ValueError as exc:
        parser.error(str(exc))
        return

    logger = logging.getLogger(__name__)
    logger.info(
        "Starting CoCoNet run: log_level=%s reefs_file=%s coastline_file=%s "
        "output_file=%s config_file=%s parameter_file=%s",
        effective_log_level,
        config.reefs_file,
        config.coastline_file,
        config.output_file,
        args.config,
        args.parameter_file,
    )

    if args.profile:
        try:
            from pyinstrument import Profiler
        except ImportError:
            parser.error(
                "Profiling needs pyinstrument. Install the optional extra, e.g. "
                "`uv sync --extra profile` or `pip install 'coconet-python[profile]'`."
            )
        if args.profile_interval <= 0:
            parser.error("--profile-interval must be positive.")
        if (
            args.profile_html_resample_interval is not None
            and args.profile_html_resample_interval < 0
        ):
            parser.error(
                "--profile-html-resample-interval must be non-negative "
                "(0 disables HTML resampling)."
            )
        out = args.profile_output or _default_profile_path(args.profile_format)
        profiler = Profiler(interval=args.profile_interval)
        profiler.start()
        try:
            run_coconet(config, configure_logs=False)
        finally:
            profiler.stop()
            _write_profile_dump(
                profiler,
                out,
                args.profile_format,
                html_resample_interval=args.profile_html_resample_interval,
                logger=logger,
            )
        logger.info(
            "Wrote %s profile to %s",
            args.profile_format,
            out.resolve(),
        )
    else:
        run_coconet(config, configure_logs=False)

    logger.info("CoCoNet run finished successfully.")


if __name__ == "__main__":
    main()
