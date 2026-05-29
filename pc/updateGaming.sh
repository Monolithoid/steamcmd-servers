#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

# =============================================================================
# Script      : updateGaming.sh
# Purpose     : Update account-bound Steam apps locally, then copy them to a VPS
# Author      : Monolithoid
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG_FILE="${SCRIPT_DIR}/updateGaming.env"
CONFIG_FILE_WAS_SET=0

if [[ -n "${CONFIG_FILE:-}" ]]; then
  CONFIG_FILE_WAS_SET=1
else
  CONFIG_FILE="${DEFAULT_CONFIG_FILE}"
fi

remember_config_overrides() {
  local variable_name=""
  local value_name=""
  local flag_name=""

  for variable_name in "$@"; do
    value_name="CONFIG_ORIGINAL_${variable_name}"
    flag_name="CONFIG_ORIGINAL_${variable_name}_WAS_SET"

    if [[ -n "${!variable_name+x}" ]]; then
      printf -v "${flag_name}" '%s' "1"
      printf -v "${value_name}" '%s' "${!variable_name}"
    else
      printf -v "${flag_name}" '%s' "0"
    fi
  done
}

restore_config_overrides() {
  local variable_name=""
  local value_name=""
  local flag_name=""

  for variable_name in "$@"; do
    value_name="CONFIG_ORIGINAL_${variable_name}"
    flag_name="CONFIG_ORIGINAL_${variable_name}_WAS_SET"

    if [[ "${!flag_name:-0}" == "1" ]]; then
      printf -v "${variable_name}" '%s' "${!value_name}"
    fi
  done
}

reject_account_credentials_in_config_file() {
  local config_file="$1"
  local line=""

  while IFS= read -r line; do
    if [[ "${line}" =~ ^[[:space:]]*(export[[:space:]]+)?(STEAM_LOGIN|STEAM_PASSWORD|STEAM_GUARD_CODE)[[:space:]]*= ]]; then
      fail "Do not store Steam account credentials in ${config_file}"
      info "Remove STEAM_LOGIN, STEAM_PASSWORD, and STEAM_GUARD_CODE from the config file."
      info "Run the script from a terminal so it can ask for account details securely at runtime."
      return 1
    fi
  done < "${config_file}"

  return 0
}

load_config_file() {
  local config_file="$1"

  if [[ -f "${config_file}" ]]; then
    reject_account_credentials_in_config_file "${config_file}" || return $?

    # shellcheck disable=SC1090
    source "${config_file}"
    return 0
  fi

  if [[ ${CONFIG_FILE_WAS_SET} -eq 1 ]]; then
    fail "Config file not found: ${config_file}"
    return 1
  fi

  return 0
}

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

CONFIG_VARIABLES=(
  STEAMCMD_BIN
  LOG_DIR
  PC_STEAM_APPS_DIR
  VPS_SSH_TARGET
  VPS_SSH_PORT
  VPS_BASE_DIR
  VPS_OWNER
  VPS_SUDO
  VPS_RSYNC_PATH
  PC_RSYNC_DELETE
  PC_RSYNC_COMPRESS
  PC_RSYNC_EXTRA_ARGS
  ASSETTO_CORSA_ENABLED
  SUBNAUTICA_ENABLED
  ASSETTO_CORSA_LOCAL_DIR
  SUBNAUTICA_LOCAL_DIR
  ASSETTO_CORSA_REMOTE_DIR
  SUBNAUTICA_REMOTE_DIR
  STEAM_LOGIN
  STEAM_PASSWORD
  STEAM_GUARD_CODE
)

remember_config_overrides "${CONFIG_VARIABLES[@]}"
load_config_file "${CONFIG_FILE}" || exit $?
restore_config_overrides "${CONFIG_VARIABLES[@]}"

STEAMCMD_BIN="${STEAMCMD_BIN:-steamcmd}"
LOG_DIR="${LOG_DIR:-${HOME}/steamcmd-servers/logs}"
PC_STEAM_APPS_DIR="${PC_STEAM_APPS_DIR:-${HOME}/steamcmd-servers/apps}"

VPS_SSH_TARGET="${VPS_SSH_TARGET:-}"
VPS_SSH_PORT="${VPS_SSH_PORT:-22}"
VPS_BASE_DIR="${VPS_BASE_DIR:-/opt/gaming}"
VPS_OWNER="${VPS_OWNER:-1000:1000}"
VPS_SUDO="${VPS_SUDO:-sudo}"
VPS_RSYNC_PATH="${VPS_RSYNC_PATH:-sudo rsync}"

PC_RSYNC_DELETE="${PC_RSYNC_DELETE:-1}"
PC_RSYNC_COMPRESS="${PC_RSYNC_COMPRESS:-1}"
PC_RSYNC_EXTRA_ARGS="${PC_RSYNC_EXTRA_ARGS:-}"

ASSETTO_CORSA_ENABLED="${ASSETTO_CORSA_ENABLED:-1}"
SUBNAUTICA_ENABLED="${SUBNAUTICA_ENABLED:-1}"

