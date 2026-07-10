from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ClipboardContractTests(unittest.TestCase):
    def test_clipboard_help_has_english_chinese_key_parity(self):
        source = (ROOT / "nvim/lua/config/i18n.lua").read_text(encoding="utf-8")
        for key in (
            "clipboard_paths_header",
            "clipboard_path_1_detail",
            "clipboard_path_2_detail",
            "clipboard_path_3_detail",
            "clipboard_rule_header",
            "clipboard_rule_line_3",
        ):
            self.assertEqual(len(re.findall(rf"\b{key}\s*=", source)), 2, key)

    def test_runtime_never_reads_or_logs_clipboard_contents(self):
        paths = [
            ROOT / "nvim/lua/config/options.lua",
            ROOT / "nvim/lua/config/audit.lua",
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

    def test_osc52_copy_only_language_is_explicit(self):
        source = (ROOT / "nvim/lua/config/i18n.lua").read_text(encoding="utf-8")
        self.assertIn("Clarity promises OSC52 copy only", source)
        self.assertIn("只承诺 OSC52 复制", source)

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
