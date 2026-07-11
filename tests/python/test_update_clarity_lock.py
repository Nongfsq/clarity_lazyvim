from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import update_clarity_lock  # noqa: E402


class LockTransactionTests(unittest.TestCase):
    def test_default_backup_root_honors_xdg_state_home(self) -> None:
        root = update_clarity_lock.default_backup_root({"XDG_STATE_HOME": "/tmp/clarity-state"})
        self.assertEqual(root, Path("/tmp/clarity-state/clarity_lazyvim/lock-backups"))

    def test_replace_with_backup_preserves_old_bytes_and_applies_new_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "lazy-lock.json"
            proposed = root / "proposed.json"
            backup_root = root / "backups"
            source.write_bytes(b'{"old": true}\n')
            source.chmod(0o640)
            proposed.write_bytes(b'{"new": true}\n')

            backup = update_clarity_lock.replace_with_backup(source, proposed, backup_root)

            self.assertEqual(backup.read_bytes(), b'{"old": true}\n')
            self.assertEqual(source.read_bytes(), b'{"new": true}\n')
            self.assertEqual(os.stat(backup_root).st_mode & 0o777, 0o700)
            self.assertEqual(os.stat(backup).st_mode & 0o777, 0o600)
            self.assertEqual(os.stat(source).st_mode & 0o777, 0o640)

    def test_prune_reviewed_exclusions_keeps_active_lock_in_lazy_format(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            lockfile = Path(directory) / "lazy-lock.json"
            lockfile.write_text(
                '{\n'
                '  "active.nvim": { "branch": "main", "commit": "abc" },\n'
                '  "reviewed.nvim": { "branch": "stable", "commit": "def" },\n'
                '  "conditional.nvim": { "branch": "main", "commit": "ghi" }\n'
                '}\n',
                encoding="utf-8",
            )

            removed = update_clarity_lock.prune_reviewed_exclusions(
                lockfile,
                ["reviewed.nvim", "not-locked.nvim"],
                ["reviewed.nvim", "conditional.nvim"],
            )

            self.assertEqual(removed, ["reviewed.nvim"])
            self.assertEqual(
                lockfile.read_text(encoding="utf-8"),
                '{\n'
                '  "active.nvim": { "branch": "main", "commit": "abc" },\n'
                '  "conditional.nvim": { "branch": "main", "commit": "ghi" }\n'
                '}\n',
            )

    def test_prune_reviewed_exclusions_requires_runtime_confirmation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            lockfile = Path(directory) / "lazy-lock.json"
            original = b'{"reviewed.nvim":{"branch":"main","commit":"abc"}}\n'
            lockfile.write_bytes(original)

            removed = update_clarity_lock.prune_reviewed_exclusions(
                lockfile,
                ["reviewed.nvim"],
                ["another.nvim"],
            )

            self.assertEqual(removed, [])
            self.assertEqual(lockfile.read_bytes(), original)

    def test_prune_reviewed_exclusions_requires_registry_membership(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            lockfile = Path(directory) / "lazy-lock.json"
            original = b'{"conditional.nvim":{"branch":"main","commit":"abc"}}\n'
            lockfile.write_bytes(original)

            removed = update_clarity_lock.prune_reviewed_exclusions(
                lockfile,
                ["reviewed.nvim"],
                ["conditional.nvim"],
            )

            self.assertEqual(removed, [])
            self.assertEqual(lockfile.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
