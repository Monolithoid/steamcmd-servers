#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

# =============================================================================
# Script      : update-games.sh
# Purpose     : Update dedicated server binaries with SteamCMD and host-side
#               prerequisites.
# Author      : Monolithoid
# =============================================================================

STEAMCMD_BIN="${STEAMCMD_BIN:-steamcmd}"
LOG_DIR="${LOG_DIR:-/tmp/steamcmd-updates}"

SUBNAUTICA_ENABLED="${SUBNAUTICA_ENABLED:-1}"
SUBNAUTICA_INSTALL_DIR="${SUBNAUTICA_INSTALL_DIR:-/opt/gaming/subnautica}"
SUBNAUTICA_NITROX_DIR="${SUBNAUTICA_NITROX_DIR:-/opt/gaming/subnautica-nitrox}"
SUBNAUTICA_NITROX_VERSION="${SUBNAUTICA_NITROX_VERSION:-latest}"
SUBNAUTICA_STEAM_USER="${SUBNAUTICA_STEAM_USER:-${STEAM_USER:-}}"
SUBNAUTICA_STEAM_PASSWORD="${SUBNAUTICA_STEAM_PASSWORD:-${STEAM_PASSWORD:-}}"
SUBNAUTICA_STEAM_GUARD_CODE="${SUBNAUTICA_STEAM_GUARD_CODE:-${STEAM_GUARD_CODE:-}}"
NITROX_RELEASE_REPO="${NITROX_RELEASE_REPO:-SubnauticaNitrox/Nitrox}"
NITROX_OWNER_UID="${NITROX_OWNER_UID:-1000}"
NITROX_OWNER_GID="${NITROX_OWNER_GID:-1000}"
NITROX_TMP_DIR="${NITROX_TMP_DIR:-/tmp/nitrox-update}"
NITROX_KEEP_ARCHIVE="${NITROX_KEEP_ARCHIVE:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NITROX_ASSET_HELPER="${NITROX_ASSET_HELPER:-${SCRIPT_DIR}/nitrox_release_asset.py}"

mkdir -p "${LOG_DIR}"

# -----------------------------------------------------------------------------
# Display helpers
# -----------------------------------------------------------------------------

step() {
  echo
  echo "╭────────────────────────────────────────────────────────────"
  printf "│ %s\n" "$1"
  echo "╰────────────────────────────────────────────────────────────"
}

ok() {
  printf "  ✓ %s\n" "$1"
}

warn() {
  printf "  ! %s\n" "$1"
}

fail() {
  printf "  ✗ %s\n" "$1"
}

info() {
  printf "  • %s\n" "$1"
}

# -----------------------------------------------------------------------------
# Generic helpers
# -----------------------------------------------------------------------------

command_exists() {
  local command_name="$1"

  command -v "${command_name}" >/dev/null 2>&1
}

require_command() {
  local command_name="$1"

  if command_exists "${command_name}"; then
    return 0
  fi

  fail "Missing required command: ${command_name}"
  return 1
}

is_enabled() {
  local value="$1"
  local normalized_value=""

  normalized_value="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]')"

  if [[ "${normalized_value}" == "1" ]]; then
    return 0
  fi

  if [[ "${normalized_value}" == "true" ]]; then
    return 0
  fi

  if [[ "${normalized_value}" == "yes" ]]; then
    return 0
  fi

  if [[ "${normalized_value}" == "on" ]]; then
    return 0
  fi

  return 1
}

# -----------------------------------------------------------------------------
# SteamCMD log analysis
# -----------------------------------------------------------------------------

analyze_steamcmd_log() {
  local app_id="$1"
  local log_file="$2"

  if grep -qi "No subscription" "${log_file}"; then
    fail "Access denied: No subscription"
    return 10
  fi

  if grep -qi "ERROR! Failed to install app" "${log_file}"; then
    fail "SteamCMD failed to install the app"
    return 11
  fi

  if grep -qi "state is 0x6" "${log_file}"; then
    fail "Known SteamCMD error: state is 0x6 after update"
    return 12
  fi

  if grep -qi "Invalid platform" "${log_file}"; then
    fail "Invalid platform for this app"
    return 13
  fi

  if grep -qi "Timeout\|timed out\|connection.*failed\|Network is unreachable" "${log_file}"; then
    fail "Network error during update"
    return 14
  fi

  if grep -qi "Disk write failure\|No space left on device\|Permission denied" "${log_file}"; then
    fail "Disk or permission error"
    return 15
  fi

  if grep -q "Success! App '${app_id}' fully installed" "${log_file}"; then
    ok "Installation/update completed successfully"
    return 0
  fi

  if grep -q "Success! App '${app_id}' already up to date" "${log_file}"; then
    ok "Already up to date"
    return 0
  fi

  if grep -qi "Success! App '${app_id}'" "${log_file}"; then
    ok "SteamCMD reported success"
    return 0
  fi

  if grep -qi "ERROR!" "${log_file}"; then
    fail "SteamCMD error detected"
    return 16
  fi

  warn "SteamCMD finished, but the status was not recognized"
  return 20
}

