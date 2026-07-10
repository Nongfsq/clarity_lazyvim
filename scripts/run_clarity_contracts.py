from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

from clarity_runtime import (
    build_env,
    combined_output,
    configure_isolated_runtime,
    extract_last_json_object,
    resolve_nvim_binary,
    run_command,
    sha256_file,
)
from run_clarity_smoke import copy_candidate, copy_plugin_cache


AUTHORITY_FILES = ("lazy-lock.json", "lazyvim.json")
FAULT_MISSING_NESTED_RUNTIME = "missing_nested_runtime"
FAULT_RAW_FOLD_ACTION = "raw_fold_action"


def lua_string(value: str | Path) -> str:
    return json.dumps(str(value))


def discover_config_modules(repo_root: Path) -> set[str]:
    config_root = repo_root / "nvim" / "lua" / "config"
    return {
        "config." + ".".join(path.relative_to(config_root).with_suffix("").parts)
        for path in config_root.rglob("*.lua")
    }


def discover_task_ids(repo_root: Path) -> set[str]:
    pattern = re.compile(r"^### ([A-Z][A-Z0-9_-]*-[0-9]{3})(?::|\s)")
    task_ids: set[str] = set()
    for path in (repo_root / "progress").glob("*.md"):
        for line in path.read_text(encoding="utf-8").splitlines():
            match = pattern.match(line)
            if match:
                task_ids.add(match.group(1))
    return task_ids


def load_catalog(repo_root: Path, nvim_bin: str, timeout: float = 30) -> dict[str, Any]:
    path = repo_root / "tests" / "contracts" / "runtime_contract.lua"
    command = [
        nvim_bin,
        "--clean",
        "--headless",
        "-u",
        "NONE",
        "+lua print(vim.json.encode(dofile(" + lua_string(path) + ")))",
        "+qall",
    ]
    result = run_command(command, cwd=repo_root, env=build_env(), timeout=timeout)
    if result.returncode != 0:
        raise RuntimeError("Could not load runtime contract catalog:\n" + combined_output(result))
    return extract_last_json_object(combined_output(result))


def catalog_issues(catalog: dict[str, Any], module_names: set[str], task_ids: set[str]) -> list[dict[str, str]]:
    issues: list[dict[str, str]] = []
    classified = set(catalog.get("modules", {}))
    for module in sorted(module_names - classified):
        issues.append({"id": "CLARITY_CONTRACT_UNCLASSIFIED_MODULE", "detail": module})
    for module in sorted(classified - module_names):
        issues.append({"id": "CLARITY_CONTRACT_MISSING_MODULE", "detail": module})

    valid_coverage = {"covered", "planned", "inherited"}
    for capability_id, capability in sorted(catalog.get("capabilities", {}).items()):
        coverage = capability.get("coverage")
        if coverage not in valid_coverage:
            issues.append(
                {"id": "CLARITY_CONTRACT_INVALID_COVERAGE", "detail": f"{capability_id}:{coverage}"}
            )
        if not capability.get("owner"):
            issues.append({"id": "CLARITY_CONTRACT_MISSING_OWNER", "detail": capability_id})
        if coverage == "planned" and capability.get("task") not in task_ids:
            issues.append(
                {
                    "id": "CLARITY_CONTRACT_INVALID_PLANNED_TASK",
                    "detail": f"{capability_id}:{capability.get('task')}",
                }
            )
    return issues


def authority_hashes(repo_root: Path) -> dict[str, str]:
    return {name: sha256_file(repo_root / name) for name in AUTHORITY_FILES}


def hash_drift(before: dict[str, str], after: dict[str, str]) -> dict[str, dict[str, str]]:
    return {
        name: {"before": before[name], "after": after[name]}
        for name in before
        if before[name] != after[name]
    }


