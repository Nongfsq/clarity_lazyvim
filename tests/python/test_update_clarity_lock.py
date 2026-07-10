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
            proposed.write_bytes(b'{"new": true}\n')

            backup = update_clarity_lock.replace_with_backup(source, proposed, backup_root)

            self.assertEqual(backup.read_bytes(), b'{"old": true}\n')
            self.assertEqual(source.read_bytes(), b'{"new": true}\n')
            self.assertEqual(os.stat(source).st_mode & 0o777, os.stat(backup).st_mode & 0o777)


if __name__ == "__main__":
    unittest.main()
