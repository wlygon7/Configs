#!/usr/bin/env python3
"""Mirror live configs from ~/.config into this dotfiles repo.

Each entry in CONFIGS is wiped from the repo and replaced with a fresh copy
of ~/.config/<name>. Anything you deleted locally gets deleted here too, and
git still has the old versions if you need them back.
"""

import shutil
from pathlib import Path

CONFIG_DIR = Path.home() / ".config"
REPO_DIR = Path(__file__).resolve().parent

# Folders (or single files) under ~/.config to mirror into the repo.
CONFIGS = [
    "gtk-3.0",
    "gtk-4.0",
    "hypr",
    "kitty",
    "matugen",
    "nvim",
    "quickshell",
    "waybar",
    "wofi",
]

IGNORE = shutil.ignore_patterns(".git", "__pycache__")


def sync(name: str) -> None:
    src = CONFIG_DIR / name
    dst = REPO_DIR / name

    if not src.exists():
        print(f"skip  {name}: {src} doesn't exist")
        return
    # e.g. ~/.config/nvim -> ~/dotfiles/nvim: the repo already is the config,
    # and wiping dst would wipe the live config with it.
    if src.resolve().is_relative_to(REPO_DIR):
        print(f"skip  {name}: already symlinked into the repo")
        return

    if dst.is_dir() and not dst.is_symlink():
        shutil.rmtree(dst)
    elif dst.exists() or dst.is_symlink():
        dst.unlink()

    if src.is_dir():
        shutil.copytree(src, dst, symlinks=True, ignore=IGNORE)
    else:
        shutil.copy2(src, dst)
    print(f"copy  {name}")


def main() -> None:
    for name in CONFIGS:
        sync(name)


if __name__ == "__main__":
    main()
