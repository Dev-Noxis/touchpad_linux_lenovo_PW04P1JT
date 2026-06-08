#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="Touchpad ACPI Auto-Installer"
WORKDIR="$HOME/acpi"
PATCH_URL="https://raw.githubusercontent.com/Dev-Noxis/touchpad_linux_lenovo_PW04P1JT/refs/heads/main/dsdt.patch"
GRUB_CUSTOM="/etc/grub.d/40_custom"
DSDT_AML="/boot/dsdt.aml"
MARK_BEGIN="# >>> touchpad_linux_lenovo_PW04P1JT >>>"
MARK_END="# <<< touchpad_linux_lenovo_PW04P1JT <<<"
BACKUP_DIR="/var/backups/touchpad_acpi"
LOG_FILE="/var/log/touchpad_acpi_install.log"

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
BOLD="\033[1m"
NC="\033[0m"

mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

log() {
  echo -e "$*" | tee -a "$LOG_FILE"
}

info() {
  log "${BLUE}[INFO]${NC} $*"
}

ok() {
  log "${GREEN}[OK]${NC} $*"
}

warn() {
  log "${YELLOW}[WARN]${NC} $*"
}

err() {
  log "${RED}[ERREUR]${NC} $*"
}

banner() {
  clear
  cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║                Touchpad ACPI Auto-Installer                 ║
╚══════════════════════════════════════════════════════════════╝
EOF
  echo
}

pause() {
  echo
  read -r -p "Appuie sur Entrée pour continuer..."
}

ensure_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo -E bash "$0" "$@"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_deps() {
  info "Vérification des dépendances..."
  local missing=()

  for cmd in acpidump iasl wget patch grep sed awk cp mv mkdir date; do
    if ! need_cmd "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    warn "Dépendances manquantes détectées. Installation..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y >>"$LOG_FILE" 2>&1
    apt-get install -y acpica-tools wget patch >>"$LOG_FILE" 2>&1
    ok "Dépendances installées."
  else
    ok "Toutes les dépendances essentielles sont déjà présentes."
  fi
}

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp -a "$file" "$BACKUP_DIR/$(basename "$file").$stamp.bak"
    ok "Sauvegarde créée : $BACKUP_DIR/$(basename "$file").$stamp.bak"
  fi
}

status() {
  banner
  info "État actuel :"

  if [[ -f "$DSDT_AML" ]]; then
    ok "Fichier ACPI présent : $DSDT_AML"
  else
    warn "Fichier ACPI absent : $DSDT_AML"
  fi

  if [[ -f "$GRUB_CUSTOM" ]] && grep -qF "$MARK_BEGIN" "$GRUB_CUSTOM"; then
    ok "Entrée GRUB personnalisée détectée dans 40_custom."
  else
    warn "Entrée GRUB personnalisée absente."
  fi

  if [[ -d "$WORKDIR" ]]; then
    ok "Dossier de travail : $WORKDIR"
  else
    warn "Dossier de travail absent : $WORKDIR"
  fi

  echo
  pause
}

download_patch() {
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  info "Téléchargement du patch depuis GitHub..."
  wget -qO dsdt.patch "$PATCH_URL" >>"$LOG_FILE" 2>&1
  ok "Patch téléchargé : $WORKDIR/dsdt.patch"
}

dump_acpi() {
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  info "Dump ACPI en cours..."
  acpidump -b >>"$LOG_FILE" 2>&1
  ok "Dump terminé : $(pwd)/dsdt.dat"
}

decompile_dsdt() {
  cd "$WORKDIR"

  if [[ ! -f dsdt.dat ]]; then
    err "Fichier dsdt.dat introuvable."
    return 1
  fi

  info "Décompilation de dsdt.dat..."
  iasl -d dsdt.dat >>"$LOG_FILE" 2>&1
  ok "Décompilation terminée : $(pwd)/dsdt.dsl"
}

apply_patch() {
  cd "$WORKDIR"

  if [[ ! -f dsdt.dsl ]]; then
    err "Fichier dsdt.dsl introuvable."
    return 1
  fi
  if [[ ! -f dsdt.patch ]]; then
    err "Fichier dsdt.patch introuvable."
    return 1
  fi

  info "Application du patch..."
  set +e
  local out
  out="$(patch -N dsdt.dsl < dsdt.patch 2>&1)"
  local rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    ok "Patch appliqué avec succès."
  else
    if echo "$out" | grep -qiE "Reversed|previously applied|already applied"; then
      warn "Le patch semble déjà appliqué. On continue."
    else
      echo "$out" >>"$LOG_FILE"
      err "Échec de l'application du patch."
      return 1
    fi
  fi
}

