#!/usr/bin/env bash
set -euo pipefail

: "${SERVER_DIR:=/opt/server}"
: "${ENABLE_TERMINAL:=0}"
: "${START_SERVER:=1}"
: "${SERVER_EXE:=Server.exe}"
: "${SERVER_ARGS:=}"
: "${WINE_MISMATCH_STRATEGY:=switch}"
: "${USE_XVFB:=1}"
: "${XVFB_SCREEN:=0 1024x768x16}"
: "${WINETRICKS_PACKAGES:=vcrun2022}"
: "${WINETRICKS_QUIET:=1}"
: "${WINETRICKS_FORCE:=1}"

get_prefix_architecture() {
  local prefix_path="$1"
  local system_reg_file=""

  system_reg_file="${prefix_path}/system.reg"

  if [[ ! -f "${system_reg_file}" ]]; then
    echo "missing"
    return 0
  fi

  if grep -q "#arch=win64" "${system_reg_file}"; then
    echo "win64"
    return 0
  fi

  if grep -q "#arch=win32" "${system_reg_file}"; then
    echo "win32"
    return 0
  fi

  echo "unknown"
}

initialize_wine_prefix() {
  echo "[wine-core] Initializing Wine prefix: ${WINEPREFIX} (WINEARCH=${WINEARCH:-default})"
  wineboot -u >/dev/null 2>&1 || wineboot -u
}

normalize_winetricks_packages() {
  local raw_packages="$1"
  local normalized_packages=""

  normalized_packages="$(echo "${raw_packages}" | tr ',' ' ')"
  normalized_packages="$(echo "${normalized_packages}" | xargs)"

  echo "${normalized_packages}"
}

ensure_winetricks_packages() {
  local packages_to_install=""
  local marker_file=""
  local quiet_flag=""
  local force_flag=""

  packages_to_install="$(normalize_winetricks_packages "${WINETRICKS_PACKAGES}")"

  if [[ -z "${packages_to_install}" ]]; then
    return 0
  fi

  if ! command -v winetricks >/dev/null 2>&1; then
    echo "[wine-core] Error: WINETRICKS_PACKAGES is set but winetricks is not found." >&2
    return 1
  fi

  marker_file="${WINEPREFIX}/.winetricks-installed.txt"
  quiet_flag=""

  if [[ "${WINETRICKS_QUIET}" == "1" ]]; then
    quiet_flag="-q"
  fi

  if [[ "${WINETRICKS_FORCE}" == "1" ]]; then
    force_flag="--force"
  fi

  if [[ -f "${marker_file}" ]]; then
    if [[ "$(cat "${marker_file}")" == "${packages_to_install}" ]]; then
      echo "[wine-core] Winetricks already applied for requested packages: ${packages_to_install}"
      return 0
    fi
  fi

  echo "[wine-core] Installing Winetricks packages: ${packages_to_install}"

  if [[ "${USE_XVFB}" == "1" ]]; then
    xvfb-run -a -s "-screen ${XVFB_SCREEN}" winetricks ${quiet_flag} ${force_flag} ${packages_to_install}
  else
    winetricks ${quiet_flag} ${force_flag} ${packages_to_install}
  fi

  if ! echo "${packages_to_install}" > "${marker_file}"; then
    echo "[wine-core] Warning: could not write marker file ${marker_file}." >&2
  fi
}

ensure_wine_prefix_architecture() {
  local prefix_architecture=""
  local expected_architecture=""
  local switched_prefix=""

  expected_architecture="${WINEARCH:-}"
  prefix_architecture="$(get_prefix_architecture "${WINEPREFIX}")"

  if [[ "${prefix_architecture}" == "missing" ]]; then
    initialize_wine_prefix
    return 0
  fi

  if [[ -z "${expected_architecture}" ]]; then
    return 0
  fi

  if [[ "${prefix_architecture}" == "${expected_architecture}" ]]; then
    return 0
  fi

  if [[ "${WINE_MISMATCH_STRATEGY}" == "switch" ]]; then
    switched_prefix="${WINEPREFIX}-${expected_architecture}"
    echo "[wine-core] Architecture mismatch detected (${prefix_architecture} vs ${expected_architecture})."
    echo "[wine-core] Automatically switching to a dedicated prefix: ${switched_prefix}"
    export WINEPREFIX="${switched_prefix}"
    initialize_wine_prefix
    return 0
  fi

  if [[ "${WINE_MISMATCH_STRATEGY}" == "recreate" ]]; then
    echo "[wine-core] Architecture mismatch detected (${prefix_architecture} vs ${expected_architecture})."
    echo "[wine-core] Deleting and recreating prefix ${WINEPREFIX}."
    rm -rf "${WINEPREFIX}"
    initialize_wine_prefix
    return 0
  fi

  echo "[wine-core] Error: WINEARCH=${expected_architecture} but ${WINEPREFIX} is ${prefix_architecture}." >&2
  echo "[wine-core] Set WINE_MISMATCH_STRATEGY=switch (recommended) or recreate to auto-fix." >&2
  return 1
}

open_terminal_mode() {
  echo "[wine-core] Terminal mode active. Opening a shell in ${SERVER_DIR}."

  cd "${SERVER_DIR}"

  if [[ -t 0 || -t 1 ]]; then
    exec /bin/bash -l
  fi

  echo "[wine-core] No TTY detected. Keeping container alive for later attachment (docker exec -it)."
  exec tail -f /dev/null
}

start_windows_server() {
  echo "[wine-core] Starting Windows server via Wine: ${SERVER_EXE} ${SERVER_ARGS}"

  if [[ ! -f "${SERVER_DIR}/${SERVER_EXE}" ]]; then
    echo "[wine-core] Error: ${SERVER_EXE} not found in ${SERVER_DIR}." >&2
    exit 1
  fi

  cd "${SERVER_DIR}"

  if [[ "${USE_XVFB}" == "1" ]]; then
    echo "[wine-core] USE_XVFB=1, launching via xvfb-run (virtual DISPLAY)."
    exec xvfb-run -a -s "-screen ${XVFB_SCREEN}" wine "${SERVER_EXE}" ${SERVER_ARGS}
  fi

  exec wine "${SERVER_EXE}" ${SERVER_ARGS}
}

main() {
  ensure_wine_prefix_architecture
  ensure_winetricks_packages

  if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
    open_terminal_mode
  fi

  if [[ "${START_SERVER}" == "1" ]]; then
    start_windows_server
  fi

  echo "[wine-core] START_SERVER=0, no server launched."
}

main "$@"
