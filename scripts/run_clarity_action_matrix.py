from __future__ import annotations

import argparse
import json
import os
import shutil
import tempfile
import time
from pathlib import Path
from typing import Any

from clarity_runtime import (
    build_env,
    configure_isolated_runtime,
    require_pynvim,
    resolve_nvim_binary,
)
from run_clarity_contracts import (
    authority_hashes,
    prepare_attached_context_fixture,
    process_context,
    repository_snapshot,
)
from run_clarity_smoke import copy_candidate, copy_plugin_cache


def default_plugin_cache() -> Path | None:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    candidate = data_home / "nvim" / "lazy"
    return candidate if candidate.is_dir() else None


def isolate_action_matrix_environment(
    env: dict[str, str],
    runtime_root: Path,
    *,
    windows: bool | None = None,
) -> dict[str, str]:
    """Remove user shell, home, and Git-hook influence from interactive actions."""

    isolated = dict(env)
    for name in tuple(isolated):
        if name.startswith("GIT_"):
            isolated.pop(name)
    home = runtime_root / "home"
    hooks = runtime_root / "git-hooks"
    home.mkdir(parents=True, exist_ok=True)
    hooks.mkdir(parents=True, exist_ok=True)
    empty_shell_init = runtime_root / "empty-shell-init"
    empty_git_config = runtime_root / "empty-gitconfig"
    empty_shell_init.touch()
    empty_git_config.touch()

    is_windows = os.name == "nt" if windows is None else windows
    if is_windows:
        shell = isolated.get("COMSPEC") or shutil.which("cmd.exe", path=isolated.get("PATH")) or "cmd.exe"
        isolated["COMSPEC"] = shell
    else:
        shell = shutil.which("sh", path=isolated.get("PATH")) or "/bin/sh"

    isolated.update(
        {
            "HOME": str(home),
            "USERPROFILE": str(home),
            "ZDOTDIR": str(home),
            "SHELL": shell,
            "ENV": str(empty_shell_init),
            "BASH_ENV": str(empty_shell_init),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": str(empty_git_config),
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.hooksPath",
            "GIT_CONFIG_VALUE_0": str(hooks),
            "GIT_TERMINAL_PROMPT": "0",
            "GCM_INTERACTIVE": "Never",
        }
    )
    return isolated


def observed_startup_command(probe: Path) -> str:
    quoted = json.dumps(str(probe))
    return (
        "lua _G.ClarityActionMatrixStartupErrors={}; "
        f"local ok,err=pcall(function() dofile({quoted}).observe() end); "
        "if not ok then table.insert(_G.ClarityActionMatrixStartupErrors, tostring(err)) end"
    )


def configure_action_matrix_environment(candidate_root: Path, runtime_root: Path) -> dict[str, str]:
    env = configure_isolated_runtime(build_env(), runtime_root)
    env = isolate_action_matrix_environment(env, runtime_root)
    env["CLARITY_CONTRACT_CATALOG"] = str(
        candidate_root / "tests" / "contracts" / "runtime_contract.lua"
    )
    env["CLARITY_ACTION_MATRIX_RUNTIME_ROOT"] = str(runtime_root)
    return env


def startup_evidence(nvim: Any, probe: Path, wait_ms: int) -> dict[str, Any]:
    evidence = nvim.exec_lua(
        "local path, timeout = ...; local errors = _G.ClarityActionMatrixStartupErrors or {}; "
        "local observer = type(_G.ClarityContractObserver) == 'table'; "
        "local ready = observer and vim.wait(timeout, function() return dofile(path).ready('file_ui') end, 20) "
        "or false; local errmsg = vim.v.errmsg or ''; "
        "return { errors=errors, observer_installed=observer, runtime_ready=ready, errmsg=errmsg, "
        "clean=observer and ready and #errors == 0 and errmsg == '' }",
        str(probe),
        wait_ms,
    )
    return dict(evidence)


def fixture_path_leak_count(value: Any, roots: tuple[Path, ...]) -> int:
    normalized_roots = tuple(
        sorted(
            {
                path.replace("\\", "/")
                for root in roots
                for path in (str(root.absolute()), str(root.resolve()))
            }
        )
    )

    def strings(item: Any):
        if isinstance(item, str):
            yield item
        elif isinstance(item, dict):
            for key, child in item.items():
                yield from strings(key)
                yield from strings(child)
        elif isinstance(item, (list, tuple)):
            for child in item:
                yield from strings(child)

    return sum(
        1
        for item in strings(value)
        if any(root in item.replace("\\", "/") for root in normalized_roots)
    )


