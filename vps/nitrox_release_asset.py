#!/usr/bin/env python3
"""Select the Linux Nitrox release asset to download."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: nitrox_release_asset.py <release.json> <arch>", file=sys.stderr)
        return 2

    release_source = sys.argv[1]
    arch = sys.argv[2].lower()

    if release_source == "-":
        release = json.loads(sys.stdin.read())
    else:
        release_path = Path(release_source)
        release = json.loads(release_path.read_text(encoding="utf-8"))
    tag_name = str(release.get("tag_name") or release.get("name") or "").strip()
    assets = release.get("assets") or []

    pattern = re.compile(rf"linux.*{re.escape(arch)}.*\.zip$", re.IGNORECASE)

    for asset in assets:
        name = str(asset.get("name") or "")
        download_url = str(asset.get("browser_download_url") or "")

        if pattern.search(name) and download_url:
            print(tag_name)
            print(name)
            print(download_url)
            return 0

    asset_names = ", ".join(str(asset.get("name") or "?") for asset in assets)
    print(
        f"No Linux {arch} zip asset found in release {tag_name}. "
        f"Available assets: {asset_names}",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
