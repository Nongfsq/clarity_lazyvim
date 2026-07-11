from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

from clarity_runtime import (
    build_env,
    combined_output,
    extract_last_json_object,
    resolve_nvim_binary,
    run_command,
    run_nvim,
)


@dataclass
class CheckResult:
    name: str
    ok: bool
    details: str
    required: bool = True

    @property
    def id(self) -> str:
        normalized = re.sub(r"[^A-Z0-9]+", "_", self.name.upper()).strip("_")
        return "CLARITY_VALIDATE_" + normalized


DELEGATED_CHECKS = {
    "CLARITY_VALIDATE_KEYMAP_LEADER_FF_EXISTS": "CLARITY_RUNTIME_PICKER_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_FW_EXISTS": "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_CZ_EXISTS": "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_UW_EXISTS": "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_TF_EXISTS": "CLARITY_RUNTIME_TERMINAL_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_HH_EXISTS": "CLARITY_RUNTIME_HELP_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_GD_EXISTS": "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    "CLARITY_VALIDATE_KEYMAP_LEADER_HS_EXISTS": "CLARITY_RUNTIME_GITSIGNS_CONTRACT",
    "CLARITY_VALIDATE_NEOTREE_OPENS_IN_HEADLESS_RUNTIME": "CLARITY_RUNTIME_EXPLORER_CONTRACT",
    "CLARITY_VALIDATE_NEOTREE_WINDOW_DISCOVERED": "CLARITY_RUNTIME_EXPLORER_CONTRACT",
    "CLARITY_VALIDATE_NEOTREE_WINDOW_HIDES_LINE_NUMBERS": "CLARITY_RUNTIME_EXPLORER_CONTRACT",
    "CLARITY_VALIDATE_LINE_WRAP_MAPPING_CHANGES_AND_RESTORES_THE_WINDOW_OPTION": "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    "CLARITY_VALIDATE_CODE_FOLD_MAPPING_OPENS_AND_RECLOSES_THE_CURRENT_FOLD": "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    "CLARITY_VALIDATE_DASHBOARD_HIDES_ABSOLUTE_LINE_NUMBERS": "CLARITY_RUNTIME_UI_CONTRACT",
}


def run_doctor_json(repo_root: Path, env: dict[str, str]) -> dict:
    result = run_command(
        [sys.executable, str(repo_root / "scripts" / "clarity_doctor.py"), "--json"],
        cwd=repo_root,
        env=env,
        timeout=120,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError((result.stderr or result.stdout).strip() or "doctor command failed")
    return json.loads(result.stdout)


def resolve_executable(name: str) -> str | None:
    return shutil.which(name)


def _report_command(
    repo_root: Path, nvim_bin: str, env: dict[str, str], command: str
) -> tuple[dict, str | None]:
    result = run_nvim(repo_root, nvim_bin, [f"+{command}!"], env)
    output = combined_output(result)
    if result.returncode != 0:
        return {}, output or "command failed"
    try:
        return extract_last_json_object(output), None
    except Exception as exc:
        return {}, str(exc)


def run(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Collect passive Clarity readiness checks; behavior is verified by runtime contracts."
    )
    parser.add_argument("--json", action="store_true", help="Emit a machine-readable validation report.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    args = parser.parse_args(argv)

    repo_root = Path(__file__).resolve().parent.parent
    env = build_env()
    nvim_bin = resolve_nvim_binary(args.nvim_bin)
    checks: list[CheckResult] = []

    startup = run_nvim(repo_root, nvim_bin, [], env)
    checks.append(
        CheckResult(
            "Headless startup",
            startup.returncode == 0,
            (startup.stderr or startup.stdout).strip() or "ok",
        )
    )

    audit_report, audit_error = _report_command(repo_root, nvim_bin, env, "ClarityAudit")
    core = audit_report.get("summary", {}).get("core", {})
    checks.append(CheckResult("ClarityAudit command", audit_error is None, audit_error or f"core={core.get('status')}"))
    checks.append(
        CheckResult(
            "Required tools present",
            bool(core.get("total")) and core.get("passed") == core.get("total"),
            f"{core.get('passed', 0)}/{core.get('total', 0)}",
        )
    )

    validation_report, validation_error = _report_command(repo_root, nvim_bin, env, "ClarityValidate")
    validation_summary = validation_report.get("summary", {})
    checks.append(
        CheckResult(
            "ClarityValidate command",
            validation_error is None,
            validation_error or f"passed={validation_summary.get('passed', 0)}/{validation_summary.get('total', 0)}",
        )
    )
    checks.append(
        CheckResult(
            "Passive editor contracts",
            validation_error is None and validation_summary.get("failed", 1) == 0,
            f"failed={validation_summary.get('failed', 0)}",
        )
    )

    try:
        doctor = run_doctor_json(repo_root, env)
        doctor_checks = {item.get("id"): item for item in doctor.get("checks", [])}
        for name, check_id, required in (
            ("Tree-sitter vim parser health", "vim_treesitter_parser", True),
            ("User-level stale vim parser override absent", "user_vim_parser_override", True),
            ("Tree-sitter CLI available for diagnostics", "tree_sitter_cli", False),
        ):
            item = doctor_checks.get(check_id, {})
            accepted = {"pass"} if check_id != "user_vim_parser_override" else {"pass", "warn"}
            checks.append(CheckResult(name, item.get("status") in accepted, item.get("details", "missing"), required))
    except Exception as exc:
        checks.append(CheckResult("Clarity doctor command", False, str(exc)))

    required_failures = [check for check in checks if check.required and not check.ok]
    optional_failures = [check for check in checks if not check.required and not check.ok]
    payload = {
        "check_id": "CLARITY-VALIDATE-001",
        "status": "fail" if required_failures else "pass",
        "collection": "passive",
        "summary": {
            "required_failures": len(required_failures),
            "optional_warnings": len(optional_failures),
            "total": len(checks),
        },
        "checks": [{"id": check.id, **asdict(check)} for check in checks],
        "delegated_checks": DELEGATED_CHECKS,
    }

    if args.json:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        print("Clarity Passive Validation")
        for check in checks:
            marker = "PASS" if check.ok else ("WARN" if not check.required else "FAIL")
            print(f"[{marker}] {check.id}: {check.name} -> {check.details}")
        print(f"Required failures: {len(required_failures)}")
        print(f"Optional warnings: {len(optional_failures)}")
        print("Behavior checks delegated to runtime contracts: " + str(len(DELEGATED_CHECKS)))

    return 1 if required_failures else 0


if __name__ == "__main__":
    raise SystemExit(run())
