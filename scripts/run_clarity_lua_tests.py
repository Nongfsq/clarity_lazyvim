from __future__ import annotations

import argparse
import sys
from pathlib import Path

from clarity_runtime import build_env, combined_output, resolve_nvim_binary, run_command


def run() -> int:
    parser = argparse.ArgumentParser(description="Run Clarity Lua policy tests with a clean Neovim runtime.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    parser.add_argument("--timeout", type=float, default=60, help="Timeout per Lua test file.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    nvim = resolve_nvim_binary(args.nvim_bin)
    tests = sorted((repo_root / "tests" / "lua").glob("test_*.lua"))
    if not tests:
        raise RuntimeError("No Lua tests found under tests/lua")

    for test in tests:
        result = run_command(
            [nvim, "--clean", "--headless", "-u", "NONE", "-l", str(test)],
            cwd=repo_root,
            env=build_env(),
            timeout=args.timeout,
        )
        output = combined_output(result)
        if output:
            print(output)
        if result.returncode != 0:
            print(f"Lua test failed: {test}", file=sys.stderr)
            return result.returncode

    print(f"Lua policy tests passed: {len(tests)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
