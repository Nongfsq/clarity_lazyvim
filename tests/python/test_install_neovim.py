from __future__ import annotations

import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import install_neovim  # noqa: E402


class InstallNeovimTests(unittest.TestCase):
    def test_selects_supported_assets(self) -> None:
        self.assertEqual(install_neovim.select_asset("Linux", "AMD64").name, "nvim-linux-x86_64.tar.gz")
        self.assertEqual(install_neovim.select_asset("Darwin", "arm64").name, "nvim-macos-arm64.tar.gz")
        self.assertEqual(install_neovim.select_asset("Windows", "x64").name, "nvim-win64.zip")

    def test_rejects_unsupported_platform(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "Unsupported Neovim CI platform"):
            install_neovim.select_asset("Plan9", "mips")

    def test_manifest_is_complete_and_uses_sha256(self) -> None:
        for asset in install_neovim.ASSETS.values():
            with self.subTest(asset=asset.name):
                self.assertEqual(len(asset.sha256), 64)
                self.assertTrue(asset.binary.endswith(("nvim", "nvim.exe")))


if __name__ == "__main__":
    unittest.main()
