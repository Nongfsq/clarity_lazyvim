from __future__ import annotations

import json
import os
from pathlib import Path

from clarity_runtime import build_env, configure_isolated_runtime


def run() -> int:
    runner_temp = os.environ.get("RUNNER_TEMP")
    github_env = os.environ.get("GITHUB_ENV")
    if not runner_temp or not github_env:
        raise RuntimeError("RUNNER_TEMP and GITHUB_ENV are required in GitHub Actions")

    runtime_root = Path(runner_temp) / "clarity-runtime"
    env = configure_isolated_runtime(build_env(), runtime_root)
    exported = {
        "CLARITY_RUNTIME_ROOT": str(runtime_root),
        "CLARITY_NONINTERACTIVE": "1",
        **{key: value for key, value in env.items() if key.startswith("XDG_")},
    }
    with Path(github_env).open("a", encoding="utf-8") as handle:
        for key, value in exported.items():
            handle.write(f"{key}={value}\n")

    print(json.dumps({"check_id": "CLARITY-ISOLATION-001", "paths": exported}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
