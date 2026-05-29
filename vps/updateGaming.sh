#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

# =============================================================================
# Script      : update-games.sh
# Objet       : Mise à jour des serveurs de jeux via SteamCMD
# Auteur      : Monolithoid
# =============================================================================

STEAMCMD_BIN="${STEAMCMD_BIN:-steamcmd}"
LOG_DIR="${LOG_DIR:-/tmp/steamcmd-updates}"

mkdir -p "$LOG_DIR"

# -----------------------------------------------------------------------------
# Affichage
# -----------------------------------------------------------------------------

step() {
  echo
  echo "╭────────────────────────────────────────────────────────────"
  printf "│ %s\n" "$1"
  echo "╰────────────────────────────────────────────────────────────"
}

ok() {
  printf "  ✓ %s\n" "$1"
}

warn() {
  printf "  ! %s\n" "$1"
}

fail() {
  printf "  ✗ %s\n" "$1"
}

info() {
  printf "  • %s\n" "$1"
}

# -----------------------------------------------------------------------------
# Analyse du log SteamCMD
# -----------------------------------------------------------------------------

analyze_steamcmd_log() {
  local app_id="$1"
  local log_file="$2"

  if grep -qi "No subscription" "$log_file"; then
    fail "Accès refusé : No subscription"
    return 10
  fi

  if grep -qi "ERROR! Failed to install app" "$log_file"; then
    fail "SteamCMD n'a pas réussi à installer l'application"
    return 11
  fi

  if grep -qi "state is 0x6" "$log_file"; then
    fail "Erreur SteamCMD connue : state is 0x6 après update"
    return 12
  fi

  if grep -qi "Invalid platform" "$log_file"; then
    fail "Plateforme invalide pour cette application"
    return 13
  fi

  if grep -qi "Timeout\|timed out\|connection.*failed\|Network is unreachable" "$log_file"; then
    fail "Erreur réseau pendant la mise à jour"
    return 14
  fi

  if grep -qi "Disk write failure\|No space left on device\|Permission denied" "$log_file"; then
    fail "Erreur disque ou permissions"
    return 15
  fi

  if grep -q "Success! App '${app_id}' fully installed" "$log_file"; then
    ok "Installation / mise à jour réussie"
    return 0
  fi

  if grep -q "Success! App '${app_id}' already up to date" "$log_file"; then
    ok "Déjà à jour"
    return 0
  fi

  if grep -qi "Success! App '${app_id}'" "$log_file"; then
    ok "SteamCMD indique un succès"
    return 0
  fi

  if grep -qi "ERROR!" "$log_file"; then
    fail "Erreur SteamCMD détectée"
    return 16
  fi

  warn "SteamCMD terminé, mais statut non reconnu"
  return 20
}

# -----------------------------------------------------------------------------
# Mise à jour d'un jeu
# -----------------------------------------------------------------------------

update_game() {
  local name="$1"
  local app_id="$2"
  local install_dir="$3"
  local platform="${4:-windows}"

  local timestamp
  local log_file
  local rc
  local analysis_rc

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  log_file="${LOG_DIR}/${name}-${app_id}-${timestamp}.log"

  step "Mise à jour : ${name}"

  info "App ID       : ${app_id}"
  info "Plateforme   : ${platform}"
  info "Répertoire   : ${install_dir}"
  info "Log          : ${log_file}"

  mkdir -p "$install_dir"

  "$STEAMCMD_BIN" \
    +@sSteamCmdForcePlatformType "$platform" \
    +force_install_dir "$install_dir" \
    +login anonymous \
    +app_update "$app_id" validate \
    +quit \
    2>&1 | tee "$log_file"

  rc=${PIPESTATUS[0]}

  if [[ $rc -ne 0 ]]; then
    fail "SteamCMD a retourné le code erreur ${rc}"
    analyze_steamcmd_log "$app_id" "$log_file" || true
    return "$rc"
  fi

  analyze_steamcmd_log "$app_id" "$log_file"
  analysis_rc=$?

  return "$analysis_rc"
}

# -----------------------------------------------------------------------------
# Jeux à mettre à jour
# Format :
#   "Nom|AppID|Répertoire|Plateforme"
# -----------------------------------------------------------------------------

GAMES=(
  "StarRupture|3809400|/opt/gaming/starrupture|windows"
  "Abiotic Factor|2857200|/opt/gaming/abioticfactor|windows"
)

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  local total=0
  local success=0
  local failed=0

  local game
  local name
  local app_id
  local install_dir
  local platform

  step "Mise à jour des jeux SteamCMD"

  for game in "${GAMES[@]}"; do
    IFS='|' read -r name app_id install_dir platform <<< "$game"

    total=$((total + 1))

    if update_game "$name" "$app_id" "$install_dir" "$platform"; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
    fi
  done

  step "Résumé"

  info "Jeux traités : ${total}"
  ok "Succès       : ${success}"

  if [[ $failed -gt 0 ]]; then
    fail "Échecs       : ${failed}"
    return 1
  fi

  ok "Toutes les mises à jour sont terminées"
  return 0
}

main "$@"