def redact_report_paths(
    value: Any,
    roots: tuple[tuple[Path, str], ...],
) -> tuple[Any, int]:
    replacements: list[tuple[str, str]] = []
    for root, marker in roots:
        for path in {str(root.absolute()), str(root.resolve())}:
            replacements.append((path, marker))
            replacements.append((path.replace("\\", "/"), marker))
            replacements.append((path.replace("/", "\\"), marker))
    replacements.sort(key=lambda item: len(item[0]), reverse=True)

    count = 0

    def redact(item: Any) -> Any:
        nonlocal count
        if isinstance(item, str):
            result = item
            for path, marker in replacements:
                occurrences = result.count(path)
                if occurrences:
                    count += occurrences
                    result = result.replace(path, marker)
            return result
        if isinstance(item, dict):
            return {redact(key): redact(child) for key, child in item.items()}
        if isinstance(item, list):
            return [redact(child) for child in item]
        if isinstance(item, tuple):
            return tuple(redact(child) for child in item)
        return item

    return redact(value), count


def fake_lsp_processes_exited(log_path: Path, timeout: float = 2.0) -> tuple[bool, int]:
    pids: set[int] = set()
    if log_path.is_file():
        for line in log_path.read_text(encoding="utf-8").splitlines():
            try:
                pid = json.loads(line).get("_server_pid")
            except json.JSONDecodeError:
                continue
            if isinstance(pid, int):
                pids.add(pid)

    def alive(pid: int) -> bool:
        try:
            os.kill(pid, 0)
        except OSError:
            return False
        return True

    deadline = time.monotonic() + timeout
    while pids and time.monotonic() < deadline:
        if not any(alive(pid) for pid in pids):
            return True, len(pids)
        time.sleep(0.05)
    return bool(pids) and not any(alive(pid) for pid in pids), len(pids)


def run_interactive_help(nvim: Any, timeout: float = 3.0) -> dict[str, Any]:
    setup = nvim.exec_lua(
        "require('lazy').load({plugins={'which-key.nvim'}}); local wk=require('which-key'); "
        "_G.ClarityActionMatrixHelp={original=wk.show}; "
        "wk.show=function(opts) _G.ClarityActionMatrixHelp.opts=vim.deepcopy(opts or {}); "
        "return _G.ClarityActionMatrixHelp.original(opts) end; "
        "local map=vim.fn.maparg('<leader>?','n',false,true); "
        "return {mapped=type(map)=='table' and not vim.tbl_isempty(map), leader=vim.g.mapleader or '\\\\'}"
    )
    opened = False
    global_only: bool | None = None
    closed = False
    input_error = ""
    try:
        nvim.input(str(setup["leader"]) + "?")
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            state = nvim.exec_lua(
                "local h=_G.ClarityActionMatrixHelp or {}; local view=require('which-key.view'); "
                "return {called=h.opts ~= nil, global_is_false=h.opts ~= nil and h.opts.global == false, "
                "view_valid=view.valid()}"
            )
            if state.get("called") and state.get("view_valid"):
                opened = True
                global_only = False if state.get("global_is_false") else None
                break
            time.sleep(0.05)
    except Exception as exc:
        input_error = str(exc)
    finally:
        try:
            nvim.input("\x1b")
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                closed = bool(
                    nvim.exec_lua(
                        "return require('which-key.state').state == nil "
                        "and not require('which-key.view').valid()"
                    )
                )
                if closed:
                    break
                time.sleep(0.05)
            nvim.exec_lua(
                "local h=_G.ClarityActionMatrixHelp; if h and h.original then "
                "require('which-key').show=h.original end; _G.ClarityActionMatrixHelp=nil"
            )
        except Exception as exc:
            input_error = input_error or str(exc)

    mapped = setup["mapped"] is True
    return {
        "action_id": "help.buffer_keymaps",
        "lhs": "<leader>?",
        "mapped": mapped,
        "input": not input_error,
        "postcondition": opened and global_only is False,
        "restored": closed,
        "ok": mapped and not input_error and opened and global_only is False and closed,
        "evidence": {
            "view_opened": opened,
            "global": global_only,
            "input_error": input_error,
        },
    }


