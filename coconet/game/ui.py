"""Reef Rescuer window and controls for the desktop GUI."""

from __future__ import annotations

import random
import time
import tkinter as tk
from tkinter import ttk
from typing import ClassVar

from coconet.game.facts import REEF_FACTS
from coconet.game.formatting import format_elapsed, format_survival_display
from coconet.game.help_text import HOW_TO_PLAY_STEPS, HOW_TO_PLAY_TITLE
from coconet.game.sim import (
    INTERVENTION_COSTS,
    INTERVENTION_LABELS,
    InterventionKind,
    SimEvent,
    apply_intervention,
    format_meters,
    initial_reef_state,
    is_reef_collapsed,
    simulate_step,
)


class ReefRescuerGame:
    """Waiting room with reef facts and a lightweight threat/intervention simulator."""

    FACT_MS = 5000
    TIMER_MS = 1000
    SIM_MS = 4000
    WINDOW_WIDTH = 500
    WINDOW_HEIGHT = 820
    FACT_PANEL_HEIGHT = 84
    EVENT_PANEL_HEIGHT = 76
    CONTENT_WIDTH = 468

    COLORS: ClassVar[dict[str, str]] = {
        "bg": "#082f49",
        "panel": "#0c4a6e",
        "text": "#ecfeff",
        "muted": "#94a3b8",
        "coral": "#fb7185",
        "fish": "#34d399",
        "dhw": "#f97316",
        "cots": "#a855f7",
        "accent": "#38bdf8",
        "warn": "#fbbf24",
    }

    def __init__(self, parent: tk.Misc) -> None:
        self._parent = parent
        self._rng = random.Random()
        self._reef = initial_reef_state()
        self._window: tk.Toplevel | None = None
        self._elapsed_var = tk.StringVar(value="Time 0:00 · Best 0:00")
        self._fact_var = tk.StringVar(value=REEF_FACTS[0])
        self._meters_var = tk.StringVar(value=format_meters(self._reef))
        self._event_var = tk.StringVar(
            value="Press Start game when you are ready."
        )
        self._overlay_var = tk.StringVar(value="")
        self._fact_index = 0
        self._game_elapsed_seconds = 0
        self._game_segment_started_at: float | None = None
        self._high_score_seconds = 0
        self._active = False
        self._run_in_progress = False
        self._overlay_frame: tk.Frame | None = None
        self._content_frame: tk.Frame | None = None
        self._coral_bar: ttk.Progressbar | None = None
        self._fish_bar: ttk.Progressbar | None = None
        self._dhw_bar: ttk.Progressbar | None = None
        self._intervention_buttons: list[tk.Button] = []
        self._game_over = False
        self._gameover_frame: tk.Frame | None = None
        self._start_button: tk.Button | None = None
        self._restart_button: tk.Button | None = None
        self._quit_button: tk.Button | None = None
        self._awaiting_start = True
        self._cots_bar: ttk.Progressbar | None = None

    @property
    def score(self) -> int:
        return self._reef.score

    def on_run_started(self) -> None:
        """Reset simulator state when a model run begins (does not open the window)."""
        self._run_in_progress = True
        self._reef = initial_reef_state()
        self._fact_index = 0
        self._game_over = False
        self._high_score_seconds = 0
        self._awaiting_start = True
        self._reset_game_timer()
        if self._window is not None and self._window.winfo_exists():
            self._sync_ui()
            self._hide_overlay()
            self._hide_game_over()
            self._sync_play_controls()
            self._set_interventions_enabled(False)

    def open(self) -> None:
        """Open Reef Rescuer when the user clicks the launch button."""
        if not self._run_in_progress:
            return
        self._ensure_window()
        self._active = True
        self._hide_overlay()
        if self._game_over:
            self._hide_game_over()
            self._reef = initial_reef_state()
            self._game_over = False
            self._reset_game_timer()
            self._awaiting_start = True
        if self._awaiting_start:
            self._show_help_popup()
            self._sync_play_controls()
            self._sync_ui()
            return
        if self._game_segment_started_at is None:
            self._start_game_timer()
        self._sync_ui()
        self._schedule_updates()

    def notify_run_ended(self, message: str) -> None:
        self._run_in_progress = False
        self._active = False
        if not self._game_over:
            self._pause_game_timer()
            self._high_score_seconds = max(self._high_score_seconds, self._game_elapsed_seconds)
        if self._window is not None and self._window.winfo_exists():
            survival = self._game_elapsed_seconds
            self._overlay_var.set(
                f"{message}\n\n"
                f"Last survival: {format_elapsed(survival)}\n"
                f"Best survival: {format_elapsed(self._high_score_seconds)}\n"
                f"Final coral {self._reef.coral_cover:.0f}% · fish {self._reef.fish_biodiversity:.0f}%\n"
                f"Interventions used: {self._reef.interventions_used} · "
                f"Threats weathered: {self._reef.threats_weathered}"
            )
            self._show_overlay()

    def _ensure_window(self) -> None:
        if self._window is not None and self._window.winfo_exists():
            self._window.deiconify()
            self._window.lift()
            if (
                self._active
                and not self._awaiting_start
                and not self._game_over
                and self._game_segment_started_at is None
            ):
                self._start_game_timer()
            if self._awaiting_start:
                self._sync_play_controls()
            return

        window = tk.Toplevel(self._parent)
        window.title("Reef Lounge")
        window.resizable(False, False)
        window.geometry(f"{self.WINDOW_WIDTH}x{self.WINDOW_HEIGHT}")
        window.minsize(self.WINDOW_WIDTH, self.WINDOW_HEIGHT)
        window.maxsize(self.WINDOW_WIDTH, self.WINDOW_HEIGHT)
        window.configure(bg=self.COLORS["bg"])
        window.protocol("WM_DELETE_WINDOW", self._on_close)

        outer = tk.Frame(window, bg=self.COLORS["bg"], padx=16, pady=14)
        outer.pack()

        tk.Label(
            outer,
            text="Reef Lounge",
            bg=self.COLORS["bg"],
            fg=self.COLORS["text"],
            font=_font(16, bold=True),
        ).pack(anchor=tk.W)

        tk.Label(
            outer,
            text="Survive as long as you can — keep coral and fish alive",
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            font=_font(10),
        ).pack(anchor=tk.W, pady=(2, 4))

        tk.Label(
            outer,
            text="Threats intensify every minute. Beat your best survival time.",
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            font=_font(9),
        ).pack(anchor=tk.W, pady=(0, 12))

        self._content_frame = tk.Frame(outer, bg=self.COLORS["bg"])
        self._content_frame.pack(fill=tk.BOTH)

        tk.Label(
            self._content_frame,
            textvariable=self._elapsed_var,
            bg=self.COLORS["bg"],
            fg=self.COLORS["text"],
            font=("Consolas", 12),
        ).pack(anchor=tk.W, pady=(0, 8))

        controls = tk.Frame(self._content_frame, bg=self.COLORS["bg"])
        controls.pack(fill=tk.X, pady=(0, 12))
        self._start_button = _action_button(
            controls,
            text="Start game",
            command=self._begin_game,
            bg=self.COLORS["accent"],
            fg="#0f172a",
            activebackground="#7dd3fc",
        )
        self._start_button.pack(side=tk.LEFT, padx=(0, 8))
        self._restart_button = _action_button(
            controls,
            text="Restart game",
            command=self._restart_game,
            bg=self.COLORS["accent"],
            fg="#0f172a",
            activebackground="#7dd3fc",
        )
        self._restart_button.pack(side=tk.LEFT, padx=(0, 8))
        self._quit_button = _action_button(
            controls,
            text="Quit game",
            command=self._quit_game,
            bg=self.COLORS["panel"],
            fg=self.COLORS["text"],
            activebackground="#155e75",
        )
        self._quit_button.pack(side=tk.LEFT)

        tk.Button(
            controls,
            text="How to play",
            command=self._show_help_popup,
            bg=self.COLORS["bg"],
            fg=self.COLORS["accent"],
            activebackground=self.COLORS["bg"],
            activeforeground=self.COLORS["accent"],
            relief=tk.FLAT,
            padx=8,
            pady=8,
        ).pack(side=tk.LEFT, padx=(8, 0))

        fact_box = tk.Frame(
            self._content_frame,
            bg=self.COLORS["panel"],
            width=self.CONTENT_WIDTH,
            height=self.FACT_PANEL_HEIGHT,
        )
        fact_box.pack(fill=tk.X, pady=(0, 12))
        fact_box.pack_propagate(False)
        tk.Label(
            fact_box,
            textvariable=self._fact_var,
            bg=self.COLORS["panel"],
            fg=self.COLORS["text"],
            font=_font(11),
            padx=14,
            pady=14,
            wraplength=self.CONTENT_WIDTH - 28,
            justify=tk.LEFT,
            anchor=tk.NW,
        ).pack(fill=tk.BOTH, expand=True)

        sim = tk.LabelFrame(
            self._content_frame,
            text="Mini reef status",
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            padx=12,
            pady=10,
        )
        sim.pack(fill=tk.X, pady=(0, 10))

        self._coral_bar = _meter_row(sim, "Coral cover", self.COLORS["coral"])
        self._fish_bar = _meter_row(sim, "Fish biodiversity", self.COLORS["fish"])
        self._dhw_bar = _meter_row(sim, "Degree heating weeks", self.COLORS["dhw"], maximum=16)
        self._cots_bar = _meter_row(sim, "CoTS pressure", self.COLORS["cots"])

        tk.Label(
            sim,
            textvariable=self._meters_var,
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            font=_font(9),
            wraplength=self.CONTENT_WIDTH - 24,
            justify=tk.LEFT,
            anchor=tk.NW,
            height=2,
        ).pack(anchor=tk.W, pady=(8, 0), fill=tk.X)

        event_box = tk.Frame(
            self._content_frame,
            bg=self.COLORS["panel"],
            width=self.CONTENT_WIDTH,
            height=self.EVENT_PANEL_HEIGHT,
        )
        event_box.pack(fill=tk.X, pady=(0, 12))
        event_box.pack_propagate(False)
        tk.Label(
            event_box,
            textvariable=self._event_var,
            bg=self.COLORS["panel"],
            fg=self.COLORS["warn"],
            font=_font(10, bold=True),
            padx=12,
            pady=10,
            wraplength=self.CONTENT_WIDTH - 24,
            justify=tk.LEFT,
            anchor=tk.NW,
        ).pack(fill=tk.BOTH, expand=True)

        self._gameover_frame = tk.Frame(self._content_frame, bg=self.COLORS["bg"])
        tk.Label(
            self._gameover_frame,
            text="GAME OVER — coral and fish biodiversity lost",
            bg="#7f1d1d",
            fg="#fecaca",
            font=_font(11, bold=True),
            padx=12,
            pady=10,
            wraplength=self.CONTENT_WIDTH - 24,
        ).pack(fill=tk.X, pady=(0, 8))
        tk.Label(
            self._gameover_frame,
            text="The reef collapsed under stress. Restart to chase a longer survival time.",
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            font=_font(10),
            wraplength=self.CONTENT_WIDTH - 24,
            justify=tk.LEFT,
        ).pack(anchor=tk.W, pady=(0, 8))

        interventions = tk.LabelFrame(
            self._content_frame,
            text="Interventions (spend management points)",
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            padx=10,
            pady=10,
        )
        interventions.pack(fill=tk.X)

        grid = tk.Frame(interventions, bg=self.COLORS["bg"])
        grid.pack(fill=tk.X)

        kinds: tuple[InterventionKind, ...] = tuple(INTERVENTION_LABELS)
        for index, kind in enumerate(kinds):
            row, col = divmod(index, 2)
            cost = INTERVENTION_COSTS[kind]
            label = f"{INTERVENTION_LABELS[kind]} ({cost} pt)"
            btn = tk.Button(
                grid,
                text=label,
                command=lambda k=kind: self._use_intervention(k),
                bg=self.COLORS["panel"],
                fg=self.COLORS["text"],
                activebackground="#155e75",
                relief=tk.FLAT,
                padx=8,
                pady=6,
                wraplength=210,
                justify=tk.CENTER,
            )
            btn.grid(row=row, column=col, sticky=tk.EW, padx=4, pady=4)
            self._intervention_buttons.append(btn)
        grid.columnconfigure(0, weight=1)
        grid.columnconfigure(1, weight=1)

        tk.Label(
            outer,
            text="Quit closes the lounge · reopen with Reef Lounge while the run is active",
            bg=self.COLORS["bg"],
            fg=self.COLORS["muted"],
            font=_font(9),
        ).pack(anchor=tk.W, pady=(12, 0))

        self._overlay_frame = tk.Frame(outer, bg=self.COLORS["bg"])
        tk.Label(
            self._overlay_frame,
            text="CoCoNet run finished",
            bg=self.COLORS["bg"],
            fg=self.COLORS["accent"],
            font=_font(14, bold=True),
        ).pack(pady=(8, 6))
        tk.Label(
            self._overlay_frame,
            textvariable=self._overlay_var,
            bg=self.COLORS["panel"],
            fg=self.COLORS["text"],
            font=_font(11),
            padx=14,
            pady=14,
            wraplength=460,
            justify=tk.CENTER,
        ).pack(fill=tk.X)

        self._window = window
        self._sync_play_controls()
        if self._awaiting_start:
            self._show_help_popup()
        window.update_idletasks()
        window.geometry(f"{self.WINDOW_WIDTH}x{self.WINDOW_HEIGHT}")

    def _use_intervention(self, kind: InterventionKind) -> None:
        if not self._run_in_progress or self._game_over or self._awaiting_start:
            return
        self._reef, event = apply_intervention(self._reef, kind)
        self._show_event(event)
        self._sync_ui()
        self._check_game_over()

    def _simulate(self) -> None:
        if not self._run_in_progress or self._game_over:
            return
        elapsed = self._survival_seconds()
        self._reef, events = simulate_step(self._reef, rng=self._rng, elapsed_seconds=elapsed)
        if events:
            self._show_event(events[-1])
        self._sync_ui()
        self._check_game_over()

    def _check_game_over(self) -> None:
        if is_reef_collapsed(self._reef):
            self._set_game_over()

    def _set_game_over(self) -> None:
        if self._game_over:
            return
        self._game_over = True
        before_best = self._high_score_seconds
        survival = self._finalize_survival_time()
        new_record = survival > before_best
        record_note = " New best survival!" if new_record else ""
        self._event_var.set(
            f"Reef collapsed after {format_elapsed(survival)}.{record_note} "
            f"Best: {format_elapsed(self._high_score_seconds)}."
        )
        self._set_interventions_enabled(False)
        self._sync_play_controls()
        self._show_game_over()
        self._update_elapsed()

    def _show_game_over(self) -> None:
        if self._gameover_frame is None:
            return
        self._gameover_frame.pack(fill=tk.X, pady=(0, 12))

    def _hide_game_over(self) -> None:
        if self._gameover_frame is not None:
            self._gameover_frame.pack_forget()

    def _restart_game(self) -> None:
        if not self._run_in_progress:
            return
        self._awaiting_start = False
        self._record_current_survival()
        self._reef = initial_reef_state()
        self._game_over = False
        self._reset_game_timer()
        self._start_game_timer()
        self._event_var.set("New round — survive longer than your best time.")
        self._hide_game_over()
        self._sync_play_controls()
        self._set_interventions_enabled(True)
        self._sync_ui()
        if self._active:
            self._schedule_updates()

    def _quit_game(self) -> None:
        self._record_current_survival()
        self._active = False
        self._awaiting_start = True
        if self._window is not None and self._window.winfo_exists():
            self._window.withdraw()

    def _begin_game(self) -> None:
        if not self._run_in_progress or self._game_over or not self._awaiting_start:
            return
        self._awaiting_start = False
        self._start_game_timer()
        self._sync_play_controls()
        self._set_interventions_enabled(True)
        self._event_var.set("Survive as long as you can — threats intensify every minute.")
        self._sync_ui()
        if self._active:
            self._schedule_updates()

    def _sync_play_controls(self) -> None:
        if self._start_button is not None:
            start_state = tk.NORMAL if self._awaiting_start and not self._game_over else tk.DISABLED
            self._start_button.configure(state=start_state)
        if self._restart_button is not None:
            restart_state = tk.NORMAL if not self._awaiting_start and self._run_in_progress else tk.DISABLED
            self._restart_button.configure(state=restart_state)
        if self._quit_button is not None:
            quit_state = tk.NORMAL if not self._awaiting_start and self._run_in_progress else tk.DISABLED
            self._quit_button.configure(state=quit_state)

    def _show_help_popup(self) -> None:
        if self._window is None or not self._window.winfo_exists():
            return
        popup = tk.Toplevel(self._window)
        popup.title(HOW_TO_PLAY_TITLE)
        popup.resizable(False, False)
        popup.configure(bg=self.COLORS["panel"])
        popup.transient(self._window)
        popup.grab_set()

        body = tk.Frame(popup, bg=self.COLORS["panel"], padx=16, pady=14)
        body.pack()
        tk.Label(
            body,
            text=HOW_TO_PLAY_TITLE,
            bg=self.COLORS["panel"],
            fg=self.COLORS["text"],
            font=_font(12, bold=True),
        ).pack(anchor=tk.W, pady=(0, 8))
        for step in HOW_TO_PLAY_STEPS:
            tk.Label(
                body,
                text=f"• {step}",
                bg=self.COLORS["panel"],
                fg=self.COLORS["text"],
                font=_font(10),
                wraplength=420,
                justify=tk.LEFT,
                anchor=tk.NW,
            ).pack(anchor=tk.W, pady=2)
        _action_button(
            body,
            text="OK",
            command=popup.destroy,
            bg=self.COLORS["accent"],
            fg="#0f172a",
            activebackground="#7dd3fc",
        ).pack(anchor=tk.E, pady=(12, 0))

        popup.update_idletasks()
        popup.geometry(f"460x{popup.winfo_reqheight() + 10}")

    def _record_current_survival(self) -> None:
        if self._game_over:
            return
        self._pause_game_timer()
        self._high_score_seconds = max(self._high_score_seconds, self._game_elapsed_seconds)

    def _reset_game_timer(self) -> None:
        self._game_elapsed_seconds = 0
        self._game_segment_started_at = None

    def _start_game_timer(self) -> None:
        if self._game_over:
            return
        self._game_segment_started_at = time.monotonic()

    def _pause_game_timer(self) -> None:
        if self._game_segment_started_at is None:
            return
        self._game_elapsed_seconds += int(time.monotonic() - self._game_segment_started_at)
        self._game_segment_started_at = None

    def _survival_seconds(self) -> int:
        extra = 0
        if self._game_segment_started_at is not None:
            extra = int(time.monotonic() - self._game_segment_started_at)
        return self._game_elapsed_seconds + extra

    def _finalize_survival_time(self) -> int:
        self._pause_game_timer()
        survival = self._game_elapsed_seconds
        if survival > self._high_score_seconds:
            self._high_score_seconds = survival
        return survival

    def _set_interventions_enabled(self, enabled: bool) -> None:
        state = tk.NORMAL if enabled else tk.DISABLED
        for button in self._intervention_buttons:
            button.configure(state=state)

    def _show_event(self, event: SimEvent) -> None:
        self._event_var.set(event.message)

    def _sync_ui(self) -> None:
        self._meters_var.set(format_meters(self._reef))
        if self._coral_bar is not None:
            self._coral_bar["value"] = self._reef.coral_cover
        if self._fish_bar is not None:
            self._fish_bar["value"] = self._reef.fish_biodiversity
        if self._dhw_bar is not None:
            self._dhw_bar["value"] = min(16.0, self._reef.dhw)
        if self._cots_bar is not None:
            self._cots_bar["value"] = self._reef.cots_pressure
        self._update_elapsed()

    def _update_elapsed(self) -> None:
        survival = self._survival_seconds()
        self._elapsed_var.set(format_survival_display(survival, self._high_score_seconds))

    def _rotate_fact(self) -> None:
        self._fact_index = (self._fact_index + 1) % len(REEF_FACTS)
        self._fact_var.set(REEF_FACTS[self._fact_index])

    def _schedule_updates(self) -> None:
        if not self._active or self._window is None or not self._window.winfo_exists():
            return
        self._window.after(self.TIMER_MS, self._on_timer)
        self._window.after(self.FACT_MS, self._on_fact)
        self._window.after(self.SIM_MS, self._on_sim)

    def _on_timer(self) -> None:
        if not self._active:
            return
        self._update_elapsed()
        if self._window is not None and self._window.winfo_exists():
            self._window.after(self.TIMER_MS, self._on_timer)

    def _on_fact(self) -> None:
        if not self._active:
            return
        self._rotate_fact()
        if self._window is not None and self._window.winfo_exists():
            self._window.after(self.FACT_MS, self._on_fact)

    def _on_sim(self) -> None:
        if not self._active or not self._run_in_progress or self._game_over or self._awaiting_start:
            return
        self._simulate()
        if self._window is not None and self._window.winfo_exists():
            self._window.after(self.SIM_MS, self._on_sim)

    def _show_overlay(self) -> None:
        if self._overlay_frame is not None:
            self._overlay_frame.pack(fill=tk.X, pady=(12, 0))
        if self._content_frame is not None:
            self._content_frame.pack_forget()

    def _hide_overlay(self) -> None:
        if self._overlay_frame is not None:
            self._overlay_frame.pack_forget()
        if self._content_frame is not None:
            self._content_frame.pack(fill=tk.BOTH)

    def _on_close(self) -> None:
        self._quit_game()


def _action_button(
    parent: tk.Misc,
    *,
    text: str,
    command: object,
    bg: str,
    fg: str,
    activebackground: str,
) -> tk.Button:
    return tk.Button(
        parent,
        text=text,
        command=command,
        bg=bg,
        fg=fg,
        activebackground=activebackground,
        relief=tk.FLAT,
        padx=12,
        pady=8,
    )


def _meter_row(
    parent: tk.Misc,
    label: str,
    color: str,
    *,
    maximum: float = 100,
) -> ttk.Progressbar:
    row = tk.Frame(parent, bg=parent.cget("bg"))
    row.pack(fill=tk.X, pady=3)
    tk.Label(row, text=label, bg=parent.cget("bg"), fg=color, width=20, anchor=tk.W).pack(side=tk.LEFT)
    bar = ttk.Progressbar(row, maximum=maximum, length=280)
    bar.pack(side=tk.LEFT, fill=tk.X, expand=True)
    return bar


def _font(size: int, *, bold: bool = False) -> tuple[str, int, str] | tuple[str, int]:
    family = "Segoe UI" if _sys_platform() == "win32" else "Helvetica"
    if bold:
        return (family, size, "bold")
    return (family, size)


def _sys_platform() -> str:
    import sys

    return sys.platform