# -----------------------------------------------------------------------------
# SteamCMD login helpers
# -----------------------------------------------------------------------------

build_login_arguments() {
  local login_mode="$1"
  local game_name="$2"
  local -n output_arguments_ref="$3"

  output_arguments_ref=()

  if [[ "${login_mode}" == "anonymous" ]]; then
    output_arguments_ref+=(+login anonymous)
    return 0
  fi

  if [[ "${login_mode}" != "account" ]]; then
    fail "Unsupported login mode for ${game_name}: ${login_mode}"
    return 1
  fi

  if [[ "${game_name}" == "Subnautica" ]]; then
    if [[ -z "${SUBNAUTICA_STEAM_USER}" ]]; then
      fail "Subnautica requires SUBNAUTICA_STEAM_USER or STEAM_USER because the base game is not an anonymous dedicated server app"
      return 1
    fi

    if [[ -z "${SUBNAUTICA_STEAM_PASSWORD}" ]]; then
      fail "Subnautica requires SUBNAUTICA_STEAM_PASSWORD or STEAM_PASSWORD"
      return 1
    fi

    output_arguments_ref+=(+login "${SUBNAUTICA_STEAM_USER}" "${SUBNAUTICA_STEAM_PASSWORD}")

    if [[ -n "${SUBNAUTICA_STEAM_GUARD_CODE}" ]]; then
      output_arguments_ref+=("${SUBNAUTICA_STEAM_GUARD_CODE}")
    fi

    return 0
  fi

  fail "No credential mapping is configured for ${game_name}"
  return 1
}

# -----------------------------------------------------------------------------
# Game update
# -----------------------------------------------------------------------------

update_game() {
  local name="$1"
  local app_id="$2"
  local install_dir="$3"
  local platform="${4:-windows}"
  local login_mode="${5:-anonymous}"

  local timestamp=""
  local safe_name=""
  local log_file=""
  local rc=0
  local analysis_rc=0
  local login_arguments=()

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  safe_name="$(printf '%s' "${name}" | tr '[:upper:] ' '[:lower:]-')"
  log_file="${LOG_DIR}/${safe_name}-${app_id}-${timestamp}.log"

  step "Updating: ${name}"

  info "App ID      : ${app_id}"
  info "Platform    : ${platform}"
  info "Directory   : ${install_dir}"
  info "Login mode  : ${login_mode}"
  info "Log         : ${log_file}"

  require_command "${STEAMCMD_BIN}" || return 2
  build_login_arguments "${login_mode}" "${name}" login_arguments || return 2
  mkdir -p "${install_dir}"

  "${STEAMCMD_BIN}" \
    +@sSteamCmdForcePlatformType "${platform}" \
    +force_install_dir "${install_dir}" \
    "${login_arguments[@]}" \
    +app_update "${app_id}" validate \
    +quit \
    2>&1 | tee "${log_file}"

  rc=${PIPESTATUS[0]}

  if [[ ${rc} -ne 0 ]]; then
    fail "SteamCMD returned exit code ${rc}"
    analyze_steamcmd_log "${app_id}" "${log_file}" || true
    return "${rc}"
  fi

  analyze_steamcmd_log "${app_id}" "${log_file}"
  analysis_rc=$?

  return "${analysis_rc}"
}

# -----------------------------------------------------------------------------
# Nitrox prerequisites for the Subnautica server
# -----------------------------------------------------------------------------

get_nitrox_release_api_url() {
  if [[ "${SUBNAUTICA_NITROX_VERSION}" == "latest" ]]; then
    printf 'https://api.github.com/repos/%s/releases/latest\n' "${NITROX_RELEASE_REPO}"
    return 0
  fi

  printf 'https://api.github.com/repos/%s/releases/tags/%s\n' "${NITROX_RELEASE_REPO}" "${SUBNAUTICA_NITROX_VERSION}"
}