ASSETTO_CORSA_LOCAL_DIR="${ASSETTO_CORSA_LOCAL_DIR:-${PC_STEAM_APPS_DIR}/assetto-corsa}"
SUBNAUTICA_LOCAL_DIR="${SUBNAUTICA_LOCAL_DIR:-${PC_STEAM_APPS_DIR}/subnautica}"

ASSETTO_CORSA_REMOTE_DIR="${ASSETTO_CORSA_REMOTE_DIR:-${VPS_BASE_DIR}/assetto-corsa}"
SUBNAUTICA_REMOTE_DIR="${SUBNAUTICA_REMOTE_DIR:-${VPS_BASE_DIR}/subnautica}"

mkdir -p "${LOG_DIR}" "${PC_STEAM_APPS_DIR}"

require_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    return 0
  fi

  fail "Required command not found: ${command_name}"
  return 1
}

slugify() {
  printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-'
}

is_interactive() {
  [[ -t 0 && -t 1 ]]
}

read_config_value() {
  local variable_name="$1"
  local prompt="$2"
  local secret="${3:-0}"
  local entered_value=""

  if [[ -n "${!variable_name:-}" ]]; then
    return 0
  fi

  if ! is_interactive; then
    return 1
  fi

  if [[ "${secret}" == "1" ]]; then
    printf '%s: ' "${prompt}"
    read -r -s entered_value
    printf '\n'
  else
    printf '%s: ' "${prompt}"
    read -r entered_value
  fi

  if [[ -z "${entered_value}" ]]; then
    return 1
  fi

  printf -v "${variable_name}" '%s' "${entered_value}"
  return 0
}

detect_vps_target() {
  local detected_target=""

  if [[ -n "${VPS_SSH_TARGET}" ]]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    return 1
  fi

  detected_target="$(git config --get steamcmd-servers.vpsSshTarget || true)"

  if [[ -z "${detected_target}" ]]; then
    return 1
  fi

  VPS_SSH_TARGET="${detected_target}"
  info "Detected VPS_SSH_TARGET from git config: ${VPS_SSH_TARGET}"
  return 0
}

prompt_for_missing_settings() {
  detect_vps_target || true

  read_config_value STEAM_LOGIN "Steam login" 0 || true
  read_config_value STEAM_PASSWORD "Steam password" 1 || true
  read_config_value VPS_SSH_TARGET "VPS SSH target (user@example.org)" 0 || true
}

require_account() {
  if [[ -z "${STEAM_LOGIN:-}" || -z "${STEAM_PASSWORD:-}" ]]; then
    fail "STEAM_LOGIN and STEAM_PASSWORD are required for account-bound Steam apps"
    return 1
  fi

  return 0
}

require_vps_target() {
  if [[ -z "${VPS_SSH_TARGET}" ]]; then
    fail "VPS_SSH_TARGET is required, for example user@example.org"
    return 1
  fi

  return 0
}

analyze_steamcmd_log() {
  local app_id="$1"
  local log_file="$2"

  if grep -qi "No subscription" "${log_file}"; then
    fail "Access denied: No subscription"
    return 10
  fi

  if grep -qi "Two-factor code mismatch\|Invalid Password\|Login Failure" "${log_file}"; then
    fail "Steam authentication failed"
    return 11
  fi

  if grep -qi "ERROR! Failed to install app" "${log_file}"; then
    fail "SteamCMD failed to install the application"
    return 12
  fi

  if grep -qi "Timeout\|timed out\|connection.*failed\|Network is unreachable" "${log_file}"; then
    fail "Network error during update"
    return 13
  fi

  if grep -qi "Disk write failure\|No space left on device\|Permission denied" "${log_file}"; then
    fail "Disk or permission error"
    return 14
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
    return 15
  fi

  warn "SteamCMD finished, but the status was not recognized"
  return 20
}

update_account_app() {
  local name="$1"
  local app_id="$2"
  local local_dir="$3"
  local platform="$4"
  local timestamp=""
  local log_file=""
  local safe_name=""
  local rc=0
  local steamcmd_args=()

  require_account || return 30

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  safe_name="$(slugify "${name}")"
  log_file="${LOG_DIR}/${safe_name}-${app_id}-${timestamp}.log"

  step "Updating account-bound Steam app: ${name}"

  info "App ID       : ${app_id}"
  info "Platform     : ${platform}"
  info "Local dir    : ${local_dir}"
  info "Log          : ${log_file}"

  require_command "${STEAMCMD_BIN}" || return 31

  mkdir -p "${local_dir}"

  steamcmd_args=(
    +force_install_dir "${local_dir}"
  )

  if [[ "${platform}" != "linux" ]]; then
    steamcmd_args=(
      +@sSteamCmdForcePlatformType "${platform}"
      "${steamcmd_args[@]}"
    )
  fi

  if [[ -n "${STEAM_GUARD_CODE:-}" ]]; then
    steamcmd_args+=(+set_steam_guard_code "${STEAM_GUARD_CODE}")
  fi

  steamcmd_args+=(+login "${STEAM_LOGIN}" "${STEAM_PASSWORD}")
  steamcmd_args+=(+app_update "${app_id}" validate +quit)

  "${STEAMCMD_BIN}" "${steamcmd_args[@]}" 2>&1 | tee "${log_file}"
  rc=${PIPESTATUS[0]}

  if [[ ${rc} -ne 0 ]]; then
    fail "SteamCMD returned exit code ${rc}"
    analyze_steamcmd_log "${app_id}" "${log_file}" || true
    return "${rc}"
  fi

  analyze_steamcmd_log "${app_id}" "${log_file}"
  return $?
}

