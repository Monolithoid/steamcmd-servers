#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

# =============================================================================
# Script      : update-games.sh
# Purpose     : Update host-managed game server files
# Author      : Monolithoid
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEAMCMD_BIN="${STEAMCMD_BIN:-steamcmd}"
LOG_DIR="${LOG_DIR:-/tmp/steamcmd-updates}"

NITROX_ENABLED="${NITROX_ENABLED:-1}"
NITROX_RELEASE_REPO="${NITROX_RELEASE_REPO:-SubnauticaNitrox/Nitrox}"
NITROX_VERSION="${NITROX_VERSION:-latest}"
NITROX_ARCH="${NITROX_ARCH:-x64}"
NITROX_INSTALL_DIR="${NITROX_INSTALL_DIR:-/opt/gaming/subnautica-nitrox}"
NITROX_OWNER="${NITROX_OWNER:-1000:1000}"
SUBNAUTICA_INSTALL_DIR="${SUBNAUTICA_INSTALL_DIR:-/opt/gaming/subnautica}"

mkdir -p "${LOG_DIR}"

# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------

step() {
  echo
  printf '==> %s\n' "$1"
}

ok() {
  printf '  [OK] %s\n' "$1"
}

warn() {
  printf '  [WARN] %s\n' "$1"
}

fail() {
  printf '  [FAIL] %s\n' "$1"
}

info() {
  printf '  [INFO] %s\n' "$1"
}

# -----------------------------------------------------------------------------
# Generic helpers
# -----------------------------------------------------------------------------

require_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    return 0
  fi

  fail "Required command not found: ${command_name}"
  return 1
}

make_temp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/gaming-update.XXXXXXXXXX"
}

