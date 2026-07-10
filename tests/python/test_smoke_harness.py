from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import run_clarity_smoke  # noqa: E402


class SmokeHarnessTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
