#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

# =============================================================================
# Script      : configureGaming.sh
# Purpose     : Configure the VPS firewall and automatic server updates
# Author      : Monolithoid
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG_FILE="${SCRIPT_DIR}/configureGaming.env"
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

load_config_file() {
  local config_file="$1"

  if [[ -f "${config_file}" ]]; then
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
  FIREWALL_TOOL
  DRY_RUN
  UPDATE_CRON_ENABLED
  UPDATE_CRON_HOUR
  UPDATE_CRON_MINUTE
  UPDATE_CRON_USER
  UPDATE_CRON_FILE
  UPDATE_SCRIPT
  UPDATE_CRON_LOG_FILE
  UPDATE_CRON_LOCK_FILE
  RUST_FIREWALL_ENABLED
  ASSETTO_CORSA_FIREWALL_ENABLED
  STARRUPTURE_FIREWALL_ENABLED
  ABIOTIC_FACTOR_FIREWALL_ENABLED
  ICARUS_FIREWALL_ENABLED
  NITROX_FIREWALL_ENABLED
  RUST_SERVER_PORT
  RUST_RCON_PORT
  RUST_QUERY_PORT
  ASSETTO_CORSA_GAME_PORT
  ASSETTO_CORSA_HTTP_PORT
  STARRUPTURE_GAME_PORT
  ABIOTIC_FACTOR_GAME_PORT
  ABIOTIC_FACTOR_QUERY_PORT
  ICARUS_GAME_PORT
  ICARUS_QUERY_PORT
  NITROX_GAME_PORT
)

remember_config_overrides "${CONFIG_VARIABLES[@]}"
load_config_file "${CONFIG_FILE}" || exit $?
restore_config_overrides "${CONFIG_VARIABLES[@]}"

FIREWALL_TOOL="${FIREWALL_TOOL:-ufw}"
DRY_RUN="${DRY_RUN:-0}"

UPDATE_CRON_ENABLED="${UPDATE_CRON_ENABLED:-1}"
UPDATE_CRON_HOUR="${UPDATE_CRON_HOUR:-2}"
UPDATE_CRON_MINUTE="${UPDATE_CRON_MINUTE:-0}"
UPDATE_CRON_USER="${UPDATE_CRON_USER:-root}"
UPDATE_CRON_FILE="${UPDATE_CRON_FILE:-/etc/cron.d/steamcmd-servers-update}"
UPDATE_SCRIPT="${UPDATE_SCRIPT:-${SCRIPT_DIR}/updateGaming.sh}"
UPDATE_CRON_LOG_FILE="${UPDATE_CRON_LOG_FILE:-/var/log/steamcmd-servers-update.log}"
UPDATE_CRON_LOCK_FILE="${UPDATE_CRON_LOCK_FILE:-/run/lock/steamcmd-servers-update.lock}"
UPDATE_CRON_TEMPORARY_FILE=""

RUST_FIREWALL_ENABLED="${RUST_FIREWALL_ENABLED:-1}"
ASSETTO_CORSA_FIREWALL_ENABLED="${ASSETTO_CORSA_FIREWALL_ENABLED:-1}"
STARRUPTURE_FIREWALL_ENABLED="${STARRUPTURE_FIREWALL_ENABLED:-1}"
ABIOTIC_FACTOR_FIREWALL_ENABLED="${ABIOTIC_FACTOR_FIREWALL_ENABLED:-1}"
ICARUS_FIREWALL_ENABLED="${ICARUS_FIREWALL_ENABLED:-1}"
NITROX_FIREWALL_ENABLED="${NITROX_FIREWALL_ENABLED:-1}"

RUST_SERVER_PORT="${RUST_SERVER_PORT:-28015}"
RUST_RCON_PORT="${RUST_RCON_PORT:-28016}"
RUST_QUERY_PORT="${RUST_QUERY_PORT:-28017}"

ASSETTO_CORSA_GAME_PORT="${ASSETTO_CORSA_GAME_PORT:-9600}"
ASSETTO_CORSA_HTTP_PORT="${ASSETTO_CORSA_HTTP_PORT:-8081}"

STARRUPTURE_GAME_PORT="${STARRUPTURE_GAME_PORT:-7777}"

