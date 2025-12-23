#!/usr/bin/env bash
set -euo pipefail

: "${STEAMCMD_DIR:=/opt/steamcmd}"
: "${SERVER_DIR:=/opt/server}"
: "${STEAMCMD:=1}"
: "${ENABLE_TERMINAL:=0}"
: "${START_SERVER:=1}"
: "${STEAM_APP_ID:?STEAM_APP_ID must be set}"
: "${STEAM_LOGIN:=anonymous}"
: "${STEAM_PASSWORD:=}"
: "${STEAM_BRANCH:=public}"
: "${STEAM_VALIDATE:=0}"

: "${SERVER_CMD:=./server.sh}"

ensure_steamclient_symlink() {
  local steam_home="/home/steam/.steam"
  local steam_sdk_dir="${steam_home}/sdk64"
  local steam_client_source="${STEAMCMD_DIR}/linux64/steamclient.so"
  local steam_client_target="${steam_sdk_dir}/steamclient.so"

  mkdir -p "${steam_sdk_dir}"

  if [[ ! -f "${steam_client_source}" ]]; then
    echo "[steamcmd-linux-core] Warning: steamclient.so not found at ${steam_client_source}. It will be linked after SteamCMD installs files."
    return 1
  fi

  ln -sf "${steam_client_source}" "${steam_client_target}"
}

update_args="+force_install_dir ${SERVER_DIR}"
update_args+=" +login ${STEAM_LOGIN}"
if [[ -n "${STEAM_PASSWORD}" && "${STEAM_LOGIN}" != "anonymous" ]]; then
  update_args+=" ${STEAM_PASSWORD}"
fi
update_args+=" +app_update ${STEAM_APP_ID}"
if [[ -n "${STEAM_BRANCH}" && "${STEAM_BRANCH}" != "public" ]]; then
  update_args+=" -beta ${STEAM_BRANCH}"
fi
if [[ "${STEAM_VALIDATE}" == "1" ]]; then
  update_args+=" validate"
fi
update_args+=" +quit"

if [[ "${STEAMCMD}" == "1" ]]; then
  echo "[steamcmd-linux-core] Updating app ${STEAM_APP_ID}... test2"
  "${STEAMCMD_DIR}/steamcmd.sh" ${update_args}
fi

ensure_steamclient_symlink

if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
  echo "[steamcmd-linux-core] Terminal mode enabled. Opening shell in ${SERVER_DIR}."
  cd "${SERVER_DIR}"
  exec /bin/bash
fi

if [[ "${START_SERVER}" == "1" ]]; then
  echo "[steamcmd-linux-core] Starting server: ${SERVER_CMD}"
  cd "${SERVER_DIR}"
  exec /bin/bash -lc "${SERVER_CMD}"
fi
