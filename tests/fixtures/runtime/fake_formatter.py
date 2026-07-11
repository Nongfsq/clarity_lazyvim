from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> int:
    args = sys.argv[1:]
    Path(os.environ["CLARITY_FAKE_FORMATTER_LOG"]).write_text(
        json.dumps({"argv": args, "cwd": os.getcwd()}),
        encoding="utf-8",
    )
    source = sys.stdin.read()
    filename = args[args.index("--stdin-filepath") + 1] if "--stdin-filepath" in args else ""
    cursor = Path(filename).resolve().parent if filename else Path.cwd()
    configured = any(
        (parent / "stylua.toml").is_file() or (parent / ".stylua.toml").is_file()
        for parent in (cursor, *cursor.parents)
    )
    if configured:
        source = "\n".join(
            ("  " + line[4:]) if line.startswith("    ") else line
            for line in source.split("\n")
        )
    sys.stdout.write(source)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