def run_session_quit(
    candidate_root: Path,
    nvim_bin: str,
    env: dict[str, str],
    timeout: float,
) -> dict[str, Any]:
    pynvim = require_pynvim()

    probe = candidate_root / "tests" / "lua" / "runtime_probe.lua"
    sample = candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua"
    argv = [
        nvim_bin,
        "--embed",
        "--cmd",
        observed_startup_command(probe),
        "-u",
        str(candidate_root / "init.lua"),
        str(sample),
    ]
    with process_context(candidate_root, env):
        nvim = pynvim.attach("child", argv=argv)

    alive = True
    ready = False
    mapped = False
    exited = False
    error_message = ""
    try:
        nvim.ui_attach(80, 24, rgb=True)
        startup = startup_evidence(nvim, probe, min(int(timeout * 1000), 5000))
        ready = startup["clean"] is True
        mapped = bool(
            nvim.exec_lua("return not vim.tbl_isempty(vim.fn.maparg('<leader>qq', 'n', false, true))")
        )
        if ready and mapped:
            leader = str(nvim.exec_lua("return vim.g.mapleader or '\\\\'"))
            nvim.input(leader + "qq")
            try:
                nvim.exec_lua("vim.wait(1000, function() return false end, 20); return true")
                nvim.eval("1")
            except Exception as exc:
                error_message = str(exc)
                alive = False
                exited = True
    finally:
        if alive:
            try:
                nvim.command("qall!")
            except Exception:
                pass
        nvim.close()

    return {
        "action_id": "session.quit_all",
        "lhs": "<leader>qq",
        "mapped": mapped,
        "input": ready and mapped,
        "postcondition": exited,
        "restored": True,
        "isolated_process": True,
        "ok": ready and mapped and exited,
        "startup": startup,
        "evidence": {"runtime_ready": ready, "rpc_exit_observed": bool(error_message)},
    }


def run_attached_matrix(
    candidate_root: Path,
    nvim_bin: str,
    env: dict[str, str],
    wait_ms: int,
) -> dict[str, Any]:
    pynvim = require_pynvim()

    probe = candidate_root / "tests" / "lua" / "runtime_probe.lua"
    matrix = candidate_root / "tests" / "lua" / "real_input_action_matrix.lua"
    sample = candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua"
    argv = [
        nvim_bin,
        "--embed",
        "--cmd",
        observed_startup_command(probe),
        "-u",
        str(candidate_root / "init.lua"),
        str(sample),
    ]

    with process_context(candidate_root, env):
        nvim = pynvim.attach("child", argv=argv)
    try:
        nvim.ui_attach(80, 24, rgb=True)
        startup = startup_evidence(nvim, probe, wait_ms)
        if startup["clean"] is not True:
            return {
                "actions": [],
                "contextual": [],
                "extras": [],
                "expected_manifest": [],
                "expected_contextual_manifest": [],
                "startup": startup,
            }
        help_action = run_interactive_help(nvim)
        result = nvim.exec_lua(
            "local path, external = ...; return dofile(path).run(external)",
            str(matrix),
            {"help.buffer_keymaps": help_action},
        )
        result["startup"] = startup
        return result
    finally:
        try:
            nvim.command("qall!")
        except Exception:
            pass
        nvim.close()


