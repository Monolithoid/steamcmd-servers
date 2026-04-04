#!/usr/bin/env bash
set -euo pipefail

: "${SERVER_DIR:=/opt/server}"
: "${ENABLE_TERMINAL:=0}"
: "${START_SERVER:=1}"
: "${SERVER_EXE:=Server.exe}"
: "${SERVER_ARGS:=}"

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
  exec wine "${SERVER_EXE}" ${SERVER_ARGS}
}

main() {
  if [[ "${ENABLE_TERMINAL}" == "1" ]]; then
    open_terminal_mode
  fi

  if [[ "${START_SERVER}" == "1" ]]; then
    start_windows_server
  fi

  echo "[wine-core] START_SERVER=0, aucun serveur lancé."
}

main "$@"
