from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import stat
import subprocess
import tarfile
import tempfile
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path


DEFAULT_VERSION = "v0.12.4"


@dataclass(frozen=True)
class Asset:
    name: str
    sha256: str
    binary: str


ASSETS = {
    ("linux", "x86_64"): Asset(
        "nvim-linux-x86_64.tar.gz",
        "012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628",
        "nvim-linux-x86_64/bin/nvim",
    ),
    ("linux", "aarch64"): Asset(
        "nvim-linux-arm64.tar.gz",
        "ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f",
        "nvim-linux-arm64/bin/nvim",
    ),
    ("darwin", "x86_64"): Asset(
        "nvim-macos-x86_64.tar.gz",
        "03fe16f8dd9f1e9eaf52d5e294913a39917b9e2faea30d7fb0fb385fbd36fe59",
        "nvim-macos-x86_64/bin/nvim",
    ),
    ("darwin", "aarch64"): Asset(
        "nvim-macos-arm64.tar.gz",
        "51ab83afa66d663627c2ab1be43209b0f4e81360d4598b53efaa4d8195f24c89",
        "nvim-macos-arm64/bin/nvim",
    ),
    ("windows", "x86_64"): Asset(
        "nvim-win64.zip",
        "9fc3572829ffd13debb6e32555da2c8cc02555568260a9fc4cf1f65bbcca319c",
        "nvim-win64/bin/nvim.exe",
    ),
    ("windows", "aarch64"): Asset(
        "nvim-win-arm64.zip",
        "49906085a3c473ee87a28319942c62216fb365a1a1a4f83dbc4ac41365f5e609",
        "nvim-win-arm64/bin/nvim.exe",
    ),
}


def normalize_platform(system: str, machine: str) -> tuple[str, str]:
    normalized_system = system.lower()
    normalized_machine = machine.lower()
    if normalized_machine in {"amd64", "x64"}:
        normalized_machine = "x86_64"
    elif normalized_machine in {"arm64", "aarch64"}:
        normalized_machine = "aarch64"
    return normalized_system, normalized_machine


def select_asset(system: str | None = None, machine: str | None = None) -> Asset:
    key = normalize_platform(system or platform.system(), machine or platform.machine())
    try:
        return ASSETS[key]
    except KeyError as exc:
        raise RuntimeError(f"Unsupported Neovim CI platform: system={key[0]} machine={key[1]}") from exc


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_archive(archive: Path, destination: Path) -> None:
    if archive.name.endswith(".zip"):
        with zipfile.ZipFile(archive) as bundle:
            bundle.extractall(destination)
        return
    with tarfile.open(archive, "r:gz") as bundle:
        bundle.extractall(destination, filter="data")


def install(version: str, destination: Path) -> tuple[Path, Asset]:
    if version != DEFAULT_VERSION:
        raise RuntimeError(
            f"No checksum manifest is defined for {version}. Update DEFAULT_VERSION and ASSETS together."
        )

    asset = select_asset()
    binary = destination / asset.binary
    if binary.is_file():
        return binary, asset

    destination.mkdir(parents=True, exist_ok=True)
    url = f"https://github.com/neovim/neovim/releases/download/{version}/{asset.name}"
    with tempfile.TemporaryDirectory(prefix="clarity-neovim-") as directory:
        archive = Path(directory) / asset.name
        urllib.request.urlretrieve(url, archive)
        actual = sha256_file(archive)
        if actual != asset.sha256:
            raise RuntimeError(f"Neovim asset checksum mismatch: expected={asset.sha256} actual={actual}")
        extract_archive(archive, destination)

    if not binary.is_file():
        raise RuntimeError(f"Neovim binary missing after extraction: {binary}")
    binary.chmod(binary.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return binary, asset


def append_github_file(variable: str, value: str) -> None:
    path = os.environ.get(variable)
    if not path:
        raise RuntimeError(f"{variable} is not set by GitHub Actions")
    with Path(path).open("a", encoding="utf-8") as handle:
        handle.write(value + "\n")


def run() -> int:
    parser = argparse.ArgumentParser(description="Install a checksummed official Neovim release for Clarity CI.")
    parser.add_argument("--version", default=DEFAULT_VERSION)
    parser.add_argument("--destination", type=Path, default=Path(".clarity-tools") / "neovim")
    parser.add_argument("--github-env", action="store_true", help="Write NVIM_BIN and the binary directory to Actions files.")
    args = parser.parse_args()

    binary, asset = install(args.version, args.destination.resolve())
    version_output = subprocess.run(
        [str(binary), "--version"], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30
    )
    if version_output.returncode != 0 or args.version.removeprefix("v") not in version_output.stdout.splitlines()[0]:
        raise RuntimeError(version_output.stderr or version_output.stdout or "Installed Neovim version check failed")

    if args.github_env:
        append_github_file("GITHUB_ENV", f"NVIM_BIN={binary}")
        append_github_file("GITHUB_PATH", str(binary.parent))

    print(
        json.dumps(
            {
                "check_id": "CLARITY-TOOLCHAIN-001",
                "version": args.version,
                "asset": asset.name,
                "sha256": asset.sha256,
                "binary": str(binary),
                "reported": version_output.stdout.splitlines()[0],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
