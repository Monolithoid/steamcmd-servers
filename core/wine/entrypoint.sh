#!/usr/bin/env bash
set -euo pipefail

: "${SERVER_DIR:=/opt/server}"
: "${ENABLE_TERMINAL:=0}"
: "${START_SERVER:=1}"
: "${SERVER_EXE:=Server.exe}"
: "${SERVER_ARGS:=}"
: "${WINE_MISMATCH_STRATEGY:=switch}"
: "${USE_XVFB:=1}"
: "${XVFB_SCREEN:=0 1024x768x16}"

get_prefix_architecture() {
  local prefix_path="$1"
  local system_reg_file=""

  system_reg_file="${prefix_path}/system.reg"

  if [[ ! -f "${system_reg_file}" ]]; then
    echo "missing"
    return 0
  fi

  if grep -q "#arch=win64" "${system_reg_file}"; then
    echo "win64"
    return 0
  fi

  if grep -q "#arch=win32" "${system_reg_file}"; then
    echo "win32"
    return 0
  fi

  echo "unknown"
}

initialize_wine_prefix() {
  echo "[wine-core] Initialisation du préfixe Wine : ${WINEPREFIX} (WINEARCH=${WINEARCH:-default})"
  wineboot -u >/dev/null 2>&1 || wineboot -u
}

ensure_wine_prefix_architecture() {
  local prefix_architecture=""
  local expected_architecture=""
  local switched_prefix=""

  expected_architecture="${WINEARCH:-}"
  prefix_architecture="$(get_prefix_architecture "${WINEPREFIX}")"

  if [[ "${prefix_architecture}" == "missing" ]]; then
    initialize_wine_prefix
    return 0
  fi

  if [[ -z "${expected_architecture}" ]]; then
    return 0
  fi

  if [[ "${prefix_architecture}" == "${expected_architecture}" ]]; then
    return 0
  fi

  if [[ "${WINE_MISMATCH_STRATEGY}" == "switch" ]]; then
    switched_prefix="${WINEPREFIX}-${expected_architecture}"
    echo "[wine-core] Incompatibilité détectée (${prefix_architecture} vs ${expected_architecture})."
    echo "[wine-core] Bascule automatique vers un préfixe dédié : ${switched_prefix}"
    export WINEPREFIX="${switched_prefix}"
    initialize_wine_prefix
    return 0
  fi

  if [[ "${WINE_MISMATCH_STRATEGY}" == "recreate" ]]; then
    echo "[wine-core] Incompatibilité détectée (${prefix_architecture} vs ${expected_architecture})."
    echo "[wine-core] Suppression et recréation du préfixe ${WINEPREFIX}."
    rm -rf "${WINEPREFIX}"
    initialize_wine_prefix
    return 0
  fi

  echo "[wine-core] Erreur: WINEARCH=${expected_architecture} mais ${WINEPREFIX} est ${prefix_architecture}." >&2
  echo "[wine-core] Défini WINE_MISMATCH_STRATEGY=switch (recommandé) ou recreate pour auto-corriger." >&2
  return 1
}

open_terminal_mode() {
  echo "[wine-core] Mode terminal actif. Ouverture d'un shell dans ${SERVER_DIR}."

  cd "${SERVER_DIR}"

  if [[ -t 0 || -t 1 ]]; then
    exec /bin/bash -l
  fi

  echo "[wine-core] Aucun TTY détecté. Conteneur maintenu actif pour connexion ultérieure (docker exec -it)."
  exec tail -f /dev/null
}

start_windows_server() {
  echo "[wine-core] Démarrage du serveur Windows via Wine : ${SERVER_EXE} ${SERVER_ARGS}"
  cd "${SERVER_DIR}"

  if [[ "${USE_XVFB}" == "1" ]]; then
    echo "[wine-core] USE_XVFB=1, lancement via xvfb-run (DISPLAY virtuel)."
    exec xvfb-run -a -s "-screen ${XVFB_SCREEN}" wine "${SERVER_EXE}" ${SERVER_ARGS}
  fi

  exec wine "${SERVER_EXE}" ${SERVER_ARGS}
}

main() {
  ensure_wine_prefix_architecture

  if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
    open_terminal_mode
  fi

  if [[ "${START_SERVER}" == "1" ]]; then
    start_windows_server
  fi

  echo "[wine-core] START_SERVER=0, aucun serveur lancé."
}

main "$@"
