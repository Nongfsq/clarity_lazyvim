from __future__ import annotations

import json
import os
import signal
import sys
import tempfile
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from clarity_runtime import (  # noqa: E402
    CommandTimeoutError,
    build_env,
    configure_isolated_runtime,
    extract_last_json_object,
    nvim_candidates,
    process_group_popen_options,
    run_command,
    sha256_file,
)


class ClarityRuntimeTests(unittest.TestCase):
    def test_extracts_last_json_object_from_mixed_logs(self) -> None:
        report = extract_last_json_object('noise\n{"first": true}\nwarning\n{"final": 2}\n')
        self.assertEqual(report, {"final": 2})

    def test_invalid_json_line_is_reported(self) -> None:
        with self.assertRaises(json.JSONDecodeError):
            extract_last_json_object("noise\n{invalid}\n")

    def test_isolated_runtime_uses_only_the_requested_root(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = {"HOME": "/user/home", "PATH": os.environ.get("PATH", "")}
            env = configure_isolated_runtime(build_env(base_env=original), root)

            self.assertEqual(env["CLARITY_NONINTERACTIVE"], "1")
            for name in ("CONFIG", "DATA", "STATE", "CACHE"):
                value = Path(env[f"XDG_{name}_HOME"])
                self.assertTrue(value.is_dir())
                self.assertEqual(value.parent, root)
            self.assertEqual(env["HOME"], "/user/home")

    def test_windows_candidates_include_chocolatey_layout(self) -> None:
        candidates = {str(path) for path in nvim_candidates({"NVIM_BIN": r"D:\nvim\nvim.exe"})}
        self.assertIn(r"D:\nvim\nvim.exe", candidates)
        self.assertIn(r"C:\tools\neovim\nvim-win64\bin\nvim.exe", candidates)

    def test_process_group_options_cover_posix_and_windows(self) -> None:
        self.assertEqual(process_group_popen_options(windows=False), {"start_new_session": True})
        self.assertEqual(process_group_popen_options(windows=True), {"creationflags": 0x00000200})

    def test_timeout_is_bounded_and_actionable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(CommandTimeoutError) as caught:
                run_command(
                    [sys.executable, "-c", "import time; time.sleep(2)"],
                    cwd=Path(directory),
                    env=dict(os.environ),
                    timeout=0.05,
                )
        self.assertIn("timed out", str(caught.exception))
        self.assertEqual(caught.exception.timeout, 0.05)

    @unittest.skipIf(os.name == "nt", "POSIX process-group assertion")
    def test_timeout_terminates_descendant_process_group(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pid_file = root / "child.pid"
            child_source = (
                "import signal, time; "
                "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                "time.sleep(30)"
            )
            source = (
                "import pathlib, subprocess, sys, time; "
                f"child=subprocess.Popen([sys.executable, '-c', {child_source!r}]); "
                f"pathlib.Path({str(pid_file)!r}).write_text(str(child.pid)); "
                "time.sleep(0.2); "
                "time.sleep(30)"
            )
            with self.assertRaises(CommandTimeoutError):
                run_command(
                    [sys.executable, "-c", source],
                    cwd=root,
                    env=dict(os.environ),
                    timeout=0.5,
                )
            child_pid = int(pid_file.read_text(encoding="utf-8"))
            alive = True
            deadline = time.monotonic() + 2
            while time.monotonic() < deadline:
                try:
                    os.kill(child_pid, 0)
                except ProcessLookupError:
                    alive = False
                    break
                time.sleep(0.05)
            if alive:
                try:
                    os.kill(child_pid, signal.SIGKILL)
                except ProcessLookupError:
                    alive = False
            self.assertFalse(alive, f"descendant process {child_pid} survived timeout cleanup")

    def test_sha256_file_is_stable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample"
            path.write_bytes(b"clarity")
            self.assertEqual(
                sha256_file(path),
                "261b152862d1d614014496a635018719d34bb3965c5bd7a9f7bbebc7cd8b8696",
            )


if __name__ == "__main__":
    unittest.main()
