#!/usr/bin/env bash
set -euo pipefail

: "${SERVER_DIR:=/opt/server}"
: "${SR_WRITE_DSSETTINGS:=1}"
: "${SR_DSSETTINGS_PATH:=${SERVER_DIR}/DSSettings.txt}"
: "${SR_SESSION_NAME:=StarRuptureServer}"
: "${SR_SAVE_GAME_INTERVAL:=300}"
: "${SR_START_NEW_GAME:=false}"
: "${SR_LOAD_SAVED_GAME:=true}"
: "${SR_SAVE_GAME_NAME:=AutoSave0.sav}"
: "${SR_ADMIN_PASSWORD_JSON:=}"
: "${SR_PLAYER_PASSWORD_JSON:=}"

print_settings_summary() {
  echo "[starrupture] SR_WRITE_DSSETTINGS=${SR_WRITE_DSSETTINGS}"
  echo "[starrupture] SR_DSSETTINGS_PATH=${SR_DSSETTINGS_PATH}"
  echo "[starrupture] SR_SESSION_NAME=${SR_SESSION_NAME}"
  echo "[starrupture] SR_SAVE_GAME_INTERVAL=${SR_SAVE_GAME_INTERVAL}"
  echo "[starrupture] SR_START_NEW_GAME=${SR_START_NEW_GAME}"
  echo "[starrupture] SR_LOAD_SAVED_GAME=${SR_LOAD_SAVED_GAME}"
  echo "[starrupture] SR_SAVE_GAME_NAME=${SR_SAVE_GAME_NAME}"
}

validate_boolean_value() {
  local variable_name="$1"
  local variable_value="$2"

  if [[ "${variable_value}" != "true" ]]; then
    if [[ "${variable_value}" != "false" ]]; then
      echo "[starrupture] Error: ${variable_name} must be 'true' or 'false'. Current value: ${variable_value}" >&2
      return 1
    fi
  fi

  return 0
}

is_target_writable() {
  local target_file="$1"
  local target_dir=""

  target_dir="$(dirname "${target_file}")"

  mkdir -p "${target_dir}"

  if [[ -e "${target_file}" ]]; then
    if [[ -w "${target_file}" ]]; then
      return 0
    fi

    return 1
  fi

  if [[ -w "${target_dir}" ]]; then
    return 0
  fi

  return 1
}

write_dssettings_file() {
  validate_boolean_value "SR_START_NEW_GAME" "${SR_START_NEW_GAME}"
  validate_boolean_value "SR_LOAD_SAVED_GAME" "${SR_LOAD_SAVED_GAME}"

  if ! is_target_writable "${SR_DSSETTINGS_PATH}"; then
    echo "[starrupture] Warning: Cannot write DSSettings file at ${SR_DSSETTINGS_PATH} (permission denied)." >&2
    echo "[starrupture] Hint: On Coolify with a persistent volume, set file owner to uid/gid 1000 or set SR_WRITE_DSSETTINGS=0 to keep the existing file." >&2
    return 0
  fi

  cat > "${SR_DSSETTINGS_PATH}" <<DSSETTINGS
{
  "SessionName": "${SR_SESSION_NAME}",
  "SaveGameInterval": "${SR_SAVE_GAME_INTERVAL}",
  "StartNewGame": "${SR_START_NEW_GAME}",
  "LoadSavedGame": "${SR_LOAD_SAVED_GAME}",
  "SaveGameName": "${SR_SAVE_GAME_NAME}"
}
DSSETTINGS

  echo "[starrupture] DSSettings file written: ${SR_DSSETTINGS_PATH}"
}

write_optional_json_file() {
  local target_file="$1"
  local file_content="$2"

  if [[ -z "${file_content}" ]]; then
    return 0
  fi

  if ! is_target_writable "${target_file}"; then
    echo "[starrupture] Warning: Cannot write file ${target_file} (permission denied). Existing file will be kept." >&2
    return 0
  fi

  printf '%s\n' "${file_content}" > "${target_file}"
  echo "[starrupture] Wrote file: ${target_file}"
}

main() {
  print_settings_summary

  if [[ "${SR_WRITE_DSSETTINGS}" == "1" ]]; then
    write_dssettings_file
  else
    echo "[starrupture] SR_WRITE_DSSETTINGS is not 1. Existing DSSettings file will be kept."
  fi

  write_optional_json_file "${SERVER_DIR}/Password.json" "${SR_ADMIN_PASSWORD_JSON}"
  write_optional_json_file "${SERVER_DIR}/PlayerPassword.json" "${SR_PLAYER_PASSWORD_JSON}"

  exec /entrypoint.sh
}

main "$@"
