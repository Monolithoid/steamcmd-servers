#!/usr/bin/env bash
set -euo pipefail

: "${NITROX_WORKDIR:=/opt/nitrox}"
: "${NITROX_SAVES_DIR:=${NITROX_WORKDIR}/Nitrox/saves}"
: "${NITROX_DATA_PATH:=${NITROX_WORKDIR}/Nitrox}"
: "${SUBNAUTICA_INSTALLATION_PATH:=/subnautica}"
: "${SERVER_WORLD_NAME:=My World}"
: "${SERVER_CFG_PATH:=}"
: "${SERVER_PASSWORD:=}"
: "${SERVER_GAMEMODE:=1}"
: "${SERVER_COMMANDS_ENABLED:=true}"
: "${SERVER_PVP_ENABLED:=false}"
: "${SERVER_KEEP_INVENTORY:=false}"
: "${SERVER_BINARY:=}"
: "${SERVER_ARGS:=}"
: "${START_SERVER:=1}"
: "${ENABLE_TERMINAL:=0}"

log_message() {
  echo "[subnautica-nitrox] $*"
}

normalize_boolean() {
  local value="$1"
  local normalized_value=""

  normalized_value="$(echo "${value}" | tr '[:upper:]' '[:lower:]')"

  if [[ "${normalized_value}" == "1" ]]; then
    echo "true"
    return 0
  fi

  if [[ "${normalized_value}" == "yes" ]]; then
    echo "true"
    return 0
  fi

  if [[ "${normalized_value}" == "on" ]]; then
    echo "true"
    return 0
  fi

  if [[ "${normalized_value}" == "true" ]]; then
    echo "true"
    return 0
  fi

  echo "false"
}

get_config_path() {
  if [[ -n "${SERVER_CFG_PATH}" ]]; then
    echo "${SERVER_CFG_PATH}"
    return 0
  fi

  echo "${NITROX_SAVES_DIR}/${SERVER_WORLD_NAME}/server.cfg"
}

write_config_value() {
  local key="$1"
  local value="$2"
  local config_path="$3"

  printf '%s=%s\n' "${key}" "${value}" >> "${config_path}"
}

write_prefixed_config_values() {
  local config_path="$1"
  local variable_name=""
  local config_key=""
  local config_value=""

  while IFS='=' read -r variable_name config_value; do
    if [[ "${variable_name}" != NITROX_CFG_* ]]; then
      continue
    fi

    config_key="${variable_name#NITROX_CFG_}"
    write_config_value "${config_key}" "${config_value}" "${config_path}"
  done < <(env | sort)
}

write_server_config() {
  local config_path=""
  local commands_enabled=""
  local disable_console="false"
  local pvp_enabled=""
  local keep_inventory=""

  config_path="$(get_config_path)"
  commands_enabled="$(normalize_boolean "${SERVER_COMMANDS_ENABLED}")"
  pvp_enabled="$(normalize_boolean "${SERVER_PVP_ENABLED}")"
  keep_inventory="$(normalize_boolean "${SERVER_KEEP_INVENTORY}")"

  if [[ "${commands_enabled}" == "false" ]]; then
    disable_console="true"
  fi

  mkdir -p "$(dirname "${config_path}")"

  {
    write_config_value "Name" "${SERVER_WORLD_NAME}" "/dev/stdout"
    write_config_value "Password" "${SERVER_PASSWORD}" "/dev/stdout"
    write_config_value "GameMode" "${SERVER_GAMEMODE}" "/dev/stdout"
    write_config_value "DisableConsole" "${disable_console}" "/dev/stdout"
    write_config_value "PvpEnabled" "${pvp_enabled}" "/dev/stdout"
    write_config_value "KeepInventoryOnDeath" "${keep_inventory}" "/dev/stdout"
  } > "${config_path}"

  write_prefixed_config_values "${config_path}"
  log_message "Wrote server config to ${config_path}."
}

find_server_binary() {
  local binary_path=""

  if [[ -n "${SERVER_BINARY}" ]]; then
    echo "${SERVER_BINARY}"
    return 0
  fi

  binary_path="$(find "${NITROX_WORKDIR}" -maxdepth 4 -type f -name "Nitrox.Server.Subnautica" | head -n 1)"

  if [[ -n "${binary_path}" ]]; then
    echo "${binary_path}"
    return 0
  fi

  binary_path="$(find "${NITROX_WORKDIR}" -maxdepth 4 -type f -name "Nitrox.Server.Subnautica.dll" | head -n 1)"

  if [[ -n "${binary_path}" ]]; then
    echo "dotnet ${binary_path}"
    return 0
  fi

  log_message "Unable to find Nitrox.Server.Subnautica in ${NITROX_WORKDIR}."
  return 1
}

open_terminal_mode() {
  log_message "Terminal mode active. Opening a shell in ${NITROX_WORKDIR}."
  cd "${NITROX_WORKDIR}"

  if [[ -t 0 || -t 1 ]]; then
    exec /bin/bash -l
  fi

  log_message "No TTY detected. Keeping container alive for later attachment."
  exec tail -f /dev/null
}

validate_subnautica_path() {
  if [[ -d "${SUBNAUTICA_INSTALLATION_PATH}/Subnautica_Data" ]]; then
    return 0
  fi

  log_message "Warning: ${SUBNAUTICA_INSTALLATION_PATH}/Subnautica_Data was not found."
  log_message "Mount a valid Subnautica installation at SUBNAUTICA_INSTALLATION_PATH."
}

start_server() {
  local server_binary=""
  local launch_command=""

  validate_subnautica_path
  server_binary="$(find_server_binary)"
  launch_command="${server_binary} --game-path \"${SUBNAUTICA_INSTALLATION_PATH}\" --data-path \"${NITROX_DATA_PATH}\" ${SERVER_ARGS}"

  log_message "Starting Nitrox server: ${launch_command}"
  cd "${NITROX_WORKDIR}"
  exec /bin/bash -lc "${launch_command}"
}

main() {
  mkdir -p "${NITROX_SAVES_DIR}" "${NITROX_DATA_PATH}"
  write_server_config

  if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
    open_terminal_mode
  fi

  if [[ "${START_SERVER}" == "1" ]]; then
    start_server
  fi

  log_message "START_SERVER=0, no server launched."
}

main "$@"
