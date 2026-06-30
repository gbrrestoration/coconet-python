"""Desktop GUI for running CoCoNet on Windows and macOS."""

from __future__ import annotations

import logging
import multiprocessing
import queue
import sys
import threading
import tkinter as tk
from contextlib import suppress
from pathlib import Path
from tkinter import filedialog, messagebox, scrolledtext, ttk
from typing import Any, Literal

from coconet.api import load_coconet_config, run_coconet
from coconet.app_paths import bundled_path
from coconet.game import ReefRescuerGame
from coconet.gui_config import ConfigEditorPanel
from coconet.logging_utils import configure_logging
from coconet.run_control import RunController, RunStopped
from coconet.viz_viewer import launch_chart_viewer

LOG_LEVELS = ("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG")
ConfigMode = Literal["file", "interactive"]


class QueueLogHandler(logging.Handler):
    """Forward log records to a thread-safe queue consumed on the Tk main loop."""

    def __init__(self, record_queue: queue.Queue[str]) -> None:
        super().__init__()
        self._record_queue = record_queue

    def emit(self, record: logging.LogRecord) -> None:
        try:
            message = self.format(record)
        except Exception:
            self.handleError(record)
            return
        self._record_queue.put(message)


class CoconetGuiApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("CoCoNet")
        self.root.minsize(920, 780)

        self._log_queue: queue.Queue[str] = queue.Queue()
        self._run_thread: threading.Thread | None = None
        self._last_output_file: Path | None = None
        self._run_control = RunController()
        self._reef_game = ReefRescuerGame(self.root)

        self.config_mode = tk.StringVar(value="file")
        self.config_path = tk.StringVar()
        self.parameter_path = tk.StringVar()
        self.reefs_path = tk.StringVar()
        self.coastline_path = tk.StringVar(value=str(self._default_coastline()))
        self.output_path = tk.StringVar(value=str(Path.cwd() / "output.csv"))
        self.log_level = tk.StringVar(value="INFO")
        self.ensemble_threads = tk.StringVar(value="0")

        self._build_ui()
        self._seed_defaults()
        self._poll_log_queue()

    def _default_coastline(self) -> Path:
        candidate = bundled_path("legacy", "coastline.csv")
        return candidate if candidate.is_file() else Path("legacy/coastline.csv")

    def _default_config(self) -> Path | None:
        candidate = bundled_path("config", "example.yaml")
        return candidate if candidate.is_file() else None

    def _seed_defaults(self) -> None:
        default_config = self._default_config()
        if default_config is not None:
            self.config_path.set(str(default_config))
            with suppress(Exception):
                self.config_editor.load_from_path(default_config)

    def _build_ui(self) -> None:
        outer = ttk.Frame(self.root, padding=12)
        outer.pack(fill=tk.BOTH, expand=True)
        outer.rowconfigure(2, weight=1)
        outer.columnconfigure(0, weight=1)

        files = ttk.LabelFrame(outer, text="Input / output files", padding=10)
        files.grid(row=0, column=0, sticky=tk.EW, pady=(0, 10))
        files.columnconfigure(1, weight=1)

        self._add_path_row(
            files,
            0,
            "Parameter CSV",
            self.parameter_path,
            [("CSV", "*.csv"), ("All files", "*.*")],
        )
        self._add_path_row(
            files,
            1,
            "Reefs CSV",
            self.reefs_path,
            [("CSV", "*.csv"), ("All files", "*.*")],
            required=True,
        )
        self._add_path_row(
            files,
            2,
            "Coastline CSV",
            self.coastline_path,
            [("CSV", "*.csv"), ("All files", "*.*")],
            required=True,
        )
        self._add_path_row(
            files,
            3,
            "Output CSV",
            self.output_path,
            [("CSV", "*.csv"), ("All files", "*.*")],
            save=True,
            required=True,
        )

        scenario = ttk.LabelFrame(outer, text="Scenario configuration", padding=10)
        scenario.grid(row=1, column=0, sticky=tk.NSEW, pady=(0, 10))
        scenario.rowconfigure(2, weight=1)
        scenario.columnconfigure(0, weight=1)

        mode_row = ttk.Frame(scenario)
        mode_row.grid(row=0, column=0, sticky=tk.W, pady=(0, 8))
        ttk.Radiobutton(
            mode_row,
            text="Use YAML file",
            variable=self.config_mode,
            value="file",
            command=self._on_config_mode_changed,
        ).pack(side=tk.LEFT)
        ttk.Radiobutton(
            mode_row,
            text="Edit interactively",
            variable=self.config_mode,
            value="interactive",
            command=self._on_config_mode_changed,
        ).pack(side=tk.LEFT, padx=(16, 0))

        self.file_config_frame = ttk.Frame(scenario)
        self.file_config_frame.grid(row=1, column=0, sticky=tk.EW, pady=(0, 8))
        self.file_config_frame.columnconfigure(1, weight=1)
        ttk.Label(self.file_config_frame, text="YAML config").grid(row=0, column=0, sticky=tk.W)
        ttk.Entry(self.file_config_frame, textvariable=self.config_path).grid(
            row=0,
            column=1,
            sticky=tk.EW,
            padx=(8, 8),
        )
        ttk.Button(
            self.file_config_frame,
            text="Browse…",
            command=lambda: self._browse(
                self.config_path,
                [("YAML", "*.yaml *.yml"), ("All files", "*.*")],
            ),
        ).grid(row=0, column=2, sticky=tk.E)
        ttk.Button(
            self.file_config_frame,
            text="Load into editor",
            command=self._load_config_file_into_editor,
        ).grid(row=0, column=3, sticky=tk.E, padx=(8, 0))

        self.interactive_config_frame = ttk.Frame(scenario)
        self.interactive_config_frame.grid(row=2, column=0, sticky=tk.NSEW)
        self.interactive_config_frame.rowconfigure(0, weight=1)
        self.interactive_config_frame.columnconfigure(0, weight=1)
        self.config_editor = ConfigEditorPanel(self.interactive_config_frame)
        self.config_editor.grid(row=0, column=0, sticky=tk.NSEW)

        bottom = ttk.Frame(outer)
        bottom.grid(row=2, column=0, sticky=tk.NSEW)
        bottom.rowconfigure(2, weight=1)
        bottom.columnconfigure(0, weight=1)

        options = ttk.LabelFrame(bottom, text="Run options", padding=10)
        options.grid(row=0, column=0, sticky=tk.EW, pady=(0, 10))

        ttk.Label(options, text="Log level").grid(row=0, column=0, sticky=tk.W, padx=(0, 8))
        log_combo = ttk.Combobox(
            options,
            textvariable=self.log_level,
            values=LOG_LEVELS,
            state="readonly",
            width=12,
        )
        log_combo.grid(row=0, column=1, sticky=tk.W)

        ttk.Label(options, text="Ensemble threads").grid(row=0, column=2, sticky=tk.W, padx=(24, 8))
        threads_spin = ttk.Spinbox(
            options,
            from_=0,
            to=64,
            textvariable=self.ensemble_threads,
            width=6,
        )
        threads_spin.grid(row=0, column=3, sticky=tk.W)
        ttk.Label(options, text="(0 = auto, 1 = serial)").grid(row=0, column=4, sticky=tk.W, padx=(8, 0))

        actions = ttk.Frame(bottom)
        actions.grid(row=1, column=0, sticky=tk.EW, pady=(0, 10))

        self.run_button = ttk.Button(actions, text="Run", command=self._on_run)
        self.run_button.pack(side=tk.LEFT)

        self.pause_button = ttk.Button(
            actions,
            text="Pause",
            command=self._on_pause,
            state=tk.DISABLED,
        )
        self.pause_button.pack(side=tk.LEFT, padx=(8, 0))

        self.stop_button = ttk.Button(
            actions,
            text="Stop",
            command=self._on_stop,
            state=tk.DISABLED,
        )
        self.stop_button.pack(side=tk.LEFT, padx=(8, 0))

        self.open_button = ttk.Button(
            actions,
            text="Open output folder",
            command=self._on_open_output_folder,
            state=tk.DISABLED,
        )
        self.open_button.pack(side=tk.LEFT, padx=(8, 0))

        self.charts_button = ttk.Button(
            actions,
            text="View charts",
            command=self._on_view_charts,
            state=tk.DISABLED,
        )
        self.charts_button.pack(side=tk.LEFT, padx=(8, 0))

        self.game_button = ttk.Button(
            actions,
            text="Reef Lounge",
            command=self._on_open_reef_game,
            state=tk.DISABLED,
        )
        self.game_button.pack(side=tk.LEFT, padx=(8, 0))

        self.progress = ttk.Progressbar(actions, mode="indeterminate", length=180)
        self.progress.pack(side=tk.RIGHT)

        log_frame = ttk.LabelFrame(bottom, text="Log", padding=10)
        log_frame.grid(row=2, column=0, sticky=tk.NSEW)
        log_frame.rowconfigure(0, weight=1)
        log_frame.columnconfigure(0, weight=1)

        self.log_text = scrolledtext.ScrolledText(
            log_frame,
            height=10,
            wrap=tk.WORD,
            state=tk.DISABLED,
            font=("Consolas", 10) if sys.platform == "win32" else ("Menlo", 11),
        )
        self.log_text.grid(row=0, column=0, sticky=tk.NSEW)

        self._on_config_mode_changed()

    def _on_config_mode_changed(self) -> None:
        if self.config_mode.get() == "file":
            self.file_config_frame.grid()
            self.interactive_config_frame.grid_remove()
        else:
            self.file_config_frame.grid_remove()
            self.interactive_config_frame.grid()

    def _load_config_file_into_editor(self) -> None:
        path_text = self.config_path.get().strip()
        if not path_text:
            messagebox.showerror("Missing file", "Choose a YAML config file first.")
            return
        path = Path(path_text)
        if not path.is_file():
            messagebox.showerror("Invalid input", f"Config file not found:\n{path}")
            return
        try:
            self.config_editor.load_from_path(path)
        except Exception as exc:
            messagebox.showerror("Load failed", str(exc))
            return
        self.config_mode.set("interactive")
        self._on_config_mode_changed()

    def _add_path_row(
        self,
        parent: ttk.LabelFrame,
        row: int,
        label: str,
        variable: tk.StringVar,
        filetypes: list[tuple[str, str]],
        *,
        save: bool = False,
        required: bool = False,
    ) -> None:
        suffix = " *" if required else ""
        ttk.Label(parent, text=f"{label}{suffix}").grid(row=row, column=0, sticky=tk.W, pady=4)
        entry = ttk.Entry(parent, textvariable=variable)
        entry.grid(row=row, column=1, sticky=tk.EW, padx=(8, 8), pady=4)
        ttk.Button(
            parent,
            text="Browse…",
            command=lambda: self._browse(variable, filetypes, save=save),
        ).grid(row=row, column=2, sticky=tk.E, pady=4)
        parent.columnconfigure(1, weight=1)

    def _browse(
        self,
        variable: tk.StringVar,
        filetypes: list[tuple[str, str]],
        *,
        save: bool = False,
    ) -> None:
        if save:
            path = filedialog.asksaveasfilename(
                title="Choose output file",
                defaultextension=".csv",
                filetypes=filetypes,
            )
        else:
            path = filedialog.askopenfilename(title="Choose file", filetypes=filetypes)
        if path:
            variable.set(path)

    def _append_log(self, message: str) -> None:
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, message + "\n")
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    def _poll_log_queue(self) -> None:
        while True:
            try:
                message = self._log_queue.get_nowait()
            except queue.Empty:
                break
            self._append_log(message)
        self.root.after(120, self._poll_log_queue)

    def _set_running(self, running: bool) -> None:
        self.run_button.configure(state=tk.DISABLED if running else tk.NORMAL)
        self.pause_button.configure(state=tk.NORMAL if running else tk.DISABLED)
        self.stop_button.configure(state=tk.NORMAL if running else tk.DISABLED)
        if running:
            self.open_button.configure(state=tk.DISABLED)
            self.charts_button.configure(state=tk.DISABLED)
            self.game_button.configure(state=tk.NORMAL)
            self.progress.start(12)
        else:
            self.pause_button.configure(text="Pause")
            self.game_button.configure(state=tk.DISABLED)
            self.progress.stop()

    def _validate_inputs(self) -> dict[str, Any] | None:
        reefs = self.reefs_path.get().strip()
        coastline = self.coastline_path.get().strip()
        output = self.output_path.get().strip()

        if not reefs:
            messagebox.showerror("Missing input", "Please choose a reefs CSV file.")
            return None
        if not Path(reefs).is_file():
            messagebox.showerror("Invalid input", f"Reefs file not found:\n{reefs}")
            return None
        if not coastline:
            messagebox.showerror("Missing input", "Please choose a coastline CSV file.")
            return None
        if not Path(coastline).is_file():
            messagebox.showerror("Invalid input", f"Coastline file not found:\n{coastline}")
            return None
        if not output:
            messagebox.showerror("Missing input", "Please choose an output CSV path.")
            return None

        output_parent = Path(output).expanduser().resolve().parent
        try:
            output_parent.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            messagebox.showerror("Invalid output", f"Cannot create output directory:\n{exc}")
            return None

        try:
            threads = int(self.ensemble_threads.get().strip())
        except ValueError:
            messagebox.showerror("Invalid option", "Ensemble threads must be an integer.")
            return None
        if threads < 0:
            messagebox.showerror("Invalid option", "Ensemble threads must be 0 or greater.")
            return None

        parameter = self.parameter_path.get().strip() or None
        if parameter is not None and not Path(parameter).is_file():
            messagebox.showerror("Invalid input", f"Parameter file not found:\n{parameter}")
            return None

        mode = self.config_mode.get()
        config_file: str | None = None
        scenario: dict[str, Any] | None = None

        if mode == "file":
            config = self.config_path.get().strip() or None
            if config is not None and not Path(config).is_file():
                messagebox.showerror("Invalid input", f"Config file not found:\n{config}")
                return None
            config_file = config
        else:
            try:
                scenario = self.config_editor.build_scenario()
            except ValueError as exc:
                messagebox.showerror("Invalid scenario configuration", str(exc))
                return None

        return {
            "config_mode": mode,
            "config_file": config_file,
            "scenario": scenario,
            "parameter_file": parameter,
            "reefs_file": reefs,
            "coastline_file": coastline,
            "output_file": output,
            "log_level": self.log_level.get(),
            "ensemble_threads": threads,
        }

    def _on_run(self) -> None:
        if self._run_thread is not None and self._run_thread.is_alive():
            return

        values = self._validate_inputs()
        if values is None:
            return

        self.log_text.configure(state=tk.NORMAL)
        self.log_text.delete("1.0", tk.END)
        self.log_text.configure(state=tk.DISABLED)
        self._run_control.reset()
        self.pause_button.configure(text="Pause")
        self._set_running(True)
        self._reef_game.on_run_started()

        self._run_thread = threading.Thread(
            target=self._run_model,
            args=(values,),
            daemon=True,
        )
        self._run_thread.start()

    def _run_model(self, values: dict[str, Any]) -> None:
        root_logger = logging.getLogger()
        handler: QueueLogHandler | None = None
        try:
            configure_logging(values["log_level"])
            handler = QueueLogHandler(self._log_queue)
            handler.setFormatter(
                logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s", "%H:%M:%S")
            )
            root_logger.addHandler(handler)

            load_kwargs: dict[str, Any] = {
                "parameter_file": values["parameter_file"],
                "reefs_file": values["reefs_file"],
                "coastline_file": values["coastline_file"],
                "output_file": values["output_file"],
                "log_level": values["log_level"],
                "ensemble_threads": values["ensemble_threads"],
            }
            if values["config_mode"] == "interactive":
                load_kwargs["scenario"] = values["scenario"]
            else:
                load_kwargs["config_file"] = values["config_file"]

            config = load_coconet_config(**load_kwargs)
            result = run_coconet(config, configure_logs=False, run_control=self._run_control)
            self._last_output_file = Path(result.output_file).resolve()
            self.root.after(0, lambda: self._on_run_success(str(self._last_output_file)))
        except RunStopped:
            self._log_queue.put("Run stopped by user.")
            self.root.after(0, self._on_run_stopped)
        except Exception as exc:
            message = str(exc)
            self._log_queue.put(f"ERROR: {message}")
            self.root.after(0, lambda m=message: self._on_run_failure(m))
        finally:
            if handler is not None:
                root_logger.removeHandler(handler)

    def _on_open_reef_game(self) -> None:
        self._reef_game.open()

    def _finish_run_ui(self, game_message: str) -> None:
        self._set_running(False)
        self._reef_game.notify_run_ended(game_message)

    def _on_pause(self) -> None:
        if self._run_control.is_paused():
            self._run_control.resume()
            self.pause_button.configure(text="Pause")
            self._log_queue.put("Run resumed.")
        else:
            self._run_control.pause()
            self.pause_button.configure(text="Resume")
            self._log_queue.put("Run paused.")

    def _on_stop(self) -> None:
        self._run_control.stop()
        self._log_queue.put("Stop requested — halting at the next year or ensemble boundary.")

    def _on_run_success(self, output_file: str) -> None:
        self._finish_run_ui("Nice reefkeeping!")
        self.open_button.configure(state=tk.NORMAL)
        self.charts_button.configure(state=tk.NORMAL)
        if messagebox.askyesno(
            "Run complete",
            f"CoCoNet finished successfully.\n\nOutput:\n{output_file}\n\nOpen charts now?",
        ):
            self._on_view_charts()

    def _resolve_chart_output(self) -> Path | None:
        if self._last_output_file is not None and self._last_output_file.is_file():
            return self._last_output_file
        candidate = Path(self.output_path.get().strip())
        if candidate.is_file():
            return candidate.resolve()
        return None

    def _on_view_charts(self) -> None:
        output = self._resolve_chart_output()
        if output is None:
            messagebox.showerror(
                "No output file",
                "Choose an existing output CSV path, or run the model first.",
            )
            return
        try:
            launch_chart_viewer(output)
        except Exception as exc:
            messagebox.showerror("Chart viewer", str(exc))

    def _on_run_stopped(self) -> None:
        self._finish_run_ui("Run stopped.")
        output = self._resolve_chart_output()
        if output is not None:
            self._last_output_file = output
            self.open_button.configure(state=tk.NORMAL)
            self.charts_button.configure(state=tk.NORMAL)
        messagebox.showinfo(
            "Run stopped",
            "The model run was stopped.\n\n"
            "Partial output may have been written if reporting had already started.",
        )

    def _on_run_failure(self, message: str) -> None:
        self._finish_run_ui("Run failed.")
        messagebox.showerror("Run failed", message)

    def _on_open_output_folder(self) -> None:
        if self._last_output_file is None:
            return
        folder = self._last_output_file.parent
        if sys.platform == "win32":
            import os

            os.startfile(folder)
        elif sys.platform == "darwin":
            import subprocess

            subprocess.run(["open", str(folder)], check=False)
        else:
            import subprocess

            subprocess.run(["xdg-open", str(folder)], check=False)


def main() -> None:
    multiprocessing.freeze_support()
    if len(sys.argv) >= 3 and sys.argv[1] == "--viz-viewer":
        from coconet.viz_viewer import run_viewer

        run_viewer(Path(sys.argv[2]))
        return

    root = tk.Tk()
    with suppress(tk.TclError):
        ttk.Style().theme_use("clam")
    CoconetGuiApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