cleanup_temp_dir() {
  local temp_dir="${1:-}"

  if [[ -n "${temp_dir}" && -d "${temp_dir}" ]]; then
    rm -rf "${temp_dir}"
  fi
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
    fail "SteamCMD failed to install the application"
    return 11
  fi

  if grep -qi "state is 0x6" "${log_file}"; then
    fail "Known SteamCMD transient error: state is 0x6 after update"
    return 12
  fi

  if grep -qi "Invalid platform" "${log_file}"; then
    fail "Invalid platform for this application"
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
    ok "Install/update completed"

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
# SteamCMD game update
# -----------------------------------------------------------------------------

update_steam_game() {
  local name="$1"
  local app_id="$2"
  local install_dir="$3"
  local platform="${4:-windows}"
  local login_mode="${5:-anonymous}"

  local timestamp=""
  local log_file=""
  local rc=0
  local analysis_rc=0
  local steamcmd_args=()

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  safe_name="$(printf '%s' "${name}" | tr '[:upper:] ' '[:lower:]-')"
  log_file="${LOG_DIR}/${safe_name}-${app_id}-${timestamp}.log"

  step "Updating SteamCMD app: ${name}"

  info "App ID       : ${app_id}"
  info "Platform     : ${platform}"
  info "Install dir  : ${install_dir}"
  info "Login mode   : ${login_mode}"
  info "Log          : ${log_file}"

  mkdir -p "${install_dir}"

  steamcmd_args=(
    +@sSteamCmdForcePlatformType "${platform}"
    +force_install_dir "${install_dir}"
  )

  if [[ "${login_mode}" == "account" ]]; then
    if [[ -z "${STEAM_LOGIN:-}" || -z "${STEAM_PASSWORD:-}" ]]; then
      fail "STEAM_LOGIN and STEAM_PASSWORD are required for ${name}"
      return 30
    fi

    steamcmd_args+=(+login "${STEAM_LOGIN}" "${STEAM_PASSWORD}")
  else
    steamcmd_args+=(+login anonymous)
  fi

  steamcmd_args+=(+app_update "${app_id}" validate +quit)

  "${STEAMCMD_BIN}" "${steamcmd_args[@]}" 2>&1 | tee "${log_file}"
  rc=${PIPESTATUS[0]}

  if [[ ${rc} -ne 0 ]]; then
    fail "SteamCMD returned exit code ${rc}"
    analyze_steamcmd_log "${app_id}" "${log_file}" || true
    return "${rc}"
  fi

# Nitrox update
# -----------------------------------------------------------------------------

get_nitrox_release_api_url() {
  if [[ "${NITROX_VERSION}" == "latest" ]]; then
    printf 'https://api.github.com/repos/%s/releases/latest\n' "${NITROX_RELEASE_REPO}"
    return 0
  fi

  printf 'https://api.github.com/repos/%s/releases/tags/%s\n' "${NITROX_RELEASE_REPO}" "${NITROX_VERSION}"
}

update_nitrox() {
  local temp_dir=""
  local release_json=""
  local zip_file=""
  local extract_dir=""
  local api_url=""
  local asset_info=""
  local release_tag=""
  local asset_name=""
  local download_url=""
  local rc=0

  step "Updating Subnautica Nitrox"

  if [[ "${NITROX_ENABLED}" != "1" ]]; then
    warn "Nitrox update is disabled (NITROX_ENABLED=${NITROX_ENABLED})"
    return 0
  fi

  require_command curl || return 40
  require_command python3 || return 40
  require_command unzip || return 40
  require_command rsync || return 40

  if [[ ! -d "${SUBNAUTICA_INSTALL_DIR}/Subnautica_Data" ]]; then
    warn "Subnautica_Data was not found under ${SUBNAUTICA_INSTALL_DIR}"
    warn "Copy the Steam game files there manually before starting the server."
  fi

  temp_dir="$(make_temp_dir)" || return 41
  release_json="${temp_dir}/nitrox-release.json"
  zip_file="${temp_dir}/nitrox.zip"
  extract_dir="${temp_dir}/extract"

  api_url="$(get_nitrox_release_api_url)"
  info "Release API  : ${api_url}"
  info "Install dir  : ${NITROX_INSTALL_DIR}"
  info "Owner        : ${NITROX_OWNER}"

  if ! curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: steamcmd-servers-update-script" \
    "${api_url}" \
    -o "${release_json}"; then
    cleanup_temp_dir "${temp_dir}"
    fail "Unable to fetch the Nitrox release metadata"
    return 42
  fi

  if ! asset_info="$(python3 "${SCRIPT_DIR}/nitrox_release_asset.py" "${release_json}" "${NITROX_ARCH}")"; then
    cleanup_temp_dir "${temp_dir}"
    fail "Unable to select a Nitrox Linux ${NITROX_ARCH} release asset"
    return 43
  fi

  release_tag="$(printf '%s\n' "${asset_info}" | sed -n '1p')"
  asset_name="$(printf '%s\n' "${asset_info}" | sed -n '2p')"
  download_url="$(printf '%s\n' "${asset_info}" | sed -n '3p')"

  info "Release      : ${release_tag}"
  info "Asset        : ${asset_name}"

  if ! curl -fL "${download_url}" -o "${zip_file}"; then
    cleanup_temp_dir "${temp_dir}"
    fail "Unable to download ${asset_name}"
    return 44
  fi

  mkdir -p "${extract_dir}" "${NITROX_INSTALL_DIR}"

  if ! unzip -q "${zip_file}" -d "${extract_dir}"; then
    cleanup_temp_dir "${temp_dir}"
    fail "Unable to extract ${asset_name}"
    return 45
  fi

  rsync -a \
    --exclude 'Nitrox/saves/' \
    --exclude 'Nitrox/saves/***' \
    --exclude 'Nitrox/server.cfg' \
    "${extract_dir}/" \
    "${NITROX_INSTALL_DIR}/"
  rc=$?

  if [[ ${rc} -ne 0 ]]; then
    cleanup_temp_dir "${temp_dir}"
    fail "Unable to sync Nitrox files"
    return "${rc}"
  fi

  if [[ -f "${NITROX_INSTALL_DIR}/Nitrox.Server.Subnautica" ]]; then
    if ! chmod +x "${NITROX_INSTALL_DIR}/Nitrox.Server.Subnautica"; then
      cleanup_temp_dir "${temp_dir}"
      fail "Unable to mark Nitrox.Server.Subnautica as executable"
      return 46
    fi
  fi

  if ! chown -R "${NITROX_OWNER}" "${NITROX_INSTALL_DIR}"; then
    cleanup_temp_dir "${temp_dir}"
    fail "Unable to set ownership on ${NITROX_INSTALL_DIR}"
    return 47
  fi

  cleanup_temp_dir "${temp_dir}"
  ok "Nitrox ${release_tag} is installed in ${NITROX_INSTALL_DIR}"
  return 0
}

# -----------------------------------------------------------------------------
# Update targets
# Format:
#   "Name|AppID|Directory|Platform|LoginMode"
#
# Subnautica itself is intentionally not listed here. Copy the Steam game folder
# manually to SUBNAUTICA_INSTALL_DIR, then let the Nitrox target update the mod.
# -----------------------------------------------------------------------------

STEAM_GAMES=(
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

  step "Updating host-managed game server files"

  for game in "${STEAM_GAMES[@]}"; do
    IFS='|' read -r name app_id install_dir platform login_mode <<< "${game}"

    total=$((total + 1))


    if update_steam_game "${name}" "${app_id}" "${install_dir}" "${platform}" "${login_mode}"; then

      success=$((success + 1))
    else
      failed=$((failed + 1))
    fi
  done

  total=$((total + 1))

  if update_nitrox; then
    success=$((success + 1))
  else
    failed=$((failed + 1))
  fi

  step "Summary"

  info "Targets processed : ${total}"
  ok "Successful        : ${success}"

  if [[ ${failed} -gt 0 ]]; then
    fail "Failed            : ${failed}"
    return 1
  fi

  ok "All updates completed"
  return 0
}

main "$@"
