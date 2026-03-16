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
: "${STEAMCMD_MAX_RETRIES:=3}"
: "${STEAMCMD_RETRY_DELAY:=10}"

: "${SERVER_CMD:=./server.sh}"

ensure_steamclient_symlink() {
  local steam_home="/home/steam/.steam"
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

run_steamcmd_update() {
  local attempt=1
  local output_file=""

  while [[ "${attempt}" -le "${STEAMCMD_MAX_RETRIES}" ]]; do
    output_file="$(mktemp)"

    echo "[steamcmd-linux-core] Updating app ${STEAM_APP_ID} (attempt ${attempt}/${STEAMCMD_MAX_RETRIES})..."

    if "${STEAMCMD_DIR}/steamcmd.sh" ${update_args} 2>&1 | tee "${output_file}"; then
      rm -f "${output_file}"
      return 0
    fi

    if grep -Fq "state is 0x6 after update job" "${output_file}"; then
      echo "[steamcmd-linux-core] SteamCMD returned state 0x6 for app ${STEAM_APP_ID}."
      echo "[steamcmd-linux-core] This is often transient. Retrying after ${STEAMCMD_RETRY_DELAY}s..."
    else
      echo "[steamcmd-linux-core] SteamCMD update failed with a non-retryable error."
      rm -f "${output_file}"
      return 1
    fi

    rm -f "${output_file}"

    if [[ "${attempt}" -lt "${STEAMCMD_MAX_RETRIES}" ]]; then
      sleep "${STEAMCMD_RETRY_DELAY}"
    fi

    attempt=$((attempt + 1))
  done

  echo "[steamcmd-linux-core] SteamCMD update failed after ${STEAMCMD_MAX_RETRIES} attempts."
  return 1
}

if [[ "${STEAMCMD}" == "1" ]]; then
  run_steamcmd_update
  echo "[steamcmd-linux-core] ... End of updating app ${STEAM_APP_ID}"
fi

ensure_steamclient_symlink

if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
  echo "[steamcmd-linux-core] Terminal mode enabled. Opening shell in ${SERVER_DIR} ..."
  cd "${SERVER_DIR}"
  if [[ -t 0 || -t 1 ]]; then
    exec /bin/bash -l
  fi

  echo "[steamcmd-linux-core] No TTY detected. Keeping the container alive so you can attach a shell (e.g., docker exec -it <container> bash)."
  exec tail -f /dev/null
fi

if [[ "${START_SERVER}" == "1" ]]; then
  echo "[steamcmd-linux-core] Starting server: ${SERVER_CMD} ..."
  cd "${SERVER_DIR}"
  
  exec /bin/bash -lc "${SERVER_CMD}"
  echo "[steamcmd-linux-core] ... End of starting server: ${SERVER_CMD}"
fi
