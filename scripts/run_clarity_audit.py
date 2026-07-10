from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from clarity_runtime import build_env, combined_output, extract_last_json_object, resolve_nvim_binary, run_nvim


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the Clarity runtime capability audit.")
    parser.add_argument("--json", action="store_true", help="Emit only the machine-readable audit report.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    parser.add_argument("--timeout", type=float, default=120, help="Neovim timeout in seconds.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    nvim = resolve_nvim_binary(args.nvim_bin)
    env = build_env()
    result = run_nvim(repo_root, nvim, ["+ClarityAudit!"], env, timeout=args.timeout)

    if result.returncode != 0:
        sys.stderr.write(result.stderr or result.stdout)
        return result.returncode

    report = extract_last_json_object(combined_output(result))

    print(json.dumps(report, indent=2, ensure_ascii=False))
    if args.json:
        return 0 if report.get("ok") else 1

    core = report["summary"]["core"]
    print(f"Core readiness: {core['status']} ({core['passed']}/{core['total']})")
    print(f"Host capability: {report['summary']['host']['status']}")
    print(f"Release quality: {report['summary']['release']['status']}")
    print(
        "Profiles: "
        + ", ".join(
            f"{name}={profile['status']}" for name, profile in sorted(report["summary"]["profiles"].items())
        )
    )

    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
