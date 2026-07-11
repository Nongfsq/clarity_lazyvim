from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import run_clarity_tests as runner  # noqa: E402


class ClarityTestRouterTests(unittest.TestCase):
    def test_authority_files_include_root_bootstrap(self) -> None:
        self.assertEqual(runner.AUTHORITY_FILES, ("init.lua", "lazy-lock.json", "lazyvim.json"))

    def test_default_plugin_cache_falls_back_to_standard_data_home(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            expected = home / ".local" / "share" / "nvim" / "lazy"
            expected.mkdir(parents=True)

            self.assertEqual(runner.default_plugin_cache({}, home=home), expected)

    def test_attached_python_requires_exact_pynvim_version_or_pinned_uv(self) -> None:
        available = mock.Mock(returncode=0)
        with mock.patch.object(runner.subprocess, "run", return_value=available):
            self.assertEqual(runner.contract_python_command("python"), ["python"])

        missing = mock.Mock(returncode=1)
        with (
            mock.patch.object(runner.subprocess, "run", return_value=missing),
            mock.patch.object(runner.shutil, "which", return_value="/usr/bin/uv"),
        ):
            self.assertEqual(
                runner.contract_python_command("python"),
                ["/usr/bin/uv", "run", "--with", "pynvim==0.6.0", "python"],
            )

    def test_output_truncation_is_bounded_and_marked(self) -> None:
        value, truncated = runner.truncate_output("a" * 100, 40)
        self.assertTrue(truncated)
        self.assertLessEqual(len(value.encode()), 40)
        self.assertIn("truncated", value)

    def test_child_json_tolerates_tooling_output_after_report(self) -> None:
        report = runner.parse_child_json('notice\n{\n  "status": "pass"\n}\ninstalled package\n')
        self.assertEqual(report, {"status": "pass"})

    def test_behavior_requires_the_fold_feature(self) -> None:
        with self.assertRaisesRegex(ValueError, "--feature fold"):
            runner.build_commands(REPO_ROOT, "behavior", "python", "nvim", None, [], None)

    def test_behavior_routes_the_real_input_action_matrix(self) -> None:
        commands = runner.build_commands(REPO_ROOT, "behavior", "python", "nvim", "fold", [], None)
        self.assertEqual(
            [command["id"] for command in commands],
            ["CLARITY_TESTS_BEHAVIOR_FOLD", "CLARITY_TESTS_ACTION_MATRIX"],
        )
        self.assertIn("scripts/run_clarity_action_matrix.py", commands[1]["command"])

    def test_contract_scenarios_are_forwarded(self) -> None:
        commands = runner.build_commands(
            REPO_ROOT, "contracts", "python", "nvim", None, ["file_headless"], None
        )
        self.assertEqual(commands[0]["command"].count("--scenario"), 1)
        self.assertIn("file_headless", commands[0]["command"])

    def test_artifact_contract_is_complete_and_parseable(self) -> None:
        report = {
            "generated_at": "2026-07-10T00:00:00+00:00",
            "manifest": {"schema_version": 1, "suite": "unit", "status": "pass"},
            "snapshot_before": {"authority_hashes": {}},
            "snapshot_after": {"authority_hashes": {}},
            "checks": [
                {
                    "check_id": "CLARITY_TEST",
                    "ok": True,
                    "returncode": 0,
                    "output": "ok",
                    "output_truncated": False,
                }
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            runner.write_artifacts(target, report)
            expected = {
                "manifest.json",
                "checks.json",
                "events.jsonl",
                "snapshot-before.json",
                "snapshot-after.json",
                "messages.txt",
                "stdout.txt",
                "stderr.txt",
                "junit.xml",
            }
            self.assertEqual({path.name for path in target.iterdir()}, expected)
            self.assertEqual(json.loads((target / "events.jsonl").read_text())["event_id"], "CLARITY_TEST")


if __name__ == "__main__":
    unittest.main()