compile_dsdt() {
  cd "$WORKDIR"

  info "Compilation de dsdt.dsl..."
  iasl -sa dsdt.dsl >>"$LOG_FILE" 2>&1

  if [[ ! -f dsdt.aml ]]; then
    err "Compilation terminée mais dsdt.aml est introuvable."
    return 1
  fi

  ok "Compilation réussie : $(pwd)/dsdt.aml"
}

install_aml() {
  cd "$WORKDIR"

  if [[ ! -f dsdt.aml ]]; then
    err "Aucun dsdt.aml à installer."
    return 1
  fi

  if [[ -f "$DSDT_AML" ]]; then
    warn "Un ancien $DSDT_AML existe déjà."
    backup_file "$DSDT_AML"
  fi

  info "Copie de dsdt.aml vers /boot..."
  cp -f dsdt.aml "$DSDT_AML"
  ok "Fichier copié vers $DSDT_AML"
}

ensure_grub_entry() {
  if [[ ! -f "$GRUB_CUSTOM" ]]; then
    err "Impossible de trouver $GRUB_CUSTOM"
    return 1
  fi

  if grep -qF "$MARK_BEGIN" "$GRUB_CUSTOM"; then
    warn "L'entrée GRUB personnalisée existe déjà."
    return 0
  fi

  info "Sauvegarde de 40_custom..."
  backup_file "$GRUB_CUSTOM"

  info "Ajout de l'entrée ACPI dans 40_custom..."
  cat <<EOF >> "$GRUB_CUSTOM"

$MARK_BEGIN
acpi /boot/dsdt.aml
$MARK_END
EOF
  ok "Entrée ajoutée dans 40_custom."
}

update_grub() {
  info "Mise à jour de GRUB..."
  update-grub >>"$LOG_FILE" 2>&1
  ok "GRUB mis à jour."
}

install_all() {
  banner
  install_deps
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  if [[ -d "$WORKDIR" ]] && [[ -n "$(ls -A "$WORKDIR" 2>/dev/null || true)" ]]; then
    warn "Le dossier de travail n'est pas vide."
  fi

  dump_acpi
  decompile_dsdt
  download_patch
  apply_patch
  compile_dsdt
  install_aml
  ensure_grub_entry
  update_grub

  echo
  ok "Installation terminée."
  warn "Un redémarrage est nécessaire pour appliquer les changements."
  pause
}

restore_all() {
  banner
  warn "Restauration de l'environnement..."

  if [[ -f "$GRUB_CUSTOM" ]] && grep -qF "$MARK_BEGIN" "$GRUB_CUSTOM"; then
    backup_file "$GRUB_CUSTOM"
    info "Suppression du bloc personnalisé dans 40_custom..."
    sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$GRUB_CUSTOM"
    ok "Bloc supprimé."
  else
    warn "Aucun bloc personnalisé trouvé dans 40_custom."
  fi

  if [[ -f "$DSDT_AML" ]]; then
    backup_file "$DSDT_AML"
    info "Suppression de $DSDT_AML..."
    rm -f "$DSDT_AML"
    ok "Fichier supprimé."
  else
    warn "Aucun $DSDT_AML à supprimer."
  fi

  update_grub
  ok "Restauration terminée."
  warn "Un redémarrage est recommandé."
  pause
}

clean_workdir() {
  banner
  warn "Nettoyage du dossier de travail : $WORKDIR"
  if [[ -d "$WORKDIR" ]]; then
    rm -rf "$WORKDIR"
    ok "Dossier de travail supprimé."
  else
    warn "Le dossier de travail n'existe pas."
  fi
  pause
}

menu() {
  while true; do
    banner
    echo "1) Installer / mettre à jour"
    echo "2) Voir l'état"
    echo "3) Restaurer / supprimer la config"
    echo "4) Supprimer le dossier de travail"
    echo "5) Quitter"
    echo
    read -r -p "Choix : " choice

    case "$choice" in
      1) install_all ;;
      2) status ;;
      3) restore_all ;;
      4) clean_workdir ;;
      5) exit 0 ;;
      *) warn "Choix invalide." ; pause ;;
    esac
  done
}

main() {
  trap 'err "Erreur à la ligne $LINENO. Consulte $LOG_FILE pour les détails."' ERR
  ensure_root "$@"
  menu
}

main "$@"