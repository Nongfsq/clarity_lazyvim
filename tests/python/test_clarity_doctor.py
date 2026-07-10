from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import clarity_doctor  # noqa: E402


class ClarityDoctorTests(unittest.TestCase):
    def test_platform_kind_distinguishes_macos_linux_windows_and_wsl(self) -> None:
        with mock.patch.object(clarity_doctor, "is_wsl", return_value=True):
            self.assertEqual(clarity_doctor.platform_kind(), "wsl")

        for system, expected in (("Darwin", "macos"), ("Linux", "linux"), ("Windows", "windows")):
            with self.subTest(system=system):
                with mock.patch.object(clarity_doctor, "is_wsl", return_value=False):
                    with mock.patch("platform.system", return_value=system):
                        self.assertEqual(clarity_doctor.platform_kind(), expected)

    def test_install_hint_is_platform_specific(self) -> None:
        self.assertIn("brew", clarity_doctor.install_hint("ripgrep", "macos"))
        self.assertIn("winget", clarity_doctor.install_hint("ripgrep", "windows"))
        self.assertIn("apt-get", clarity_doctor.install_hint("ripgrep", "linux"))

    def test_parser_failure_with_user_override_is_safely_fixable(self) -> None:
        hint, fixable = clarity_doctor.vim_parser_failure_hint({}, "invalid node", True)
        self.assertTrue(fixable)
        self.assertIn("--apply", hint)

    def test_parse_nvim_version(self) -> None:
        self.assertEqual(clarity_doctor.parse_nvim_version("NVIM v0.12.4\nBuild type"), (0, 12, 4))
        self.assertIsNone(clarity_doctor.parse_nvim_version("unknown"))


if __name__ == "__main__":
    unittest.main()
