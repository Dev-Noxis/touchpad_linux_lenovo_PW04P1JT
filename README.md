# Fix Touchpad Lenovo Linux (PW04P1JT) - Script d'automatisation

Ce dépôt contient un script Bash d'automatisation clé en main permettant de corriger le problème de fonctionnement du touchpad sur certains modèles d'ordinateurs Lenovo sous Linux (notamment liés à la révision de la table DSDT `PW04P1JT`).

> 🤖 **Note sur le développement :** Le script d'installation (`install.sh`) a été entièrement généré par une Intelligence Artificielle (IA) à partir de la procédure manuelle que j'ai rédigée.

---

## ⚠️ PRÉREQUIS CRITIQUE : DÉSACTIVER LE SECURE BOOT
Pour que ce correctif fonctionne, **vous devez obligatoirement désactiver le Secure Boot** dans les paramètres de votre BIOS/UEFI avant de lancer le script. 

*Pourquoi ?* Si le Secure Boot reste activé, le noyau Linux et GRUB refuseront catégoriquement de charger la table ACPI personnalisée modifiée (`dsdt.aml`) pour des raisons de sécurité de signature. Le script s'exécutera mais le touchpad ne fonctionnera toujours pas après le redémarrage.

---

## 🧾 Crédits et Inspirations
L'écriture de la procédure manuelle initiale et la compréhension de ce correctif ont été rendus possibles en m'inspirant grandement des précieuses recherches et partages de **lurnot3k** et **ethium** sur le forum Ubuntu. Un grand merci à eux pour leur contribution à la communauté !

---

## 🚀 Fonctionnalités du Script
Le script `install.sh` intègre une logique avancée pour éviter les erreurs humaines :
- **Détection automatique d'état** : Il vérifie si le correctif est déjà appliqué, partiellement installé (configuration cassée) ou non installé, et s'adapte en conséquence.
- **Gestion et sécurité des erreurs** : À chaque étape critique (décompilation, application du patch, recompilation), le script vérifie la réussite de l'opération. Si une étape échoue, il s'arrête proprement pour ne pas corrompre votre système.
- **Option de Revert (Désinstallation)** : Si vous souhaitez revenir à l'état d'origine, le script propose un nettoyage complet (retrait de la ligne dans GRUB, suppression du fichier dans `/boot` et régénération de GRUB).
- **Interface CLI intuitive** : Un affichage textuel clair et coloré avec un menu interactif.

---

## 🛠️ Utilisation (Installation Rapide)

Ouvrez votre terminal et copiez-collez la commande suivante. 

*Note : Ne lancez pas la commande globale avec `sudo`. Le script est conçu pour s'exécuter en utilisateur normal et appellera `sudo` de lui-même uniquement lorsqu'il aura besoin des privilèges système (comme pour modifier GRUB ou copier dans `/boot`).*

```bash
wget [https://raw.githubusercontent.com/Dev-Noxis/touchpad_linux_lenovo_PW04P1JT/main/install.sh](https://raw.githubusercontent.com/Dev-Noxis/touchpad_linux_lenovo_PW04P1JT/main/install.sh) && chmod +x install.sh && ./install.sh
```

Laissez-vous ensuite guider par les options affichées à l'écran.

---

## 🛑 Clause de non-responsabilité (Disclaimer)

La modification des tables ACPI (DSDT) et l'injection de configurations personnalisées dans GRUB touchent à des composants sensibles du système de démarrage de votre système d'exploitation.

**En utilisant ce script, vous acceptez explicitement les conditions suivantes :**

* Ce script et ce protocole sont fournis "en l'état", à des fins éducatives et d'entraide, sans aucune garantie d'aucune sorte, expresse ou implicite.
* L'auteur de ce dépôt **ne pourra en aucun cas être tenu pour responsable** de tout dommage direct ou indirect causé à votre ordinateur. Cela inclut, sans s'y limiter : la perte de données, l'instabilité du système, les dysfonctionnements matériels ou l'incapacité de votre système à démarrer ("soft-brick" ou système figé au boot).
* Il est fortement recommandé d'effectuer une sauvegarde de vos fichiers importants avant toute manipulation de ce type.
