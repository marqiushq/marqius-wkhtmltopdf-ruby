#!/usr/bin/env python3
"""Follows the releases of marqius-wkhtmltopdf on GitHub, for a package that carries it.

    python3 .github/release.py latest              prints the latest release's version
    python3 .github/release.py newer A B           succeeds when version A is newer than version B
    python3 .github/release.py fetch VERSION DIR   each program of VERSION, checked three ways

`fetch` downloads every program of release vVERSION of marqiushq/marqius-wkhtmltopdf into DIR. Each
must match the release's SHA256SUMS, the .sha256 file published beside it, and the build provenance
GitHub signed for it when the release workflow built it (`gh attestation verify`, which needs gh and
a GH_TOKEN). It stops at the first that does not, and writes DIR/SHA256SUMS. Only the standard
library is used, and gh.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

REPO = "marqiushq/marqius-wkhtmltopdf"
WORKFLOW = f"{REPO}/.github/workflows/release.yml"  # the workflow that builds and signs each release
BUILDS = ["linux-x86_64", "linux-arm64", "macos-arm64", "windows-x86_64.exe"]
AGENT = "marqiushq-package-release (+https://github.com/marqiushq)"


def fetch(url, api=False):
    headers = {"User-Agent": AGENT}
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if api:
        headers["Accept"] = "application/vnd.github+json"
        if token:
            headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def version(v):
    if not re.fullmatch(r"\d+(\.\d+)+", v):
        sys.exit(f"not a version: {v[:40]!r}")
    return tuple(int(x) for x in v.split("."))


def latest():
    tag = json.loads(fetch(f"https://api.github.com/repos/{REPO}/releases/latest", api=True))["tag_name"]
    v = tag[1:] if tag.startswith("v") else tag
    version(v)
    print(v)


def fetch_all(v, folder):
    version(v)
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    base = f"https://github.com/{REPO}/releases/download/v{v}"
    listed = {}
    for line in fetch(f"{base}/SHA256SUMS").decode("utf-8").splitlines():
        if line.strip():
            sha, name = line.split()
            listed[name.lstrip("*")] = sha.lower()
    sums = []
    for build in BUILDS:
        name = f"marqius-wkhtmltopdf-{build}"
        beside = fetch(f"{base}/{name}.sha256").decode("utf-8").strip()[:64].lower()
        if not re.fullmatch(r"[0-9a-f]{64}", beside) or listed.get(name) != beside:
            sys.exit(f"{name}: SHA256SUMS ({listed.get(name)}) and {name}.sha256 ({beside[:64]}) disagree")
        data = fetch(f"{base}/{name}")
        got = hashlib.sha256(data).hexdigest()
        if got != beside:
            sys.exit(f"{name} {v} does not match its published SHA-256 ({beside}; it has {got})")
        path = folder / name
        path.write_bytes(data)
        os.chmod(path, 0o755)
        check = subprocess.run(
            ["gh", "attestation", "verify", str(path), "--repo", REPO, "--signer-workflow", WORKFLOW,
             "--deny-self-hosted-runners"],
            capture_output=True, text=True)
        if check.returncode != 0:
            path.unlink()
            sys.exit(f"{name} {v} has no valid build provenance from {WORKFLOW}:\n{check.stdout}{check.stderr}")
        sums.append(f"{got}  {name}\n")
        print(f"{name} {v}: {got}, provenance verified ({WORKFLOW})")
    (folder / "SHA256SUMS").write_text("".join(sums), encoding="utf-8")


def main():
    a = sys.argv[1:]
    if a == ["latest"]:
        latest()
    elif len(a) == 3 and a[0] == "newer":
        sys.exit(0 if version(a[1]) > version(a[2]) else 1)
    elif len(a) == 3 and a[0] == "fetch":
        fetch_all(a[1], a[2])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
