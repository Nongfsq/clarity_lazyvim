from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ClipboardContractTests(unittest.TestCase):
    def test_health_clipboard_has_english_chinese_key_parity(self):
        source = (ROOT / "nvim/lua/config/health.lua").read_text(encoding="utf-8")
        for key in (
            "clipboard_header",
            "clipboard_mode",
            "clipboard_provider",
            "clipboard_kind",
            "clipboard_ready",
            "clipboard_copy",
            "clipboard_ssh",
            "clipboard_privacy",
        ):
            self.assertEqual(len(re.findall(rf"\b{key}\s*=", source)), 2, key)

    def test_runtime_never_reads_or_logs_clipboard_contents(self):
        paths = [
            ROOT / "nvim/lua/config/options.lua",
            ROOT / "nvim/lua/config/audit.lua",
            ROOT / "nvim/lua/config/health.lua",
            ROOT / "nvim/lua/config/help.lua",
        ]
        source = "\n".join(path.read_text(encoding="utf-8") for path in paths)
        forbidden = (
            "getreg(\"+\")",
            "getreg('+')",
            "vim.ui.clipboard.osc52').paste",
            'vim.ui.clipboard.osc52").paste',
            "clipboard_content",
            "clipboard_text",
        )
        for token in forbidden:
            self.assertNotIn(token, source)

    def test_health_states_copy_only_and_privacy_boundaries(self):
        source = (ROOT / "nvim/lua/config/health.lua").read_text(encoding="utf-8")
        self.assertIn("OSC52 is a copy-only path", source)
        self.assertIn("OSC52 只负责复制", source)
        self.assertIn("Health never reads or records clipboard contents", source)
        self.assertIn("Health 永远不会读取或记录剪贴板内容", source)

    def test_missing_clipboard_is_profile_not_core(self):
        source = (ROOT / "nvim/lua/config/audit.lua").read_text(encoding="utf-8")
        block = re.search(
            r'id\s*=\s*"clipboard_provider"(?P<body>.*?)\n\s*\}\)', source, re.DOTALL
        )
        self.assertIsNotNone(block)
        self.assertIn('profile = "clipboard"', block.group("body"))
        self.assertNotIn('profile = "core"', block.group("body"))


if __name__ == "__main__":
    unittest.main()
