from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
I18N = ROOT / "nvim/lua/config/i18n.lua"

EXPECTED_KEYS = frozenset(
    {
        "locale.choice.auto",
        "locale.choice.en",
        "locale.choice.zh",
        "locale.source.env",
        "locale.source.global",
        "locale.source.persisted",
        "locale.source.auto",
        "locale.source.runtime",
        "locale.current",
        "locale.usage",
        "locale.updated",
        "locale.invalid",
        "locale.save_failed",
        "commands.health",
        "commands.audit",
        "commands.validate",
        "commands.start",
        "commands.clipboard",
        "commands.sync",
        "commands.language",
        "commands.log",
        "help.open_failed",
        "keymaps.next_hunk",
        "keymaps.prev_hunk",
        "keymaps.preview_hunk",
        "keymaps.explorer_cwd",
        "keymaps.explorer_root",
        "keymaps.terminal_float_center",
        "keymaps.help_start_hub",
        "notifications.feature_unavailable",
        "notifications.fold_no_fold",
        "notifications.fold_unsupported",
        "notifications.fold_degraded",
        "notifications.fold_failed",
        "notifications.fold_toggled",
        "notifications.log_path",
        "notifications.log_exported",
        "notifications.log_export_failed",
        "notifications.log_usage",
    }
)


def catalog_keys(source: str) -> dict[str, set[str]]:
    """Extract leaf paths from the deliberately simple local strings table."""
    in_catalog = False
    stack: list[tuple[int, str]] = []
    result: dict[str, set[str]] = {}

    for line in source.splitlines():
        if line == "local strings = {":
            in_catalog = True
            continue
        if not in_catalog:
            continue
        if line == "}":
            break

        table = re.match(
            r"^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{\s*,?\s*$", line
        )
        if table:
            indent = len(table.group(1))
            while stack and stack[-1][0] >= indent:
                stack.pop()
            stack.append((indent, table.group(2)))
            continue

        leaf = re.match(r"^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?!\{)", line)
        if not leaf:
            continue
        indent = len(leaf.group(1))
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if len(stack) < 2:
            raise AssertionError(f"unexpected i18n leaf outside a locale table: {line}")
        locale = stack[0][1]
        key = ".".join([part for _, part in stack[1:]] + [leaf.group(2)])
        result.setdefault(locale, set()).add(key)

    return result


class I18nCatalogContractTests(unittest.TestCase):
    def test_catalog_is_exact_bilingual_consumed_surface(self):
        catalogs = catalog_keys(I18N.read_text(encoding="utf-8"))
        self.assertEqual(set(catalogs), {"en", "zh"})
        self.assertEqual(catalogs["en"], EXPECTED_KEYS)
        self.assertEqual(catalogs["zh"], EXPECTED_KEYS)

    def test_retired_panels_and_git_mutation_labels_stay_absent(self):
        keys = catalog_keys(I18N.read_text(encoding="utf-8"))["en"]
        self.assertFalse(any(key.startswith("help.start_") for key in keys))
        self.assertFalse(any(key.startswith("help.clipboard_") for key in keys))
        self.assertFalse(any(key.startswith("help.sync_") for key in keys))
        self.assertTrue(
            {
                "keymaps.stage_hunk",
                "keymaps.reset_hunk",
                "keymaps.stage_buffer",
                "keymaps.reset_buffer",
                "keymaps.undo_stage_hunk",
            }.isdisjoint(keys)
        )


if __name__ == "__main__":
    unittest.main()
