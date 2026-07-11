from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import run_clarity_action_matrix as matrix_runner  # noqa: E402


class ActionMatrixTests(unittest.TestCase):
    def test_evaluate_requires_exact_global_and_context_coverage(self) -> None:
        expected = [f"<leader>{index:02d}" for index in range(28)]
        actions = [
            {
                "action_id": f"action.{index}",
                "lhs": lhs,
                "ok": True,
            }
            for index, lhs in enumerate(expected[:-1])
        ]
        session = {
            "action_id": "session.quit_all",
            "lhs": expected[-1],
            "ok": True,
            "isolated_process": True,
            "startup": {"clean": True},
        }
        contextual = [
            {"action_id": action_id, "lhs": lhs, "ok": True}
            for action_id, lhs in (
                ("format.auto_buffer_toggle", "<leader>uF"),
                ("git.hunk_preview", "<leader>ghp"),
                ("lsp.code_action", "<leader>ca"),
                ("lsp.document_symbols", "<leader>ss"),
                ("lsp.inlay_hints_toggle", "<leader>uh"),
                ("lsp.rename_symbol", "<leader>cr"),
                ("lsp.workspace_symbols", "<leader>sS"),
            )
        ]
        extras = [
            {"id": name, "ok": True}
            for name in (
                "diagnostic.next_previous",
                "lsp.definition",
                "lsp.hover",
                "lsp.references",
            )
        ]

        matrix = {
            "actions": actions,
            "contextual": contextual,
            "extras": extras,
            "expected_manifest": expected,
            "expected_global_manifest": [
                {"action_id": case["action_id"], "lhs": case["lhs"]}
                for case in [*actions, session]
            ],
            "expected_contextual_manifest": [
                {"action_id": case["action_id"], "lhs": case["lhs"]} for case in contextual
            ],
            "startup": {"clean": True},
            "cleanup_recovery": {"ok": True},
        }
        report = matrix_runner.evaluate(
            matrix,
            session,
            repository_immutable=True,
            authority_immutable=True,
            fixture_processes_exited=True,
            fixture_process_count=2,
        )

        self.assertEqual(report["status"], "pass")
        self.assertTrue(report["global"]["manifest_exact"])
        self.assertEqual(report["global"]["actual_count"], 28)
        self.assertEqual(report["contextual"]["actual_count"], 7)
        self.assertEqual(report["extras"]["actual_count"], 4)
        isolation_failure = matrix_runner.evaluate(
            matrix,
            session,
            repository_immutable=False,
            authority_immutable=True,
            fixture_processes_exited=True,
            fixture_process_count=2,
        )
        self.assertEqual(isolation_failure["status"], "fail")
        self.assertFalse(isolation_failure["isolation"]["repository_immutable"])

    def test_evaluate_reports_the_exact_failed_action(self) -> None:
        expected = [f"<leader>{index:02d}" for index in range(28)]
        actions = [
            {
                "action_id": f"action.{index}",
                "lhs": lhs,
                "ok": index != 7,
            }
            for index, lhs in enumerate(expected[:-1])
        ]
        session = {
            "action_id": "session.quit_all",
            "lhs": expected[-1],
            "ok": True,
            "isolated_process": True,
            "startup": {"clean": True},
        }

        report = matrix_runner.evaluate(
            {
                "actions": actions,
                "contextual": [],
                "extras": [],
                "expected_manifest": expected,
                "expected_global_manifest": [
                    {"action_id": case["action_id"], "lhs": case["lhs"]}
                    for case in [*actions, session]
                ],
                "startup": {"clean": True},
                "cleanup_recovery": {"ok": True},
            },
            session,
            repository_immutable=True,
            authority_immutable=True,
            fixture_processes_exited=True,
            fixture_process_count=2,
        )

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["global"]["failure_ids"], ["action.7"])

    def test_evaluate_rejects_startup_errors_even_when_all_actions_pass(self) -> None:
        expected = [f"<leader>{index:02d}" for index in range(28)]
        contextual = [
            {"action_id": f"context.{index}", "lhs": f"<leader>c{index}", "ok": True}
            for index in range(7)
        ]
        extras = [
            {"id": name, "ok": True}
            for name in (
                "diagnostic.next_previous",
                "lsp.definition",
                "lsp.hover",
                "lsp.references",
            )
        ]
        session = {
            "action_id": "session.quit_all",
            "lhs": expected[-1],
            "ok": True,
            "isolated_process": True,
            "startup": {"clean": True},
        }
        report = matrix_runner.evaluate(
            {
                "actions": [
                    {"action_id": f"action.{index}", "lhs": lhs, "ok": True}
                    for index, lhs in enumerate(expected[:-1])
                ],
                "contextual": contextual,
                "extras": extras,
                "expected_manifest": expected,
                "expected_global_manifest": [
                    {"action_id": f"action.{index}", "lhs": lhs}
                    for index, lhs in enumerate(expected[:-1])
                ]
                + [{"action_id": session["action_id"], "lhs": session["lhs"]}],
                "expected_contextual_manifest": [
                    {"action_id": case["action_id"], "lhs": case["lhs"]} for case in contextual
                ],
                "startup": {"clean": False, "errors": ["E5108 fixture"]},
                "cleanup_recovery": {"ok": True},
            },
            session,
            repository_immutable=True,
            authority_immutable=True,
            fixture_processes_exited=True,
            fixture_process_count=2,
        )

        self.assertEqual(report["status"], "fail")
        self.assertFalse(report["startup"]["clean"])
        self.assertEqual(report["startup"]["matrix"]["errors"], ["E5108 fixture"])

    def test_environment_isolates_home_shell_startup_and_git_hooks(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = {
                "HOME": "/real/home",
                "USERPROFILE": "/real/profile",
                "SHELL": "/bin/zsh",
                "PATH": os.environ.get("PATH", ""),
                "GIT_DIR": "/outside/repository/.git",
                "GIT_WORK_TREE": "/outside/repository",
                "GIT_INDEX_FILE": "/outside/repository/.git/index",
                "GIT_NAMESPACE": "outside",
                "GIT_CEILING_DIRECTORIES": "/outside",
                "GIT_TEMPLATE_DIR": "/outside/templates",
                "GIT_AUTHOR_NAME": "Private User",
                "GIT_TRACE": "1",
            }
            isolated = matrix_runner.isolate_action_matrix_environment(original, root, windows=False)

            self.assertEqual(isolated["HOME"], str(root / "home"))
            self.assertEqual(isolated["USERPROFILE"], str(root / "home"))
            self.assertEqual(isolated["ZDOTDIR"], str(root / "home"))
            self.assertNotEqual(isolated["SHELL"], original["SHELL"])
            self.assertEqual(isolated["ENV"], str(root / "empty-shell-init"))
            self.assertEqual(isolated["BASH_ENV"], str(root / "empty-shell-init"))
            self.assertEqual(isolated["GIT_CONFIG_KEY_0"], "core.hooksPath")
            self.assertEqual(isolated["GIT_CONFIG_VALUE_0"], str(root / "git-hooks"))
            self.assertEqual(isolated["GIT_CONFIG_NOSYSTEM"], "1")
            self.assertNotIn("GIT_DIR", isolated)
            self.assertNotIn("GIT_WORK_TREE", isolated)
            self.assertNotIn("GIT_INDEX_FILE", isolated)
            self.assertNotIn("GIT_NAMESPACE", isolated)
            self.assertNotIn("GIT_CEILING_DIRECTORIES", isolated)
            self.assertNotIn("GIT_TEMPLATE_DIR", isolated)
            self.assertNotIn("GIT_AUTHOR_NAME", isolated)
            self.assertNotIn("GIT_TRACE", isolated)

    def test_configured_environment_points_probe_to_candidate_catalog(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            candidate = root / "candidate"
            runtime = root / "runtime"
            configured = matrix_runner.configure_action_matrix_environment(candidate, runtime)

            self.assertEqual(
                configured["CLARITY_CONTRACT_CATALOG"],
                str(candidate / "tests" / "contracts" / "runtime_contract.lua"),
            )
            self.assertEqual(configured["HOME"], str(runtime / "home"))
            self.assertEqual(configured["CLARITY_ACTION_MATRIX_RUNTIME_ROOT"], str(runtime))

    def test_windows_environment_uses_controlled_cmd_and_isolated_profile(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            isolated = matrix_runner.isolate_action_matrix_environment(
                {"COMSPEC": r"C:\\Windows\\System32\\cmd.exe", "SHELL": r"C:\\custom\\bash.exe"},
                root,
                windows=True,
            )

            self.assertEqual(isolated["SHELL"], isolated["COMSPEC"])
            self.assertEqual(isolated["HOME"], str(root / "home"))
            self.assertEqual(isolated["USERPROFILE"], str(root / "home"))
            self.assertEqual(isolated["GIT_CONFIG_GLOBAL"], str(root / "empty-gitconfig"))

    def test_privacy_checker_redacts_nested_fixture_paths_before_serialization(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            clean = {"evidence": {"root_matches": True}}
            leaked = {"evidence": [{"path": str(root / "candidate" / "file.lua")}]}

            self.assertEqual(matrix_runner.fixture_path_leak_count(clean, (root,)), 0)
            self.assertEqual(matrix_runner.fixture_path_leak_count(leaked, (root,)), 1)
            redacted, count = matrix_runner.redact_report_paths(leaked, ((root, "<fixture>"),))
            encoded = json.dumps(redacted)
            self.assertGreater(count, 0)
            self.assertNotIn(str(root), encoded)
            self.assertIn("<fixture>", encoded)


if __name__ == "__main__":
    unittest.main()
