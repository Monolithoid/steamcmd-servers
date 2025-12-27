#!/usr/bin/env bash
set -euo pipefail

: "${STEAMCMD_DIR:=/opt/steamcmd}"
: "${SERVER_DIR:=/opt/server}"
: "${STEAM_HOME:=/home/steam}"
: "${WINEPREFIX:=${STEAM_HOME}/.wine}"
: "${PERSIST_STEAM_HOME:=0}"
: "${PERSIST_STEAM_HOME_DIR:=/opt/steam-home}"
: "${STEAMCMD:=1}"
: "${ENABLE_TERMINAL:=0}"
: "${START_SERVER:=1}"
: "${STEAMCMD_PLATFORM:=}"
: "${STEAM_APP_ID:?STEAM_APP_ID must be set}"
: "${STEAM_LOGIN:=anonymous}"
: "${STEAM_PASSWORD:=}"
: "${STEAM_BRANCH:=public}"
: "${STEAM_VALIDATE:=0}"

: "${SERVER_EXE:=Server.exe}"
: "${SERVER_ARGS:=}"
setup_steam_home() {
  if [[ "${PERSIST_STEAM_HOME}" != "1" ]]; then
    mkdir -p "${STEAM_HOME}"
    return
  fi

  mkdir -p "${PERSIST_STEAM_HOME_DIR}"

  if [[ ! -L "${STEAM_HOME}" && -d "${STEAM_HOME}" ]]; then
    shopt -s dotglob nullglob
    for item in "${STEAM_HOME}"/*; do
      cp -a "${item}" "${PERSIST_STEAM_HOME_DIR}/"
    done
    shopt -u dotglob nullglob
    rm -rf "${STEAM_HOME}"
  fi

  ln -snf "${PERSIST_STEAM_HOME_DIR}" "${STEAM_HOME}"
}

ensure_steamclient_symlink() {
  local steam_home="${STEAM_HOME}/.steam"
  local steam_sdk_dir="${steam_home}/sdk64"
  local steam_client_source="${STEAMCMD_DIR}/linux64/steamclient.so"
  local steam_client_target="${steam_sdk_dir}/steamclient.so"

  mkdir -p "${steam_sdk_dir}"

  if [[ ! -f "${steam_client_source}" ]]; then
    echo "[steamcmd-linux-core] Warning: steamclient.so not found at ${steam_client_source}. It will be linked after SteamCMD installs files."
    return 0
  fi

  ln -sf "${steam_client_source}" "${steam_client_target}"
}

setup_steam_home

update_args="+force_install_dir ${SERVER_DIR}"
update_args+=" +login ${STEAM_LOGIN}"
if [[ -n "${STEAM_PASSWORD}" && "${STEAM_LOGIN}" != "anonymous" ]]; then
  update_args+=" ${STEAM_PASSWORD}"
fi
if [[ -n "${STEAMCMD_PLATFORM}" ]]; then
  update_args+=" +@sSteamCmdForcePlatformType ${STEAMCMD_PLATFORM}"
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
  echo "[steamcmd-wine-core] Updating app ${STEAM_APP_ID}..."
  "${STEAMCMD_DIR}/steamcmd.sh" ${update_args}
  echo "[steamcmd-linux-core] ... End of updating app ${STEAM_APP_ID}"
fi

ensure_steamclient_symlink

if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
  echo "[steamcmd-wine-core] Terminal mode enabled. Opening shell in ${SERVER_DIR}."
  cd "${SERVER_DIR}"
  if [[ -t 0 || -t 1 ]]; then
    exec /bin/bash -l
  fi

  echo "[steamcmd-linux-core] No TTY detected. Keeping the container alive so you can attach a shell (e.g., docker exec -it <container> bash)."
  exec tail -f /dev/null
fi

if [[ "${START_SERVER}" == "1" ]]; then
  echo "[steamcmd-wine-core] Starting Windows server via Wine: ${SERVER_EXE} ${SERVER_ARGS} ..."
  cd "${SERVER_DIR}"

# Optional : Xvfb if necessary
# Xvfb :99 -screen 0 1024x768x16 &
# export DISPLAY=:99

  exec wine "${SERVER_EXE}" ${SERVER_ARGS}
  echo "[steamcmd-wine-core] ... End of starting Windows server via Wine: ${SERVER_EXE} ${SERVER_ARGS}"
fi