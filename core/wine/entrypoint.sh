#!/usr/bin/env bash
set -euo pipefail

: "${STEAMCMD_DIR:=/opt/steamcmd}"
: "${SERVER_DIR:=/opt/server}"
: "${WINEPREFIX:=/home/steam/.wine}"
: "${STEAMCMD:=1}"
: "${ENABLE_TERMINAL:=0}"
: "${START_SERVER:=1}"
: "${STEAMCMD_PLATFORM:=}"
: "${STEAM_APP_ID:?STEAM_APP_ID must be set}"
: "${STEAM_LOGIN:=anonymous}"
: "${STEAM_PASSWORD:=}"
: "${STEAM_BRANCH:=public}"
: "${STEAM_VALIDATE:=0}"
: "${STEAMCMD_MAX_RETRIES:=3}"
: "${STEAMCMD_RETRY_DELAY:=10}"
: "${STEAMCMD_FAILURE_MODE:=ignore}"

: "${SERVER_EXE:=Server.exe}"
: "${SERVER_ARGS:=}"
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

run_steamcmd_update() {
  local attempt=1
  local output_file=""

  while [[ "${attempt}" -le "${STEAMCMD_MAX_RETRIES}" ]]; do
    output_file="$(mktemp)"

    echo "[steamcmd-wine-core] Updating app ${STEAM_APP_ID} (attempt ${attempt}/${STEAMCMD_MAX_RETRIES})..."

    if "${STEAMCMD_DIR}/steamcmd.sh" ${update_args} 2>&1 | tee "${output_file}"; then
      rm -f "${output_file}"
      return 0
    fi

    if grep -Fq "state is 0x6 after update job" "${output_file}"; then
      echo "[steamcmd-wine-core] SteamCMD returned state 0x6 for app ${STEAM_APP_ID}."
      echo "[steamcmd-wine-core] This is often transient. Retrying after ${STEAMCMD_RETRY_DELAY}s..."
    else
      echo "[steamcmd-wine-core] SteamCMD update failed with a non-retryable error."
      rm -f "${output_file}"
      return 1
    fi

    rm -f "${output_file}"

    if [[ "${attempt}" -lt "${STEAMCMD_MAX_RETRIES}" ]]; then
      sleep "${STEAMCMD_RETRY_DELAY}"
    fi

    attempt=$((attempt + 1))
  done

  echo "[steamcmd-wine-core] SteamCMD update failed after ${STEAMCMD_MAX_RETRIES} attempts."
  return 1
}

handle_steamcmd_failure() {
  if [[ "${STEAMCMD_FAILURE_MODE}" == "exit" ]]; then
    echo "[steamcmd-wine-core] SteamCMD update failed. Exiting container because STEAMCMD_FAILURE_MODE=exit."
    return 1
  fi

  if [[ "${STEAMCMD_FAILURE_MODE}" == "keepalive" ]]; then
    echo "[steamcmd-wine-core] SteamCMD update failed. Keeping container alive because STEAMCMD_FAILURE_MODE=keepalive."
    echo "[steamcmd-wine-core] You can inspect logs and files, then restart manually when ready."
    exec tail -f /dev/null
  fi

  if [[ "${STEAMCMD_FAILURE_MODE}" == "ignore" ]]; then
    echo "[steamcmd-wine-core] SteamCMD update failed, but continuing startup because STEAMCMD_FAILURE_MODE=ignore."
    return 0
  fi

  echo "[steamcmd-wine-core] Invalid STEAMCMD_FAILURE_MODE value: ${STEAMCMD_FAILURE_MODE}."
  echo "[steamcmd-wine-core] Allowed values: exit, keepalive, ignore."
  return 1
}

if [[ "${STEAMCMD}" == "1" ]]; then
  if ! run_steamcmd_update; then
    handle_steamcmd_failure
  fi
  echo "[steamcmd-wine-core] ... End of updating app ${STEAM_APP_ID}"
fi

ensure_steamclient_symlink

if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
  echo "[steamcmd-wine-core] Terminal mode enabled. Opening shell in ${SERVER_DIR}."
  cd "${SERVER_DIR}"
  if [[ -t 0 || -t 1 ]]; then
    exec /bin/bash -l
  fi

  echo "[steamcmd-wine-core] No TTY detected. Keeping the container alive so you can attach a shell (e.g., docker exec -it <container> bash)."
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
