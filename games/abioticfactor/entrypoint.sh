#!/usr/bin/env bash
set -euo pipefail

: "${SERVER_DIR:=/opt/server}"

resolve_server_executable() {
  local configured_executable="${SERVER_EXE:-}"
  local candidate_executable=""
  local discovered_executable=""
  local executable_candidates=(
    "${configured_executable}"
    "AbioticFactorServer.exe"
    "AbioticFactor/Binaries/Win64/AbioticFactorServer-Win64-Shipping.exe"
    "AbioticFactorServer-Win64-Shipping.exe"
  )

  for candidate_executable in "${executable_candidates[@]}"; do
    if [[ -z "${candidate_executable}" ]]; then
      continue
    fi

    if [[ -f "${SERVER_DIR}/${candidate_executable}" ]]; then
      if [[ "${candidate_executable}" != "${configured_executable}" ]]; then
        echo "[abioticfactor] Warning: SERVER_EXE='${configured_executable}' introuvable."
        echo "[abioticfactor] Utilisation automatique de '${candidate_executable}'."
      fi

      export SERVER_EXE="${candidate_executable}"
      return 0
    fi
  done

  discovered_executable="$({
    find "${SERVER_DIR}" -maxdepth 8 -type f \
      \( -iname "AbioticFactorServer.exe" -o -iname "AbioticFactorServer-Win64-Shipping.exe" \)
  } | head -n 1)"

  if [[ -n "${discovered_executable}" ]]; then
    discovered_executable="${discovered_executable#${SERVER_DIR}/}"
    echo "[abioticfactor] Warning: SERVER_EXE='${configured_executable}' introuvable."
    echo "[abioticfactor] Exécutable détecté automatiquement: '${discovered_executable}'."
    export SERVER_EXE="${discovered_executable}"
    return 0
  fi

  echo "[abioticfactor] Error: Aucun exécutable serveur trouvé dans ${SERVER_DIR}." >&2
  echo "[abioticfactor] Vérifie l'installation dédiée et la variable SERVER_EXE." >&2
  return 1
}

main() {
  resolve_server_executable
  exec /entrypoint.sh
}

main "$@"