def apply_fault(candidate_root: Path, fault: str | None) -> None:
    if fault is None:
        return
    if fault == FAULT_RAW_FOLD_ACTION:
        keymaps_path = candidate_root / "nvim" / "lua" / "config" / "keymaps.lua"
        keymaps_source = keymaps_path.read_text(encoding="utf-8")
        old = 'map("n", "<leader>cz", require("config.actions.fold").toggle, opts)'
        new = 'map("n", "<leader>cz", function()\n    vim.cmd("normal! za")\nend, opts) -- fault: raw fold action'
        if old not in keymaps_source:
            raise RuntimeError("Fault fixture could not locate the typed fold action mapping.")
        keymaps_path.write_text(keymaps_source.replace(old, new, 1), encoding="utf-8")
        return
    if fault != FAULT_MISSING_NESTED_RUNTIME:
        raise ValueError(f"Unknown fault: {fault}")

    lazy_path = candidate_root / "nvim" / "lua" / "config" / "lazy.lua"
    lazy_source = lazy_path.read_text(encoding="utf-8")
    old = "paths = vim.list_extend({ vim.g.clarity_nvim_dir }, bundled_runtime_paths()),"
    new = "paths = bundled_runtime_paths(), -- fault: nested runtime removed"
    if old not in lazy_source:
        raise RuntimeError("Fault fixture could not locate the nested runtime performance path.")
    lazy_path.write_text(lazy_source.replace(old, new, 1), encoding="utf-8")

    init_path = candidate_root / "nvim" / "init.lua"
    init_source = init_path.read_text(encoding="utf-8")
    old = "    vim.opt.rtp:append(nvim_dir)"
    new = "    -- fault: do not restore the nested runtime before UIEnter"
    if old not in init_source:
        raise RuntimeError("Fault fixture could not locate the post-setup nested runtime path.")
    init_path.write_text(init_source.replace(old, new, 1), encoding="utf-8")


