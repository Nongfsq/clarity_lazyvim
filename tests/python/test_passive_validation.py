from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

import run_clarity_validate  # noqa: E402


class PassiveValidationTests(unittest.TestCase):
    def test_lua_collectors_have_no_live_session_actions(self) -> None:
        for relative in ("nvim/lua/config/audit.lua", "nvim/lua/config/validation.lua"):
            source = (ROOT / relative).read_text(encoding="utf-8")
            for forbidden in (
                "doautocmd User VeryLazy",
                "silent edit ",
                'vim.cmd, "Neotree show"',
                "nvim_create_buf",
                "nvim_exec_autocmds",
                "vim.treesitter.start",
            ):
                self.assertNotIn(forbidden, source, f"{relative} retains live mutation: {forbidden}")

    def test_python_validator_delegates_behavior_contracts(self) -> None:
        source = (ROOT / "scripts/run_clarity_validate.py").read_text(encoding="utf-8")
        self.assertNotIn("doautocmd User VeryLazy", source)
        self.assertNotIn("Neotree show", source)
        self.assertNotIn("nvim_exec_autocmds", source)
        self.assertEqual(
            run_clarity_validate.DELEGATED_CHECKS["CLARITY_VALIDATE_KEYMAP_LEADER_GD_EXISTS"],
            "CLARITY_RUNTIME_KEYMAP_CONTRACT",
        )
        self.assertEqual(
            run_clarity_validate.DELEGATED_CHECKS["CLARITY_VALIDATE_NEOTREE_WINDOW_DISCOVERED"],
            "CLARITY_RUNTIME_EXPLORER_CONTRACT",
        )

    def test_public_helpers_remain_stable(self) -> None:
        check = run_clarity_validate.CheckResult("Headless startup", True, "ok")
        self.assertEqual(check.id, "CLARITY_VALIDATE_HEADLESS_STARTUP")
        self.assertEqual(run_clarity_validate.parse_node_major("node v26.5.0"), 26)


if __name__ == "__main__":
    unittest.main()