get_nitrox_download_url() {
  local release_api_url=""
  local metadata_file=""
  local download_url=""

  release_api_url="$(get_nitrox_release_api_url)"
  metadata_file="${NITROX_TMP_DIR}/nitrox-release.json"

  mkdir -p "${NITROX_TMP_DIR}" || return 1
  rm -f "${metadata_file}"

  curl -fsSL "${release_api_url}" -o "${metadata_file}" || return 1

  download_url="$(python3 "${NITROX_ASSET_HELPER}" "${metadata_file}")"

  if [[ -z "${download_url}" ]]; then
    fail "Unable to find a Linux x64 Nitrox ZIP asset in the GitHub release"
    return 1
  fi

  printf '%s\n' "${download_url}"
}

prepare_nitrox_directory() {
  mkdir -p "${SUBNAUTICA_NITROX_DIR}"
}

install_nitrox_release() {
  local download_url=""
  local archive_path=""
  local extract_dir=""

  step "Updating Nitrox prerequisites"

  info "Nitrox directory : ${SUBNAUTICA_NITROX_DIR}"
  info "Nitrox version   : ${SUBNAUTICA_NITROX_VERSION}"
  info "Owner            : ${NITROX_OWNER_UID}:${NITROX_OWNER_GID}"

  require_command curl || return 2
  require_command unzip || return 2
  require_command python3 || return 2
  require_command rsync || return 2

  prepare_nitrox_directory || return 1

  download_url="$(get_nitrox_download_url)" || return 1
  archive_path="${NITROX_TMP_DIR}/nitrox-linux-x64.zip"
  extract_dir="${NITROX_TMP_DIR}/extract"

  info "Nitrox archive   : ${download_url}"

  rm -rf "${extract_dir}" || return 1
  mkdir -p "${extract_dir}" || return 1

  curl -fL "${download_url}" -o "${archive_path}" || return 1
  unzip -oq "${archive_path}" -d "${extract_dir}" || return 1

  rsync -a --delete "${extract_dir}/" "${SUBNAUTICA_NITROX_DIR}/" || return 1

  if [[ -f "${SUBNAUTICA_NITROX_DIR}/Nitrox.Server.Subnautica" ]]; then
    chmod +x "${SUBNAUTICA_NITROX_DIR}/Nitrox.Server.Subnautica" || return 1
  fi

  chown -R "${NITROX_OWNER_UID}:${NITROX_OWNER_GID}" "${SUBNAUTICA_NITROX_DIR}" || return 1

  if ! is_enabled "${NITROX_KEEP_ARCHIVE}"; then
    rm -f "${archive_path}" || return 1
  fi

  rm -rf "${extract_dir}" || return 1
  ok "Nitrox prerequisites are installed"
}

update_subnautica_server() {
  if ! is_enabled "${SUBNAUTICA_ENABLED}"; then
    warn "Subnautica update is disabled by SUBNAUTICA_ENABLED=${SUBNAUTICA_ENABLED}"
    return 0
  fi

  update_game "Subnautica" "264710" "${SUBNAUTICA_INSTALL_DIR}" "windows" "account" || return $?
  install_nitrox_release
}

# -----------------------------------------------------------------------------
# Games to update with SteamCMD
# Format:
#   "Name|AppID|Directory|Platform|LoginMode"
# -----------------------------------------------------------------------------

GAMES=(
  "StarRupture|3809400|/opt/gaming/starrupture|windows|anonymous"
  "Abiotic Factor|2857200|/opt/gaming/abioticfactor|windows|anonymous"
)

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  local total=0
  local success=0
  local failed=0

  local game=""
  local name=""
  local app_id=""
  local install_dir=""
  local platform=""
  local login_mode=""

  step "SteamCMD game server updates"

  for game in "${GAMES[@]}"; do
    IFS='|' read -r name app_id install_dir platform login_mode <<< "${game}"

    total=$((total + 1))

    if update_game "${name}" "${app_id}" "${install_dir}" "${platform}" "${login_mode}"; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
    fi
  done

  total=$((total + 1))

  if update_subnautica_server; then
    success=$((success + 1))
  else
    failed=$((failed + 1))
  fi

  step "Summary"

  info "Games processed : ${total}"
  ok "Successful      : ${success}"

  if [[ ${failed} -gt 0 ]]; then
    fail "Failed          : ${failed}"
    return 1
  fi

  ok "All updates completed"
  return 0
}

main "$@"
