from __future__ import annotations

import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import run_clarity_validate  # noqa: E402


class ValidationHelperTests(unittest.TestCase):
    def test_parse_node_major(self) -> None:
        self.assertEqual(run_clarity_validate.parse_node_major("v22.14.0"), 22)
        self.assertEqual(run_clarity_validate.parse_node_major("node v26.5.0"), 26)
        self.assertIsNone(run_clarity_validate.parse_node_major("unknown"))

    def test_check_ids_are_stable_and_machine_safe(self) -> None:
        check = run_clarity_validate.CheckResult("Keymap <leader>ff exists", True, "expected true")
        self.assertEqual(check.id, "CLARITY_VALIDATE_KEYMAP_LEADER_FF_EXISTS")


if __name__ == "__main__":
    unittest.main()
