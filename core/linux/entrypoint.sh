#!/usr/bin/env bash
set -euo pipefail

main() {
    local steamcmd_root
    steamcmd_root="${STEAMCMD_ROOT:-/home/steam/Steam}"

    if [[ ! -d "${steamcmd_root}" ]]; then
        echo "Creating SteamCMD directory at ${steamcmd_root}"
        mkdir -p "${steamcmd_root}"
    fi

    if [[ -n "${STEAMCMD_ARGS:-}" ]]; then
        echo "Running SteamCMD with custom arguments"
        steamcmd +force_install_dir /data ${STEAMCMD_ARGS} +quit
    else
        echo "No custom arguments provided; starting SteamCMD shell"
        exec steamcmd
    fi
}

main "$@"
