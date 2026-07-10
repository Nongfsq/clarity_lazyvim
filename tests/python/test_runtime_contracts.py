from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import run_clarity_contracts as contracts  # noqa: E402
from clarity_runtime import resolve_nvim_binary  # noqa: E402


class RuntimeContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = contracts.load_catalog(REPO_ROOT, resolve_nvim_binary())

    def test_catalog_classifies_all_config_modules_and_planned_tasks(self) -> None:
        issues = contracts.catalog_issues(
            self.catalog,
            contracts.discover_config_modules(REPO_ROOT),
            contracts.discover_task_ids(REPO_ROOT),
        )
        self.assertEqual(issues, [])

    def test_orphan_module_fails_catalog_drift(self) -> None:
        modules = contracts.discover_config_modules(REPO_ROOT) | {"config.orphan"}
        issues = contracts.catalog_issues(self.catalog, modules, contracts.discover_task_ids(REPO_ROOT))
        self.assertIn("CLARITY_CONTRACT_UNCLASSIFIED_MODULE", {issue["id"] for issue in issues})

    def test_probe_source_forbids_lifecycle_replay(self) -> None:
        source = (REPO_ROOT / "tests" / "lua" / "runtime_probe.lua").read_text(encoding="utf-8")
        self.assertNotIn("doautocmd", source)
        self.assertNotIn("nvim_exec_autocmds", source)

    def test_headless_command_installs_observer_before_init(self) -> None:
        command = contracts.build_headless_command(REPO_ROOT, "nvim", "file_headless", 1000)
        self.assertLess(command.index("--cmd"), command.index("-u"))
        self.assertIn("runtime_probe.lua", command[command.index("--cmd") + 1])

    def test_fault_transform_only_changes_candidate_runtime_visibility(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            candidate = Path(directory)
            lazy = candidate / "nvim" / "lua" / "config" / "lazy.lua"
            init = candidate / "nvim" / "init.lua"
            lazy.parent.mkdir(parents=True)
            lazy.write_text(
                "paths = vim.list_extend({ vim.g.clarity_nvim_dir }, bundled_runtime_paths()),\n",
                encoding="utf-8",
            )
            init.parent.mkdir(parents=True, exist_ok=True)
            init.write_text("    vim.opt.rtp:append(nvim_dir)\n", encoding="utf-8")

            contracts.apply_fault(candidate, contracts.FAULT_MISSING_NESTED_RUNTIME)

            self.assertIn("nested runtime removed", lazy.read_text(encoding="utf-8"))
            self.assertIn("do not restore the nested runtime", init.read_text(encoding="utf-8"))

    def test_raw_fold_fault_restores_the_confirmed_false_green_callback(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            candidate = Path(directory)
            keymaps = candidate / "nvim" / "lua" / "config" / "keymaps.lua"
            keymaps.parent.mkdir(parents=True)
            keymaps.write_text(
                'map("n", "<leader>cz", require("config.actions.fold").toggle, opts)\n',
                encoding="utf-8",
            )

            contracts.apply_fault(candidate, contracts.FAULT_RAW_FOLD_ACTION)

            source = keymaps.read_text(encoding="utf-8")
            self.assertIn('vim.cmd("normal! za")', source)
            self.assertIn("fault: raw fold action", source)

    def test_positive_and_fault_snapshots_have_distinct_contract_results(self) -> None:
        modules = {
            name: {"loaded": True, "first_seen": "User:LazyDone"}
            for name in self.catalog["modules"]
        }
        modules["config.options"]["first_seen"] = "User:LazyVimOptions"
        modules["config.autocmds"]["first_seen"] = "User:LazyVimAutocmds"
        modules["config.keymaps"]["first_seen"] = "User:LazyVimKeymaps"
        positive = {
            "scenario": "file_ui",
            "modules": modules,
            "options": {
                "number": True,
                "relativenumber": False,
                "wrap": True,
                "linebreak": True,
                "breakindent": True,
            },
            "autocmds": {"absolute_line_numbers": 5},
            "maps": {
                "leader_uw": {"source": "/repo/nvim/lua/config/keymaps.lua"},
                "leader_cz": {"source": "/repo/nvim/lua/config/actions/fold.lua"},
            },
        }
        behavior = {
            "wrap_callback": True,
            "fold_callback": True,
            "fold_input": True,
            "fold_open_input_ok": True,
            "wrap_changed": True,
            "wrap_restored": True,
            "fold_initially_closed": True,
            "fold_opened": True,
            "fold_reclosed": True,
            "fold_open_outcome": "toggled",
            "fold_close_outcome": "toggled",
            "fold_close_input_ok": True,
            "fold_no_fold_ok": True,
            "fold_no_fold_outcome": "no_fold",
            "fold_no_fold_event_id": "CLARITY_FOLD_NO_FOLD",
            "fold_no_fold_error": "",
            "fold_cleanup": True,
            "log_small_ui": True,
            "log_readonly": True,
            "log_tail": True,
            "log_cleanup": True,
        }
        self.assertFalse([result for result in contracts.evaluate_snapshot(self.catalog, positive, behavior) if not result["ok"]])

        fault = {**positive, "modules": {name: dict(value) for name, value in modules.items()}}
        for name in ("config.options", "config.autocmds", "config.keymaps"):
            fault["modules"][name] = {"loaded": False, "first_seen": None}
        fault["options"] = {
            "number": True,
            "relativenumber": True,
            "wrap": False,
            "linebreak": False,
            "breakindent": False,
        }
        fault["autocmds"] = {"absolute_line_numbers": 0}
        fault["maps"] = {"leader_uw": {"source": None}, "leader_cz": {"source": None}}
        failure_ids = {
            result["id"]
            for result in contracts.evaluate_snapshot(self.catalog, fault, {})
            if not result["ok"]
        }
        self.assertEqual(
            failure_ids,
            {
                "CLARITY_RUNTIME_OPTIONS_CONTRACT",
                "CLARITY_RUNTIME_AUTOCMDS_CONTRACT",
                "CLARITY_RUNTIME_EDITING_DEFAULTS",
                "CLARITY_RUNTIME_KEYMAP_CONTRACT",
            },
        )

    def test_hash_drift_identifies_exact_authority_file(self) -> None:
        drift = contracts.hash_drift(
            {"lazy-lock.json": "old", "lazyvim.json": "same"},
            {"lazy-lock.json": "new", "lazyvim.json": "same"},
        )
        self.assertEqual(drift, {"lazy-lock.json": {"before": "old", "after": "new"}})


if __name__ == "__main__":
    unittest.main()
