#!/bin/bash

# Couleurs pour l'interface CLI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Pas de couleur
BOLD='\033[1m'

GRUB_FILE="/etc/grub.d/40_custom"
BOOT_AML="/boot/dsdt.aml"
WORK_DIR="$HOME/acpi"

clear
echo -e "${BLUE}${BOLD}=================================================="
echo -e "       Touchpad Auto-Installer & Fixer"
echo -e "==================================================${NC}\n"

# Fonction pour vérifier l'état actuel du système
check_status() {
    if [ -f "$BOOT_AML" ] && grep -q "acpi /boot/dsdt.aml" "$GRUB_FILE"; then
        return 1 # Déjà complètement installé
    elif [ -f "$BOOT_AML" ] || grep -q "acpi /boot/dsdt.aml" "$GRUB_FILE"; then
        return 2 # Installation partielle ou incohérente
    else
        return 0 # Non installé
    fi
}

# Fonction d'installation automatique
install_protocol() {
    echo -e "${BLUE}${BOLD}>>> Début de l'automatisation...${NC}"
    
    echo -e "\n${YELLOW}[1/8] Installation des dépendances (acpica-tools, wget, patch)...${NC}"
    sudo apt update && sudo apt install acpica-tools wget patch -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erreur lors de l'installation des paquets requis.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}[2/8] Préparation du dossier de travail temporaire...${NC}"
    [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR" && cd "$WORK_DIR" || exit 1

    echo -e "\n${YELLOW}[3/8] Extraction des tables ACPI natives (acpidump)...${NC}"
    sudo acpidump -b
    if [ ! -f "dsdt.dat" ]; then
        echo -e "${RED}❌ Erreur : Le fichier dsdt.dat n'a pas pu être extrait.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}[4/8] Décompilation de la table DSDT...${NC}"
    iasl -d dsdt.dat
    if [ ! -f "dsdt.dsl" ]; then
        echo -e "${RED}❌ Erreur : Impossible de décompiler dsdt.dat.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}[5/8] Téléchargement et application du patch depuis GitHub...${NC}"
    wget -q --show-progress -O dsdt.patch https://raw.githubusercontent.com/Dev-Noxis/touchpad_linux_lenovo_PW04P1JT/refs/heads/main/dsdt.patch
    if [ ! -f "dsdt.patch" ]; then
        echo -e "${RED}❌ Erreur : Impossible de récupérer le fichier de patch.${NC}"
        exit 1
    fi
    
    # Utilisation de --forward pour éviter les prompts interactifs si déjà appliqué
    patch --forward dsdt.dsl < dsdt.patch
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erreur lors de l'application du patch dsdt.patch.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}[6/8] Recompilation de la table DSDT modifiée...${NC}"
    iasl -sa dsdt.dsl
    if [ ! -f "dsdt.aml" ]; then
        echo -e "${RED}❌ Erreur de compilation iasl. Le patch est peut-être obsolète.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}[7/8] Copie de la table finale aml dans /boot...${NC}"
    sudo cp dsdt.aml "$BOOT_AML"

    echo -e "\n${YELLOW}[8/8] Injection de la configuration dans GRUB...${NC}"
    if ! grep -q "acpi /boot/dsdt.aml" "$GRUB_FILE"; then
        # Ajout propre avec un saut de ligne initial au fichier 40_custom
        echo -e "\nacpi /boot/dsdt.aml" | sudo tee -a "$GRUB_FILE" > /dev/null
    fi

    echo -e "${YELLOW}Mise à jour des configurations de GRUB...${NC}"
    sudo update-grub
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erreur lors de l'exécution de update-grub.${NC}"
        exit 1
    fi

    echo -e "\n${GREEN}${BOLD}✔ Le protocole a été appliqué avec succès !${NC}"
    
    # Nettoyage du dossier temporaire utilisateur
    rm -rf "$WORK_DIR"

    echo ""
    read -p "Un redémarrage est nécessaire pour appliquer les changements. Redémarrer maintenant ? (o/n) : " choice
    if [[ "$choice" =~ ^[OoYy]$ ]]; then
        sudo reboot
    fi
}

# Fonction de désinstallation / Remise à zéro
revert_protocol() {
    echo -e "${BLUE}${BOLD}>>> Restauration du système à l'état d'origine...${NC}"
    
    if [ -f "$BOOT_AML" ]; then
        echo -e "${YELLOW}[-] Suppression de $BOOT_AML...${NC}"
        sudo rm "$BOOT_AML"
    fi

    if grep -q "acpi /boot/dsdt.aml" "$GRUB_FILE"; then
        echo -e "${YELLOW}[-] Retrait de la ligne personnalisée dans $GRUB_FILE...${NC}"
        # Supprime précisément la ligne ajoutée dans le fichier custom
        sudo sed -i '/acpi \/boot\/dsdt.aml/d' "$GRUB_FILE"
    fi

    echo -e "${YELLOW}[-] Régénération de GRUB...${NC}"
    sudo update-grub

    # Nettoyage optionnel du dossier résiduel au cas où
    [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"

    echo -e "\n${GREEN}${BOLD}✔ Système restauré avec succès !${NC}"
}

# --- Logique principale de l'interface ---
check_status
status=$?

if [ $status -eq 1 ]; then
    echo -e "${GREEN}${BOLD}● Statut : Le correctif touchpad est déjà pleinement INSTALLÉ.${NC}\n"
    echo "Que souhaitez-vous faire ?"
    echo -e " 1) Désinstaller le correctif (${RED}Revert${NC})"
    echo -e " 2) Réinstaller proprement (Suppression totale puis réinstallation)"
    echo -e " 3) Quitter"
    echo ""
    read -p "Sélectionnez une option [1-3] : " opt
    case $opt in
        1) revert_protocol ;;
        2) revert_protocol && install_protocol ;;
        *) echo -e "${YELLOW}Opération annulée.${NC}"; exit 0 ;;
    esac

elif [ $status -eq 2 ]; then
    echo -e "${RED}${BOLD}● Statut : Une installation partielle ou instable a été détectée !${NC}\n"
    echo "Que souhaitez-vous faire ?"
    echo -e " 1) Réparer et réinstaller proprement (${GREEN}Recommandé${NC})"
    echo -e " 2) Nettoyer les fichiers et désinstaller complètement"
    echo -e " 3) Quitter"
    echo ""
    read -p "Sélectionnez une option [1-3] : " opt
    case $opt in
        1) revert_protocol && install_protocol ;;
        2) revert_protocol ;;
        *) echo -e "${YELLOW}Opération annulée.${NC}"; exit 0 ;;
    esac

else
    echo -e "${YELLOW}${BOLD}● Statut : Le correctif n'est pas encore installé.${NC}\n"
    echo "Que souhaitez-vous faire ?"
    echo -e " 1) Lancer l'installation automatisée"
    echo -e " 2) Quitter"
    echo ""
    read -p "Sélectionnez une option [1-2] : " opt
    case $opt in
        1) install_protocol ;;
        *) echo -e "${YELLOW}Opération annulée.${NC}"; exit 0 ;;
    esac
fi