def build_headless_command(
    candidate_root: Path,
    nvim_bin: str,
    scenario: str,
    wait_ms: int,
) -> list[str]:
    probe = candidate_root / "tests" / "lua" / "runtime_probe.lua"
    observe = "lua dofile(" + lua_string(probe) + ").observe()"
    emit = (
        "+lua local p=dofile("
        + lua_string(probe)
        + "); local ready=vim.wait("
        + str(wait_ms)
        + ", function() return p.ready("
        + lua_string(scenario)
        + ") end, 20); local report=p.snapshot("
        + lua_string(scenario)
        + "); report.ready=ready; print(vim.json.encode(report))"
    )
    args = [str(candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua")] if scenario == "file_headless" else []
    return [
        nvim_bin,
        "--headless",
        "--cmd",
        observe,
        "-u",
        str(candidate_root / "init.lua"),
        *args,
        emit,
        "+qall",
    ]


@contextmanager
def process_context(cwd: Path, env: dict[str, str]) -> Iterator[None]:
    original_cwd = Path.cwd()
    original_env = dict(os.environ)
    try:
        os.chdir(cwd)
        os.environ.clear()
        os.environ.update(env)
        yield
    finally:
        os.environ.clear()
        os.environ.update(original_env)
        os.chdir(original_cwd)


def attached_ui_behavior_setup_lua() -> str:
    return r'''
local results = {}
local wrap_map = vim.fn.maparg('<leader>uw', 'n', false, true)
local fold_map = vim.fn.maparg('<leader>cz', 'n', false, true)
results.wrap_callback = type(wrap_map.callback) == 'function'
results.fold_callback = type(fold_map.callback) == 'function'

local original_buf = vim.api.nvim_get_current_buf()
local original_wrap = vim.wo.wrap
if results.wrap_callback then
  wrap_map.callback()
  results.wrap_changed = vim.wo.wrap ~= original_wrap
  wrap_map.callback()
  results.wrap_restored = vim.wo.wrap == original_wrap
end

local original_foldmethod = vim.wo.foldmethod
local original_foldenable = vim.wo.foldenable
local original_foldlevel = vim.wo.foldlevel
local scratch = vim.api.nvim_create_buf(false, false)
vim.api.nvim_win_set_buf(0, scratch)
vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { 'if true then', '  print(1)', 'end', 'print(2)' })
vim.wo.foldmethod = 'manual'
vim.wo.foldenable = true
vim.wo.foldlevel = 0
vim.cmd('1,3fold')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
results.fold_initially_closed = vim.fn.foldclosed(1) == 1
_G.ClarityAttachedBehavior = {
  original_buf = original_buf,
  original_foldmethod = original_foldmethod,
  original_foldenable = original_foldenable,
  original_foldlevel = original_foldlevel,
  scratch = scratch,
}
return results
'''


def attached_ui_fold_state_lua() -> str:
    return r'''
local events = require('config.diagnostics').events()
local event = events[#events]
return {
  closed = vim.fn.foldclosed(1),
  errmsg = vim.v.errmsg,
  event_id = event and event.event_id or nil,
  outcome = event and event.outcome or nil,
  event_count = #events,
  messages = vim.api.nvim_exec2('messages', { output = true }).output,
}
'''


def attached_ui_behavior_cleanup_lua() -> str:
    return r'''
local state = _G.ClarityAttachedBehavior
if not state then return false end
vim.api.nvim_win_set_buf(0, state.original_buf)
vim.wo.foldmethod = state.original_foldmethod
vim.wo.foldenable = state.original_foldenable
vim.wo.foldlevel = state.original_foldlevel
if vim.api.nvim_buf_is_valid(state.scratch) then
  vim.api.nvim_buf_delete(state.scratch, { force = true })
end
_G.ClarityAttachedBehavior = nil
return true
'''


def run_attached_ui(
    candidate_root: Path,
    nvim_bin: str,
    env: dict[str, str],
    wait_ms: int,
) -> tuple[dict[str, Any], dict[str, Any]]:
    try:
        import pynvim
    except ImportError as exc:
        raise RuntimeError(
            "file_ui requires pynvim. Run with: uv run --with pynvim python scripts/run_clarity_contracts.py ..."
        ) from exc

    probe = candidate_root / "tests" / "lua" / "runtime_probe.lua"
    observe = "lua dofile(" + lua_string(probe) + ").observe()"
    argv = [
        nvim_bin,
        "--embed",
        "--cmd",
        observe,
        "-u",
        str(candidate_root / "init.lua"),
        str(candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua"),
    ]
    with process_context(candidate_root, env):
        nvim = pynvim.attach("child", argv=argv)
    try:
        nvim.ui_attach(80, 24, rgb=True)
        ready = nvim.exec_lua(
            "local path, wait_ms = ...; local p=dofile(path); "
            "return vim.wait(wait_ms, function() return p.ready('file_ui') end, 20)",
            str(probe),
            wait_ms,
        )
        snapshot = nvim.exec_lua("return dofile(...).snapshot('file_ui')", str(probe))
        snapshot["ready"] = ready
        behavior = nvim.exec_lua(attached_ui_behavior_setup_lua())
        messages_before = nvim.exec_lua("return vim.api.nvim_exec2('messages', { output = true }).output")

        def input_fold(expected_closed: int | None, before_events: int) -> tuple[bool, str | None]:
            try:
                nvim.input(" cz")
                settled = nvim.exec_lua(
                    "local expected, before = ...; return vim.wait(500, function() "
                    "local count = #require('config.diagnostics').events(); "
                    "return (expected ~= nil and vim.fn.foldclosed(1) == expected) or count > before end, 20)",
                    expected_closed,
                    before_events,
                )
                return bool(settled), None
            except Exception as exc:  # pynvim surfaces mapping errors as RPC failures on the next request
                return False, str(exc)

        before = nvim.exec_lua(attached_ui_fold_state_lua())
        open_ok, open_error = input_fold(-1, before["event_count"])
        opened = nvim.exec_lua(attached_ui_fold_state_lua())
        close_ok, close_error = input_fold(1, opened["event_count"])
        reclosed = nvim.exec_lua(attached_ui_fold_state_lua())
        nvim.exec_lua("vim.cmd('normal! zE'); vim.v.errmsg = ''")
        no_fold_ok, no_fold_rpc_error = input_fold(None, reclosed["event_count"])
        no_fold = nvim.exec_lua(attached_ui_fold_state_lua())
        behavior.update(
            {
                "fold_input": True,
                "fold_open_input_ok": open_ok,
                "fold_open_rpc_error": open_error,
                "fold_opened": opened["closed"] == -1,
                "fold_open_outcome": opened.get("outcome"),
                "fold_close_input_ok": close_ok,
                "fold_close_rpc_error": close_error,
                "fold_reclosed": reclosed["closed"] == 1,
                "fold_close_outcome": reclosed.get("outcome"),
                "fold_no_fold_ok": no_fold_ok,
                "fold_no_fold_rpc_error": no_fold_rpc_error,
                "fold_no_fold_outcome": no_fold.get("outcome"),
                "fold_no_fold_event_id": no_fold.get("event_id"),
                "fold_no_fold_error": no_fold.get("errmsg", ""),
                "fold_messages_delta": no_fold.get("messages", "")[len(messages_before) :],
                "fold_cleanup": nvim.exec_lua(attached_ui_behavior_cleanup_lua()),
            }
        )
        original_buffer = nvim.exec_lua("return vim.api.nvim_get_current_buf()")
        nvim.ui_try_resize(60, 16)
        nvim.command("ClarityLog")
        log_small = nvim.exec_lua(
            "local b=vim.api.nvim_get_current_buf(); return {"
            "name=vim.api.nvim_buf_get_name(b), readonly=vim.bo[b].readonly, "
            "modifiable=vim.bo[b].modifiable, lines=vim.api.nvim_buf_line_count(b)}"
        )
        nvim.ui_try_resize(80, 24)
        nvim.command("ClarityLog tail")
        log_tail = nvim.exec_lua(
            "local b=vim.api.nvim_get_current_buf(); return {"
            "line=vim.api.nvim_win_get_cursor(0)[1], lines=vim.api.nvim_buf_line_count(b)}"
        )
        behavior.update(
            {
                "log_small_ui": log_small.get("name") == "clarity://log" and log_small.get("lines", 0) > 0,
                "log_readonly": log_small.get("readonly") is True and log_small.get("modifiable") is False,
                "log_tail": log_tail.get("line") == log_tail.get("lines"),
                "log_cleanup": nvim.exec_lua(
                    "local b=...; if vim.api.nvim_buf_is_valid(b) then "
                    "vim.api.nvim_win_set_buf(0,b); return true end; return false",
                    original_buffer,
                ),
            }
        )
        return snapshot, behavior
    finally:
        try:
            nvim.exec_lua("vim.defer_fn(function() vim.cmd('qall!') end, 10)")
            try:
                nvim.run_loop(lambda _name, _args: None, lambda _name, _args: None)
            except EOFError:
                pass
        finally:
            nvim.close()


def _result(
    check: dict[str, Any],
    scenario: str,
    ok: bool,
    actual: Any,
    phase: str | None = None,
) -> dict[str, Any]:
    return {
        "id": check["id"],
        "scenario": scenario,
        "phase": phase,
        "owner": check["owner"],
        "expected": check["expected"],
        "actual": actual,
        "ok": ok,
        "severity": "required",
        "repair": check["repair"],
        "evidence_source": "runtime_probe",
    }


def evaluate_snapshot(
    catalog: dict[str, Any],
    snapshot: dict[str, Any],
    behavior: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    scenario = snapshot["scenario"]
    results: list[dict[str, Any]] = []
    modules = snapshot.get("modules", {})
    for check in catalog["checks"]:
        if scenario not in check["scenarios"]:
            continue
        kind = check["kind"]
        phase = None
        if kind == "module_phase":
            module = modules.get(check["module"], {})
            phase = module.get("first_seen")
            actual = {"loaded": module.get("loaded", False), "first_seen": phase}
            ok = actual["loaded"] and phase == check["expected"]
        elif kind == "autocmds_contract":
            module = modules.get(check["module"], {})
            phase = module.get("first_seen")
            count = snapshot.get("autocmds", {}).get("absolute_line_numbers", 0)
            actual = {"loaded": module.get("loaded", False), "first_seen": phase, "owned_autocmds": count}
            ok = actual["loaded"] and phase == "User:LazyVimAutocmds" and count >= 4
        elif kind == "editing_defaults":
            options = snapshot.get("options", {})
            actual = {name: options.get(name) for name in ("number", "relativenumber", "wrap", "linebreak", "breakindent")}
            ok = actual == {
                "number": True,
                "relativenumber": False,
                "wrap": True,
                "linebreak": True,
                "breakindent": True,
            }
        elif kind == "keymap_contract":
            module = modules.get(check["module"], {})
            phase = module.get("first_seen")
            maps = snapshot.get("maps", {})
            sources = [maps.get(name, {}).get("source") for name in ("leader_uw", "leader_cz")]
            normalized_sources = [str(source).replace("\\", "/") for source in sources]
            owner_ok = bool(sources[0] and sources[1]) and normalized_sources[0].endswith(
                "/nvim/lua/config/keymaps.lua"
            ) and normalized_sources[1].endswith("/nvim/lua/config/actions/fold.lua")
            behavior = behavior or {}
            behavior_ok = (
                all(
                    behavior.get(name) is True
                    for name in (
                        "wrap_callback",
                        "fold_callback",
                        "fold_input",
                        "fold_open_input_ok",
                        "wrap_changed",
                        "wrap_restored",
                        "fold_initially_closed",
                        "fold_opened",
                        "fold_close_input_ok",
                        "fold_reclosed",
                        "fold_no_fold_ok",
                        "fold_cleanup",
                        "log_small_ui",
                        "log_readonly",
                        "log_tail",
                        "log_cleanup",
                    )
                )
                and behavior.get("fold_open_outcome") == "toggled"
                and behavior.get("fold_close_outcome") == "toggled"
                and behavior.get("fold_no_fold_outcome") == "no_fold"
                and behavior.get("fold_no_fold_event_id") == "CLARITY_FOLD_NO_FOLD"
                and behavior.get("fold_no_fold_error") == ""
            )
            actual = {
                "loaded": module.get("loaded", False),
                "first_seen": phase,
                "sources": sources,
                "behavior": behavior,
            }
            ok = actual["loaded"] and phase == "User:LazyVimKeymaps" and owner_ok and behavior_ok
        elif kind == "modules_loaded":
            actual = {name: modules.get(name, {}).get("loaded", False) for name in check["modules"]}
            ok = all(actual.values())
        else:
            actual = f"unsupported check kind: {kind}"
            ok = False
        results.append(_result(check, scenario, ok, actual, phase))
    return results


def coverage_summary(catalog: dict[str, Any], repo_root: Path) -> dict[str, Any]:
    modules = set(catalog.get("modules", {}))
    discovered = discover_config_modules(repo_root)
    counts: dict[str, int] = {}
    for capability in catalog.get("capabilities", {}).values():
        coverage = capability["coverage"]
        counts[coverage] = counts.get(coverage, 0) + 1
    return {
        "modules": {
            "classified": len(modules & discovered),
            "unclassified": sorted(discovered - modules),
            "missing": sorted(modules - discovered),
        },
        "capabilities": counts,
    }


def run_scenario(
    source_root: Path,
    catalog: dict[str, Any],
    scenario: str,
    nvim_bin: str,
    timeout: float,
    plugin_cache: Path | None,
    fault: str | None,
) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix=f"clarity-contract-{scenario}-") as directory:
        scenario_root = Path(directory)
        candidate_root = scenario_root / "candidate"
        runtime_root = scenario_root / "runtime"
        copy_candidate(source_root, candidate_root)
        apply_fault(candidate_root, fault)
        before = authority_hashes(candidate_root)
        env = configure_isolated_runtime(build_env(), runtime_root)
        env["CLARITY_CONTRACT_CATALOG"] = str(candidate_root / "tests" / "contracts" / "runtime_contract.lua")
        env["CLARITY_CONTRACT_SCENARIO"] = scenario
        if plugin_cache:
            copy_plugin_cache(plugin_cache, runtime_root)

        behavior = None
        if scenario == "file_ui":
            snapshot, behavior = run_attached_ui(candidate_root, nvim_bin, env, min(int(timeout * 1000), 5000))
        else:
            command = build_headless_command(candidate_root, nvim_bin, scenario, min(int(timeout * 1000), 5000))
            result = run_command(command, cwd=candidate_root, env=env, timeout=timeout)
            if result.returncode != 0:
                raise RuntimeError(f"{scenario} failed with exit {result.returncode}:\n{combined_output(result)}")
            snapshot = extract_last_json_object(combined_output(result))

        after = authority_hashes(candidate_root)
        results = evaluate_snapshot(catalog, snapshot, behavior)
        expected_paths = {
            "repo": str(candidate_root.resolve()).replace("\\", "/"),
            "lock": str((candidate_root / "lazy-lock.json").resolve()).replace("\\", "/"),
            "json": str((candidate_root / "lazyvim.json").resolve()).replace("\\", "/"),
        }
        actual_paths = {key: str(snapshot["paths"].get(key)).replace("\\", "/") for key in expected_paths}
        results.extend(
            [
                {
                    "id": "CLARITY_RUNTIME_AUTHORITY_PATHS",
                    "scenario": scenario,
                    "phase": None,
                    "owner": "root bootstrap",
                    "expected": expected_paths,
                    "actual": actual_paths,
                    "ok": actual_paths == expected_paths,
                    "severity": "required",
                    "repair": "Restore explicit repository root lock and LazyVim JSON paths.",
                    "evidence_source": "runtime_probe",
                },
                {
                    "id": "CLARITY_RUNTIME_AUTHORITY_IMMUTABLE",
                    "scenario": scenario,
                    "phase": None,
                    "owner": "scenario runner",
                    "expected": before,
                    "actual": after,
                    "ok": before == after,
                    "severity": "required",
                    "repair": "Move generated updates to an explicit transaction and keep startup read-only.",
                    "evidence_source": "sha256",
                },
            ]
        )
        return {
            "scenario": scenario,
            "fault": fault,
            "snapshot": snapshot,
            "behavior": behavior,
            "hashes": {"before": before, "after": after},
            "checks": results,
        }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Clarity natural-lifecycle runtime contracts.")
    parser.add_argument(
        "--scenario",
        action="append",
        choices=("empty_headless", "file_headless", "file_ui"),
        help="Scenario to run; repeatable. Defaults to empty_headless and file_headless.",
    )
    parser.add_argument("--fault", choices=(FAULT_MISSING_NESTED_RUNTIME, FAULT_RAW_FOLD_ACTION))
    parser.add_argument("--expect-failure-id", action="append", default=[])
    parser.add_argument("--reuse-plugin-cache", type=Path)
    parser.add_argument("--nvim-bin")
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--json", action="store_true", help="Retained for command compatibility; output is JSON.")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    nvim = resolve_nvim_binary(args.nvim_bin)
    catalog = load_catalog(source_root, nvim)
    issues = catalog_issues(catalog, discover_config_modules(source_root), discover_task_ids(source_root))
    if issues:
        print(json.dumps({"status": "fail", "catalog_issues": issues}, indent=2, ensure_ascii=False))
        return 1

    scenarios = args.scenario or ["empty_headless", "file_headless"]
    source_before = authority_hashes(source_root)
    reports = [
        run_scenario(
            source_root,
            catalog,
            scenario,
            nvim,
            args.timeout,
            args.reuse_plugin_cache.resolve() if args.reuse_plugin_cache else None,
            args.fault,
        )
        for scenario in scenarios
    ]
    source_after = authority_hashes(source_root)
    all_checks = [check for report in reports for check in report["checks"]]
    if source_before != source_after:
        all_checks.append(
            {
                "id": "CLARITY_RUNTIME_SOURCE_IMMUTABLE",
                "scenario": "source",
                "phase": None,
                "owner": "scenario runner",
                "expected": source_before,
                "actual": source_after,
                "ok": False,
                "severity": "required",
                "repair": "Never run contract scenarios against source authority files.",
                "evidence_source": "sha256",
            }
        )

    actual_failures = sorted({check["id"] for check in all_checks if not check["ok"]})
    expected_failures = sorted(set(args.expect_failure_id))
    expectation_ok = bool(expected_failures) and actual_failures == expected_failures
    status = "expected_failure" if expectation_ok else ("pass" if not actual_failures else "fail")
    report = {
        "schema_version": 1,
        "status": status,
        "fault": args.fault,
        "scenarios": reports,
        "coverage": coverage_summary(catalog, source_root),
        "failure_ids": actual_failures,
        "expected_failure_ids": expected_failures,
        "source_hashes": {"before": source_before, "after": source_after},
    }
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if status in {"pass", "expected_failure"} else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1) from exc