def evaluate(
    matrix: dict[str, Any],
    session: dict[str, Any],
    repository_immutable: bool,
    authority_immutable: bool,
    fixture_processes_exited: bool,
    fixture_process_count: int,
) -> dict[str, Any]:
    actions = [*matrix.get("actions", []), session]
    actions.sort(key=lambda action: action.get("lhs", ""))
    expected = sorted(matrix.get("expected_manifest", []))
    actual = sorted(action.get("lhs") for action in actions)
    expected_global_rows = matrix.get("expected_global_manifest", [])
    expected_global = {
        (case.get("action_id"), case.get("lhs")) for case in expected_global_rows
    }
    actual_global = {(case.get("action_id"), case.get("lhs")) for case in actions}
    action_failures = [action for action in actions if not action.get("ok")]
    contextual = matrix.get("contextual", [])
    contextual_failures = [case for case in contextual if not case.get("ok")]
    expected_contextual_rows = matrix.get("expected_contextual_manifest", [])
    expected_contextual = {
        (case.get("action_id"), case.get("lhs")) for case in expected_contextual_rows
    }
    contextual_exact = {
        (case.get("action_id"), case.get("lhs")) for case in contextual
    } == expected_contextual and len(contextual) == len(expected_contextual_rows) == 7
    extras = matrix.get("extras", [])
    extra_failures = [case for case in extras if not case.get("ok")]
    exact = (
        actual == expected
        and actual_global == expected_global
        and len(actions) == len(expected_global_rows) == 28
    )
    expected_context = {
        "diagnostic.next_previous",
        "lsp.definition",
        "lsp.hover",
        "lsp.references",
    }
    extras_exact = {case.get("id") for case in extras} == expected_context and len(extras) == 4
    matrix_startup = matrix.get("startup", {})
    session_startup = session.get("startup", {})
    startup_clean = matrix_startup.get("clean") is True and session_startup.get("clean") is True
    cleanup_recovery = matrix.get("cleanup_recovery", {})
    cleanup_recovered = cleanup_recovery.get("ok") is True
    status = (
        "pass"
        if exact
        and not action_failures
        and contextual_exact
        and not contextual_failures
        and extras_exact
        and not extra_failures
        and repository_immutable
        and authority_immutable
        and startup_clean
        and cleanup_recovered
        and fixture_processes_exited
        else "fail"
    )
    return {
        "schema_version": 1,
        "status": status,
        "global": {
            "expected_count": 28,
            "actual_count": len(actions),
            "manifest_exact": exact,
            "expected_manifest": expected,
            "actual_manifest": actual,
            "actions": actions,
            "failure_ids": [action.get("action_id") for action in action_failures],
        },
        "contextual": {
            "expected_count": 7,
            "actual_count": len(contextual),
            "manifest_exact": contextual_exact,
            "actions": contextual,
            "failure_ids": [case.get("action_id") for case in contextual_failures],
        },
        "extras": {
            "expected_count": 4,
            "actual_count": len(extras),
            "manifest_exact": extras_exact,
            "actions": extras,
            "failure_ids": [case.get("id") for case in extra_failures],
        },
        "isolation": {
            "repository_immutable": repository_immutable,
            "authority_immutable": authority_immutable,
            "session_quit_isolated": session.get("isolated_process") is True,
            "fixture_processes_exited": fixture_processes_exited,
            "fixture_process_count": fixture_process_count,
        },
        "startup": {
            "clean": startup_clean,
            "matrix": matrix_startup,
            "session": session_startup,
        },
        "cleanup_recovery": cleanup_recovery,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run every promoted Clarity action through real Neovim input.")
    parser.add_argument("--nvim-bin")
    parser.add_argument("--reuse-plugin-cache", type=Path)
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--json", action="store_true", help="Retained for command compatibility; output is JSON.")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    nvim_bin = resolve_nvim_binary(args.nvim_bin)
    plugin_cache = args.reuse_plugin_cache or default_plugin_cache()
    if plugin_cache is None:
        raise RuntimeError("No reusable Neovim plugin cache was found; pass --reuse-plugin-cache.")

    source_before = authority_hashes(source_root)
    with tempfile.TemporaryDirectory(prefix="clarity-action-matrix-") as directory:
        root = Path(directory)
        candidate_root = root / "candidate"
        runtime_root = root / "runtime"
        copy_candidate(source_root, candidate_root)
        env = configure_action_matrix_environment(candidate_root, runtime_root)
        copy_plugin_cache(plugin_cache.resolve(), runtime_root)
        prepare_attached_context_fixture(candidate_root, runtime_root, env, args.timeout)

        candidate_before = authority_hashes(candidate_root)
        repository_before = repository_snapshot(candidate_root, env, args.timeout)
        session = run_session_quit(candidate_root, nvim_bin, env, args.timeout)
        matrix = run_attached_matrix(candidate_root, nvim_bin, env, min(int(args.timeout * 1000), 5000))
        fixture_processes_exited, fixture_process_count = fake_lsp_processes_exited(
            Path(env["CLARITY_FAKE_LSP_LOG"])
        )
        repository_after = repository_snapshot(candidate_root, env, args.timeout)
        candidate_after = authority_hashes(candidate_root)

    source_after = authority_hashes(source_root)
    report = evaluate(
        matrix,
        session,
        repository_before == repository_after,
        candidate_before == candidate_after and source_before == source_after,
        fixture_processes_exited,
        fixture_process_count,
    )
    report["source_hashes"] = {"before": source_before, "after": source_after}
    report["candidate_hashes"] = {"before": candidate_before, "after": candidate_after}
    roots = (
        (candidate_root, "<candidate>"),
        (runtime_root, "<runtime>"),
        (source_root, "<source>"),
        (Path.home(), "<home>"),
    )
    report, redacted_count = redact_report_paths(report, roots)
    leak_count = fixture_path_leak_count(report, tuple(root for root, _ in roots))
    report["privacy"] = {
        "absolute_roots_absent": leak_count == 0,
        "leak_count": leak_count,
        "redacted_count": redacted_count,
    }
    if leak_count:
        report["status"] = "fail"
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, ValueError, shutil.Error) as exc:
        print(str(exc), file=os.sys.stderr)
        raise SystemExit(1) from exc
