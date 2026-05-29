#!/usr/bin/env python3
"""Print the Linux x64 Nitrox ZIP asset URL from a GitHub release payload."""

import json
import sys
from pathlib import Path


def is_linux_x64_zip(asset_name: str) -> bool:
    normalized_name = asset_name.lower()

    if "linux" not in normalized_name:
        return False

    if "x64" not in normalized_name and "amd64" not in normalized_name:
        return False

    if not normalized_name.endswith(".zip"):
        return False

    return True


def find_download_url(metadata_path: Path) -> str:
    with metadata_path.open("r", encoding="utf-8") as metadata_file:
        release = json.load(metadata_file)

    for asset in release.get("assets", []):
        asset_name = asset.get("name", "")
        download_url = asset.get("browser_download_url", "")

        if not download_url:
            continue

        if is_linux_x64_zip(asset_name):
            return download_url

    return ""


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: nitrox_release_asset.py <github-release-json>", file=sys.stderr)
        return 2

    download_url = find_download_url(Path(sys.argv[1]))

    if not download_url:
        return 1

    print(download_url)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
