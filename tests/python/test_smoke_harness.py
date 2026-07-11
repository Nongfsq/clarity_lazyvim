from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import run_clarity_smoke  # noqa: E402


class SmokeHarnessTests(unittest.TestCase):
    def test_authority_files_include_root_bootstrap(self) -> None:
        self.assertEqual(
            run_clarity_smoke.AUTHORITY_FILES,
            ("init.lua", "lazy-lock.json", "lazyvim.json"),
        )

    def test_probe_emits_json_on_a_fresh_line(self) -> None:
        self.assertIn("io.stdout:write", run_clarity_smoke.probe_command())

    def test_candidate_copy_excludes_local_agent_and_git_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            destination = root / "candidate"
            source.mkdir()
            (source / "lazy-lock.json").write_text("{}\n", encoding="utf-8")
            (source / "lazyvim.json").write_text("{}\n", encoding="utf-8")
            (source / "AGENTS.md").write_text("local only\n", encoding="utf-8")
            (source / ".git").mkdir()
            (source / ".git" / "HEAD").write_text("ref\n", encoding="utf-8")

            run_clarity_smoke.copy_candidate(source, destination)

            self.assertTrue((destination / "lazy-lock.json").is_file())
            self.assertTrue((destination / "lazyvim.json").is_file())
            self.assertFalse((destination / "AGENTS.md").exists())
            self.assertFalse((destination / ".git").exists())

    def test_git_candidate_copy_excludes_ignored_local_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            destination = root / "candidate"
            source.mkdir()
            (source / ".gitignore").write_text(".env\nAGENTS.md\n", encoding="utf-8")
            (source / "init.lua").write_text("return {}\n", encoding="utf-8")
            (source / "visible-untracked.lua").write_text("return true\n", encoding="utf-8")
            (source / ".env").write_text("SECRET=private\n", encoding="utf-8")
            (source / "AGENTS.md").write_text("local only\n", encoding="utf-8")
            subprocess.run(["git", "init", "--quiet", str(source)], check=True)
            subprocess.run(
                ["git", "-C", str(source), "add", ".gitignore", "init.lua"],
                check=True,
            )

            run_clarity_smoke.copy_candidate(source, destination)

            self.assertTrue((destination / "init.lua").is_file())
            self.assertTrue((destination / "visible-untracked.lua").is_file())
            self.assertFalse((destination / ".env").exists())
            self.assertFalse((destination / "AGENTS.md").exists())
            self.assertFalse((destination / ".git").exists())


if __name__ == "__main__":
    unittest.main()
