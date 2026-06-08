# Touchpad Linux Lenovo (ACPI Patch Auto Installer)

Script d’installation automatique pour appliquer un patch ACPI permettant d’activer / corriger le touchpad sur certains modèles Lenovo sous Linux.

⚠️ Ce script modifie le DSDT et la configuration GRUB. Une mauvaise utilisation peut rendre le système instable. À utiliser uniquement sur la machine cible.

---

## 📌 Fonctionnalités

- Dump automatique de l’ACPI (`dsdt.dat`)
- Décompilation du DSDT (`dsdt.dsl`)
- Téléchargement du patch depuis GitHub
- Application automatique du patch
- Compilation en `dsdt.aml`
- Installation dans `/boot`
- Modification de GRUB (`40_custom`)
- Sauvegardes automatiques avant modification
- Mode restauration complet
- Interface interactive en terminal

---

## 🧰 Prérequis

Le script installe automatiquement les dépendances suivantes :

- `acpica-tools`
- `wget`
- `patch`

Sur Debian / Ubuntu / Kali :

```bash
sudo apt update
sudo apt install acpica-tools wget patch -y
```

---

## 🚀 Installation

Clone le dépôt :

```bash
cd Downloads
wget https://raw.githubusercontent.com/Dev-Noxis/touchpad_linux_lenovo_PW04P1JT/refs/heads/main/install.sh
```

Rends le script exécutable :

```bash
chmod +x install.sh
```

Lance-le :

```bash
sudo ./install.sh
```

---

## 🖥️ Menu interactif

Le script propose plusieurs options :

1. Installation complète automatique
2. Vérification de l’état actuel
3. Restauration (suppression du patch + GRUB cleanup)
4. Nettoyage des fichiers temporaires
5. Quitter

---

## 🔁 Mode restauration

Permet de revenir à l’état initial :

* Supprime `/boot/dsdt.aml`
* Retire l’entrée ACPI dans GRUB
* Met à jour GRUB automatiquement

---

## ⚠️ Compatibilité

Ce patch est conçu pour :

* Certains modèles Lenovo spécifiques (DSDT ciblé)
* Linux avec GRUB
* Systèmes utilisant ACPI standard

❌ Non compatible avec :

* Machines virtuelles (VMware, VirtualBox, QEMU)
* Autres modèles non testés Lenovo
* Secure Boot activé (peut bloquer le DSDT custom)

---

## 🧪 Vérification matériel (optionnel)

Le script peut être adapté pour vérifier automatiquement la machine :

```bash
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/sys_vendor
```

---

## 🛠️ Logs

Les logs sont disponibles ici :

```bash
/var/log/touchpad_acpi_install.log
```

---

## 📂 Sauvegardes

Les fichiers modifiés sont sauvegardés dans :

```bash
/var/backups/touchpad_acpi/
```

---

## 🔒 Avertissement

Ce projet modifie des composants bas niveau du système (ACPI + bootloader).

Utilisation à vos risques et périls.
Il est recommandé de tester uniquement sur la machine cible réelle.

---

## 👨‍💻 Auteur

Projet développé pour automatiser l’installation du patch touchpad Lenovo sous Linux généré par IA