build_rsync_args() {
  local rsync_args=(-a --human-readable --info=stats2,progress2)

  if [[ "${PC_RSYNC_DELETE}" == "1" ]]; then
    rsync_args+=(--delete)
  fi

  if [[ "${PC_RSYNC_COMPRESS}" == "1" ]]; then
    rsync_args+=(-z)
  fi

  if [[ -n "${PC_RSYNC_EXTRA_ARGS}" ]]; then
    # shellcheck disable=SC2206
    rsync_args+=(${PC_RSYNC_EXTRA_ARGS})
  fi

  printf '%s\n' "${rsync_args[@]}"
}

prepare_remote_dir() {
  local remote_dir="$1"
  local remote_command="mkdir -p '${remote_dir}'"

  if [[ -n "${VPS_SUDO}" ]]; then
    remote_command="${VPS_SUDO} mkdir -p '${remote_dir}' && ${VPS_SUDO} chown '${VPS_OWNER}' '${remote_dir}'"
  fi

  ssh -p "${VPS_SSH_PORT}" "${VPS_SSH_TARGET}" "${remote_command}"
}

set_remote_owner() {
  local remote_dir="$1"
  local remote_command="chown -R '${VPS_OWNER}' '${remote_dir}'"

  if [[ -n "${VPS_SUDO}" ]]; then
    remote_command="${VPS_SUDO} ${remote_command}"
  fi

  ssh -p "${VPS_SSH_PORT}" "${VPS_SSH_TARGET}" "${remote_command}"
}

copy_app_to_vps() {
  local name="$1"
  local local_dir="$2"
  local remote_dir="$3"
  local rc=0
  local rsync_args=()

  require_vps_target || return 50
  require_command ssh || return 51
  require_command rsync || return 51

  step "Copying ${name} to VPS"

  info "Source       : ${local_dir}/"
  info "Destination  : ${VPS_SSH_TARGET}:${remote_dir}/"
  info "SSH port     : ${VPS_SSH_PORT}"
  info "Owner        : ${VPS_OWNER}"
  info "Remote rsync : ${VPS_RSYNC_PATH}"

  if [[ ! -d "${local_dir}" ]]; then
    fail "Local directory does not exist: ${local_dir}"
    return 52
  fi

  if ! prepare_remote_dir "${remote_dir}"; then
    fail "Unable to prepare remote directory ${remote_dir}"
    return 53
  fi

  mapfile -t rsync_args < <(build_rsync_args)

  rsync "${rsync_args[@]}" \
    --rsync-path "${VPS_RSYNC_PATH}" \
    -e "ssh -p ${VPS_SSH_PORT}" \
    "${local_dir}/" \
    "${VPS_SSH_TARGET}:${remote_dir}/"
  rc=$?

  if [[ ${rc} -ne 0 ]]; then
    fail "rsync failed with exit code ${rc}"
    return "${rc}"
  fi

  if ! set_remote_owner "${remote_dir}"; then
    fail "Unable to set remote ownership on ${remote_dir}"
    return 54
  fi

  ok "${name} copied to ${remote_dir}"
  return 0
}

run_target() {
  local enabled="$1"
  local name="$2"
  local app_id="$3"
  local local_dir="$4"
  local remote_dir="$5"
  local platform="$6"

  if [[ "${enabled}" != "1" ]]; then
    warn "Skipping ${name} (enabled=${enabled})"
    return 0
  fi

  update_account_app "${name}" "${app_id}" "${local_dir}" "${platform}" || return $?
  copy_app_to_vps "${name}" "${local_dir}" "${remote_dir}"
  return $?
}

main() {
  local total=0
  local success=0
  local failed=0

  step "Updating account-bound apps locally, then copying them to the VPS"
  prompt_for_missing_settings

  total=$((total + 1))
  if run_target "${ASSETTO_CORSA_ENABLED}" "Assetto Corsa Dedicated Server" "302550" "${ASSETTO_CORSA_LOCAL_DIR}" "${ASSETTO_CORSA_REMOTE_DIR}" "windows"; then
    success=$((success + 1))
  else
    failed=$((failed + 1))
  fi

  total=$((total + 1))
  if run_target "${SUBNAUTICA_ENABLED}" "Subnautica" "264710" "${SUBNAUTICA_LOCAL_DIR}" "${SUBNAUTICA_REMOTE_DIR}" "windows"; then
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

  ok "All updates and copies completed"
  return 0
}

main "$@"
