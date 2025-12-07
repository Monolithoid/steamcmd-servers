#!/usr/bin/env bash
set -euo pipefail

setup_wine_prefix() {
    if [[ ! -d "${WINEPREFIX}" ]]; then
        echo "Initializing Wine prefix at ${WINEPREFIX}"
        wineboot --init
    fi
}

run_steamcmd() {
    if [[ -n "${STEAMCMD_ARGS:-}" ]]; then
        echo "Running SteamCMD with custom arguments through Wine"
        wine steamcmd +force_install_dir Z:/data ${STEAMCMD_ARGS} +quit
    else
        echo "Launching interactive SteamCMD via Wine"
        exec wine steamcmd
    fi
}

main() {
    export WINEPREFIX="${WINEPREFIX:-/home/steam/.wine}"
    setup_wine_prefix
    run_steamcmd
}

main "$@"
