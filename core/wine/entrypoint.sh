#!/usr/bin/env bash
set -euo pipefail

: "${STEAMCMD_DIR:=/opt/steamcmd}"
: "${SERVER_DIR:=/opt/server}"
: "${WINEPREFIX:=/home/steam/.wine}"
: "${ENABLE_TERMINAL:=1}"

: "${STEAM_APP_ID:?STEAM_APP_ID must be set}"
: "${STEAM_LOGIN:=anonymous}"
: "${STEAM_PASSWORD:=}"
: "${STEAM_BRANCH:=public}"
: "${STEAM_VALIDATE:=0}"

: "${SERVER_EXE:=Server.exe}"
: "${SERVER_ARGS:=}"

update_args="+login ${STEAM_LOGIN}"
if [[ -n "${STEAM_PASSWORD}" && "${STEAM_LOGIN}" != "anonymous" ]]; then
  update_args+=" ${STEAM_PASSWORD}"
fi
update_args+=" +force_install_dir ${SERVER_DIR}"
update_args+=" +app_update ${STEAM_APP_ID}"
if [[ -n "${STEAM_BRANCH}" && "${STEAM_BRANCH}" != "public" ]]; then
  update_args+=" -beta ${STEAM_BRANCH}"
fi
if [[ "${STEAM_VALIDATE}" == "1" ]]; then
  update_args+=" validate"
fi
update_args+=" +quit"

echo "[steamcmd-wine-core] Updating app ${STEAM_APP_ID}..."
"${STEAMCMD_DIR}/steamcmd.sh" ${update_args}

if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
  echo "[steamcmd-wine-core] Terminal mode enabled. Opening shell in ${SERVER_DIR}."
  cd "${SERVER_DIR}"
  exec /bin/bash
fi

echo "[steamcmd-wine-core] Starting Windows server via Wine: ${SERVER_EXE} ${SERVER_ARGS}"
cd "${SERVER_DIR}"

# Optional : Xvfb if necessary
# Xvfb :99 -screen 0 1024x768x16 &
# export DISPLAY=:99

exec wine "${SERVER_EXE}" ${SERVER_ARGS}
