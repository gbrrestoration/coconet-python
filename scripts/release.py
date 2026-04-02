#!/usr/bin/env python3
"""Cut a release: bump version in pyproject.toml, refresh uv.lock, commit, tag vX.Y.Z, optional push.

One-liner (from repo root, pushes branch + tag):
  ./scripts/release 1.2.3 --push

Other examples:
  uv run python scripts/release.py patch --push
  uv run python scripts/release.py 0.2.0 --dry-run
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
VERSION_LINE_RE = re.compile(r'^version = "[^"]*"\s*$', re.MULTILINE)
BUMP_KINDS = frozenset({"major", "minor", "patch"})


def run_git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo,
        check=check,
        capture_output=True,
        text=True,
    )


def git_toplevel(start: Path) -> Path:
    r = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=start,
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        sys.stderr.write("release: not inside a git repository\n")
        sys.exit(1)
    return Path(r.stdout.strip())


def read_pyproject_version(text: str) -> str:
    matches = list(VERSION_LINE_RE.finditer(text))
    if not matches:
        sys.stderr.write('release: could not find version = "..." in pyproject.toml\n')
        sys.exit(1)
    if len(matches) > 1:
        sys.stderr.write("release: multiple version = lines in pyproject.toml; aborting\n")
        sys.exit(1)
    line = matches[0].group(0).strip()
    m = re.match(r'^version = "([^"]*)"\s*$', line)
    if not m:
        sys.stderr.write("release: could not parse version line\n")
        sys.exit(1)
    return m.group(1)


def replace_pyproject_version(text: str, new_version: str) -> str:
    def repl(_: re.Match[str]) -> str:
        return f'version = "{new_version}"'

    updated, n = VERSION_LINE_RE.subn(repl, text, count=1)
    if n != 1:
        sys.stderr.write("release: failed to replace version in pyproject.toml\n")
        sys.exit(1)
    return updated


def parse_semver(s: str) -> tuple[int, int, int]:
    m = SEMVER_RE.match(s)
    if not m:
        sys.stderr.write(
            f"release: invalid semver {s!r}; expected MAJOR.MINOR.PATCH "
            "(non-negative integers, no leading zeros on segments)\n"
        )
        sys.exit(1)
    return int(m.group(1)), int(m.group(2)), int(m.group(3))


def bump_version(current: str, kind: str) -> str:
    major, minor, patch = parse_semver(current)
    if kind == "patch":
        patch += 1
    elif kind == "minor":
        minor += 1
        patch = 0
    elif kind == "major":
        major += 1
        minor = 0
        patch = 0
    return f"{major}.{minor}.{patch}"


def ensure_clean_tree(repo: Path, allow_dirty: bool) -> None:
    if allow_dirty:
        return
    r = run_git(repo, "status", "--porcelain", check=True)
    if r.stdout.strip():
        sys.stderr.write("release: working tree is dirty; commit or stash, or pass --allow-dirty\n")
        sys.exit(1)


def tag_exists_local(repo: Path, tag: str) -> bool:
    r = run_git(repo, "rev-parse", "--verify", f"refs/tags/{tag}", check=False)
    return r.returncode == 0


def tag_exists_remote(repo: Path, tag: str) -> bool:
    r = run_git(repo, "remote", "get-url", "origin", check=False)
    if r.returncode != 0:
        return False
    lr = run_git(
        repo,
        "ls-remote",
        "origin",
        f"refs/tags/{tag}",
        check=False,
    )
    return lr.returncode == 0 and bool(lr.stdout.strip())


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Set package version, uv lock, commit, tag vX.Y.Z, optionally push.",
    )
    parser.add_argument(
        "version",
        metavar="VERSION_OR_BUMP",
        help="Semver X.Y.Z or bump keyword: major | minor | patch",
    )
    parser.add_argument(
        "--push",
        action="store_true",
        help="git push current branch and the new tag to origin",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print actions; do not write files, run uv, or git mutate",
    )
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="allow a dirty working tree (still only stages pyproject.toml and uv.lock)",
    )
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    repo = git_toplevel(script_dir)
    pyproject = repo / "pyproject.toml"
    if not pyproject.is_file():
        sys.stderr.write(f"release: missing {pyproject}\n")
        sys.exit(1)

    raw_text = pyproject.read_text(encoding="utf-8")
    current_ver = read_pyproject_version(raw_text)
    spec = args.version.lower()
    if spec in BUMP_KINDS:
        if not SEMVER_RE.match(current_ver):
            sys.stderr.write(
                f"release: current pyproject version {current_ver!r} is not a valid semver; "
                "cannot bump\n"
            )
            sys.exit(1)
        target = bump_version(current_ver, spec)
    else:
        target = args.version
    parse_semver(target)

    tag = f"v{target}"
    if tag_exists_local(repo, tag) or tag_exists_remote(repo, tag):
        sys.stderr.write(f"release: tag {tag} already exists (local or origin)\n")
        sys.exit(1)

    new_text = replace_pyproject_version(raw_text, target)

    if args.dry_run:
        print(f"Would set version to {target} ({tag})")
        for line in difflike_lines(raw_text, new_text, str(pyproject)):
            print(line)
        if new_text == raw_text:
            print("No file change; would skip commit/tag/push")
            return
        print("Would run: uv lock")
        print(f'Would run: git add pyproject.toml uv.lock && git commit -m "chore: release {tag}"')
        print(f"Would run: git tag {tag}")
        if args.push:
            print("Would run: git push && git push origin " + tag)
        return

    if new_text == raw_text:
        sys.stderr.write(f"release: version is already {target}; nothing to do\n")
        sys.exit(1)

    ensure_clean_tree(repo, args.allow_dirty)

    pyproject.write_text(new_text, encoding="utf-8")
    try:
        subprocess.run(
            ["uv", "lock"],
            cwd=repo,
            check=True,
        )
    except FileNotFoundError:
        sys.stderr.write("release: uv not found on PATH\n")
        sys.exit(1)
    except subprocess.CalledProcessError:
        sys.stderr.write("release: uv lock failed\n")
        sys.exit(1)

    run_git(repo, "add", "pyproject.toml", "uv.lock", check=True)
    run_git(
        repo,
        "commit",
        "-m",
        f"chore: release {tag}",
        check=True,
    )
    run_git(repo, "tag", tag, check=True)

    if args.push:
        pb = run_git(repo, "push", check=False)
        if pb.returncode != 0:
            sys.stderr.write(pb.stderr or pb.stdout or "git push failed\n")
            sys.exit(1)
        pt = run_git(repo, "push", "origin", tag, check=False)
        if pt.returncode != 0:
            sys.stderr.write(pt.stderr or pt.stdout or "git push origin tag failed\n")
            sys.exit(1)


def difflike_lines(old: str, new: str, label: str) -> list[str]:
    old_l = old.splitlines(keepends=True)
    new_l = new.splitlines(keepends=True)
    out: list[str] = [f"--- {label} (before)", f"+++ {label} (after)"]
    if old_l == new_l:
        return out
    for i, (a, b) in enumerate(zip(old_l, new_l, strict=False)):
        if a != b:
            out.append(f"@@ line {i + 1} @@")
            out.append(f"-{a.rstrip()}")
            out.append(f"+{b.rstrip()}")
            break
    else:
        if len(old_l) != len(new_l):
            out.append("@@ length differs @@")
    return out


if __name__ == "__main__":
    main()