ABIOTIC_FACTOR_GAME_PORT="${ABIOTIC_FACTOR_GAME_PORT:-7777}"
ABIOTIC_FACTOR_QUERY_PORT="${ABIOTIC_FACTOR_QUERY_PORT:-27015}"

ICARUS_GAME_PORT="${ICARUS_GAME_PORT:-17777}"
ICARUS_QUERY_PORT="${ICARUS_QUERY_PORT:-27015}"

NITROX_GAME_PORT="${NITROX_GAME_PORT:-11000}"

require_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    return 0
  fi

  fail "Required command not found: ${command_name}"
  return 1
}

validate_integer_between() {
  local variable_name="$1"
  local value="$2"
  local minimum="$3"
  local maximum="$4"

  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    fail "${variable_name} must be an integer between ${minimum} and ${maximum}"
    return 1
  fi

  if ((10#${value} < minimum || 10#${value} > maximum)); then
    fail "${variable_name} must be between ${minimum} and ${maximum}: ${value}"
    return 1
  fi

  return 0
}

validate_cron_path() {
  local variable_name="$1"
  local path_value="$2"

  if [[ "${path_value}" != /* ]]; then
    fail "${variable_name} must be an absolute path: ${path_value}"
    return 1
  fi

  if [[ "${path_value}" == *$'\n'* || "${path_value}" == *%* ]]; then
    fail "${variable_name} contains a character that cron cannot safely use"
    return 1
  fi

  return 0
}

quote_for_shell() {
  local value="$1"

  value="${value//\'/\'\\\'\'}"
  printf "'%s'" "${value}"
}

cleanup_update_cron_temp_file() {
  if [[ -n "${UPDATE_CRON_TEMPORARY_FILE}" ]]; then
    rm -f "${UPDATE_CRON_TEMPORARY_FILE}"
  fi
}

run_command() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '  [DRY-RUN]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

allow_ufw_port() {
  local port="$1"
  local protocol="$2"
  local label="$3"

  info "Allowing ${label}: ${port}/${protocol}"

  if run_command "${FIREWALL_TOOL}" allow "${port}/${protocol}" comment "steamcmd-servers ${label}"; then
    ok "Allowed ${port}/${protocol} for ${label}"
    return 0
  fi

  fail "Unable to allow ${port}/${protocol} for ${label}"
  return 1
}

configure_rust_ports() {
  step "Configuring Rust firewall ports"

  if [[ "${RUST_FIREWALL_ENABLED}" != "1" ]]; then
    warn "Rust firewall rules are disabled (RUST_FIREWALL_ENABLED=${RUST_FIREWALL_ENABLED})"
    return 0
  fi

  allow_ufw_port "${RUST_SERVER_PORT}" "udp" "rust-server" || return $?
  allow_ufw_port "${RUST_RCON_PORT}" "udp" "rust-rcon" || return $?
  allow_ufw_port "${RUST_QUERY_PORT}" "tcp" "rust-query" || return $?

  return 0
}

configure_assetto_corsa_ports() {
  step "Configuring Assetto Corsa firewall ports"

  if [[ "${ASSETTO_CORSA_FIREWALL_ENABLED}" != "1" ]]; then
    warn "Assetto Corsa firewall rules are disabled (ASSETTO_CORSA_FIREWALL_ENABLED=${ASSETTO_CORSA_FIREWALL_ENABLED})"
    return 0
  fi

  allow_ufw_port "${ASSETTO_CORSA_GAME_PORT}" "tcp" "assetto-corsa-game" || return $?
  allow_ufw_port "${ASSETTO_CORSA_GAME_PORT}" "udp" "assetto-corsa-game" || return $?
  allow_ufw_port "${ASSETTO_CORSA_HTTP_PORT}" "tcp" "assetto-corsa-http" || return $?

  return 0
}

configure_starrupture_ports() {
  step "Configuring StarRupture firewall ports"

  if [[ "${STARRUPTURE_FIREWALL_ENABLED}" != "1" ]]; then
    warn "StarRupture firewall rules are disabled (STARRUPTURE_FIREWALL_ENABLED=${STARRUPTURE_FIREWALL_ENABLED})"
    return 0
  fi

  allow_ufw_port "${STARRUPTURE_GAME_PORT}" "udp" "starrupture-game" || return $?

  return 0
}

configure_abiotic_factor_ports() {
  step "Configuring Abiotic Factor firewall ports"

  if [[ "${ABIOTIC_FACTOR_FIREWALL_ENABLED}" != "1" ]]; then
    warn "Abiotic Factor firewall rules are disabled (ABIOTIC_FACTOR_FIREWALL_ENABLED=${ABIOTIC_FACTOR_FIREWALL_ENABLED})"
    return 0
  fi

  allow_ufw_port "${ABIOTIC_FACTOR_GAME_PORT}" "udp" "abiotic-factor-game" || return $?
  allow_ufw_port "${ABIOTIC_FACTOR_QUERY_PORT}" "udp" "abiotic-factor-query" || return $?

  return 0
}

configure_icarus_ports() {
  step "Configuring ICARUS firewall ports"

  if [[ "${ICARUS_FIREWALL_ENABLED}" != "1" ]]; then
    warn "ICARUS firewall rules are disabled (ICARUS_FIREWALL_ENABLED=${ICARUS_FIREWALL_ENABLED})"
    return 0
  fi

  allow_ufw_port "${ICARUS_GAME_PORT}" "udp" "icarus-game" || return $?
  allow_ufw_port "${ICARUS_QUERY_PORT}" "udp" "icarus-query" || return $?

  return 0
}

configure_nitrox_ports() {
  step "Configuring Subnautica Nitrox firewall ports"

  if [[ "${NITROX_FIREWALL_ENABLED}" != "1" ]]; then
    warn "Nitrox firewall rules are disabled (NITROX_FIREWALL_ENABLED=${NITROX_FIREWALL_ENABLED})"
    return 0
  fi

  allow_ufw_port "${NITROX_GAME_PORT}" "udp" "nitrox-game" || return $?
  allow_ufw_port "${NITROX_GAME_PORT}" "tcp" "nitrox-game" || return $?

  return 0
}

configure_firewall_ports() {
  local failed=0

  configure_rust_ports || failed=$((failed + 1))
  configure_assetto_corsa_ports || failed=$((failed + 1))
  configure_starrupture_ports || failed=$((failed + 1))
  configure_abiotic_factor_ports || failed=$((failed + 1))
  configure_icarus_ports || failed=$((failed + 1))
  configure_nitrox_ports || failed=$((failed + 1))

  if [[ ${failed} -gt 0 ]]; then
    fail "Firewall configuration failed for ${failed} target group(s)"
    return 1
  fi

  return 0
}

show_firewall_status() {
  step "Firewall status"

  if [[ "${DRY_RUN}" == "1" ]]; then
    warn "Skipping firewall status in dry-run mode"
    return 0
  fi

  run_command "${FIREWALL_TOOL}" status verbose
  return $?
}

write_update_cron_file() {
  local flock_bin="$1"
  local cron_directory=""
  local log_directory=""
  local temporary_file=""
  local quoted_flock=""
  local quoted_lock=""
  local quoted_script=""
  local quoted_log=""

  cron_directory="$(dirname "${UPDATE_CRON_FILE}")"
  log_directory="$(dirname "${UPDATE_CRON_LOG_FILE}")"

  mkdir -p "${cron_directory}" "${log_directory}" "$(dirname "${UPDATE_CRON_LOCK_FILE}")" || return 1
  touch "${UPDATE_CRON_LOG_FILE}" || return 1
  chown "${UPDATE_CRON_USER}" "${UPDATE_CRON_LOG_FILE}" || return 1

  temporary_file="$(mktemp "${cron_directory}/.steamcmd-servers-update.XXXXXXXX")" || return 1
  UPDATE_CRON_TEMPORARY_FILE="${temporary_file}"
  trap cleanup_update_cron_temp_file EXIT

  quoted_flock="$(quote_for_shell "${flock_bin}")"
  quoted_lock="$(quote_for_shell "${UPDATE_CRON_LOCK_FILE}")"
  quoted_script="$(quote_for_shell "${UPDATE_SCRIPT}")"
  quoted_log="$(quote_for_shell "${UPDATE_CRON_LOG_FILE}")"

  {
    printf '%s\n' 'SHELL=/bin/bash'
    printf '%s\n' 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    printf '%s %s * * * %s %s -n %s %s >> %s 2>&1\n' \
      "${UPDATE_CRON_MINUTE}" \
      "${UPDATE_CRON_HOUR}" \
      "${UPDATE_CRON_USER}" \
      "${quoted_flock}" \
      "${quoted_lock}" \
      "${quoted_script}" \
      "${quoted_log}"
  } > "${temporary_file}"

  chmod 0644 "${temporary_file}" || return 1
  mv "${temporary_file}" "${UPDATE_CRON_FILE}" || return 1
  UPDATE_CRON_TEMPORARY_FILE=""
  trap - EXIT
  return 0
}

configure_update_cron() {
  local flock_bin=""
  local formatted_hour=""
  local formatted_minute=""

  step "Configuring automatic server updates"

  if [[ "${UPDATE_CRON_ENABLED}" != "0" && "${UPDATE_CRON_ENABLED}" != "1" ]]; then
    fail "UPDATE_CRON_ENABLED must be 0 or 1: ${UPDATE_CRON_ENABLED}"
    return 1
  fi

  validate_cron_path "UPDATE_CRON_FILE" "${UPDATE_CRON_FILE}" || return 1

  if [[ "${UPDATE_CRON_ENABLED}" != "1" ]]; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      info "Would remove ${UPDATE_CRON_FILE} if it exists"
      return 0
    fi

    if [[ "$(id -u)" -ne 0 ]]; then
      fail "Run configureGaming.sh as root to remove ${UPDATE_CRON_FILE}"
      return 1
    fi

    rm -f "${UPDATE_CRON_FILE}" || return 1
    ok "Automatic updates are disabled"
    return 0
  fi

  validate_integer_between "UPDATE_CRON_HOUR" "${UPDATE_CRON_HOUR}" 0 23 || return 1
  validate_integer_between "UPDATE_CRON_MINUTE" "${UPDATE_CRON_MINUTE}" 0 59 || return 1
  printf -v formatted_hour '%02d' "$((10#${UPDATE_CRON_HOUR}))"
  printf -v formatted_minute '%02d' "$((10#${UPDATE_CRON_MINUTE}))"
  validate_cron_path "UPDATE_SCRIPT" "${UPDATE_SCRIPT}" || return 1
  validate_cron_path "UPDATE_CRON_LOG_FILE" "${UPDATE_CRON_LOG_FILE}" || return 1
  validate_cron_path "UPDATE_CRON_LOCK_FILE" "${UPDATE_CRON_LOCK_FILE}" || return 1

  if [[ ! "${UPDATE_CRON_USER}" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
    fail "UPDATE_CRON_USER is not a valid system user name: ${UPDATE_CRON_USER}"
    return 1
  fi

  if ! id "${UPDATE_CRON_USER}" >/dev/null 2>&1; then
    fail "UPDATE_CRON_USER does not exist: ${UPDATE_CRON_USER}"
    return 1
  fi

  if [[ ! -x "${UPDATE_SCRIPT}" ]]; then
    fail "Update script is missing or not executable: ${UPDATE_SCRIPT}"
    return 1
  fi

  require_command flock || return 1
  flock_bin="$(command -v flock)"

  if [[ "${DRY_RUN}" == "1" ]]; then
    info "Would install ${UPDATE_CRON_FILE} for ${formatted_hour}:${formatted_minute}"
    return 0
  fi

  if [[ "$(id -u)" -ne 0 ]]; then
    fail "Run configureGaming.sh as root to install ${UPDATE_CRON_FILE}"
    return 1
  fi

  if ! write_update_cron_file "${flock_bin}"; then
    fail "Unable to install the automatic update cron file"
    return 1
  fi

  ok "Automatic updates scheduled at ${formatted_hour}:${formatted_minute}"
  info "Cron file: ${UPDATE_CRON_FILE}"
  info "Output log: ${UPDATE_CRON_LOG_FILE}"
  return 0
}

main() {
  step "Configuring VPS game firewall openings"

  if [[ "${FIREWALL_TOOL}" != "ufw" ]]; then
    fail "Unsupported FIREWALL_TOOL=${FIREWALL_TOOL}. Only ufw is currently supported."
    return 2
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    warn "Dry-run mode is enabled; ${FIREWALL_TOOL} does not need to be installed."
  else
    require_command "${FIREWALL_TOOL}" || return 3
  fi

  configure_firewall_ports || return $?
  show_firewall_status || return $?
  configure_update_cron || return $?

  ok "VPS gaming configuration is complete"
  return 0
}

main "$@"
