# SteamCMD Linux Base Image

Image de base Linux prête à l'emploi pour déployer un serveur dédié avec SteamCMD. Elle installe SteamCMD, télécharge les fichiers serveur demandés, puis lance ta commande serveur.

## Variables d'environnement

- `STEAM_APP_ID` (requis) : identifiant Steam de l'application à installer.
- `STEAM_LOGIN` (par défaut `anonymous`) et `STEAM_PASSWORD` : compte Steam pour récupérer l'app (nécessaire si l'accès anonyme n'est pas autorisé).
- `STEAM_BRANCH` (par défaut `public`) : branche/beta à installer (`-beta` dans SteamCMD).
- `STEAM_VALIDATE` (par défaut `0`) : mettre à `1` pour forcer la validation des fichiers.
- `STEAMCMD_MAX_RETRIES` (par défaut `3`) : nombre maximum de tentatives lorsque SteamCMD retourne des erreurs transitoires (ex. `state is 0x6 after update job`).
- `STEAMCMD_RETRY_DELAY` (par défaut `10`) : délai en secondes entre chaque tentative.
- `STEAMCMD_FAILURE_MODE` (par défaut `ignore`) : comportement si SteamCMD échoue après toutes les tentatives. `ignore` continue le démarrage (mise à jour non bloquante), `keepalive` maintient le conteneur actif pour debug, `exit` arrête avec une erreur.
- `SERVER_CMD` (par défaut `./server.sh`) : commande exécutée après l'installation.
- `SERVER_DIR` (par défaut `/opt/server`) : chemin d'installation du serveur.
- `STEAMCMD_DIR` (par défaut `/opt/steamcmd`) : emplacement de SteamCMD.
- `LD_LIBRARY_PATH` (par défaut `/opt/steamcmd/linux64`) : inclut les bibliothèques Steam pour que les jeux puissent charger `steamclient.so` sans liens supplémentaires.
- `ENABLE_TERMINAL` (par défaut `0`) : si `1`, lance la mise à jour SteamCMD puis ouvre un shell dans `SERVER_DIR` au lieu de démarrer le serveur (utile pour le debug via Coolify ou Docker). Si aucun TTY n'est disponible, le conteneur reste actif pour une connexion ultérieure (ex. `docker exec -it`). Mettre à `0` pour démarrer normalement le serveur après la mise à jour.
- `START_SERVER` (par défaut `1`) : si `0`, effectue les étapes de mise à jour SteamCMD puis quitte sans lancer le serveur (utile pour les mises à jour seules).
- `STEAMCMD` (par défaut `0`) : si `0`, ignore toutes les tentatives de mise à jour SteamCMD au démarrage. Utiliser `1` uniquement lors de fenêtres de maintenance manuelle contrôlées depuis l'hôte VPS.

Après la fin de SteamCMD, l'entrypoint crée `/home/steam/.steam/sdk64/steamclient.so` comme lien symbolique vers le `steamclient.so` de SteamCMD (si présent), afin que les jeux attendant ce chemin puissent charger la bibliothèque sans configuration supplémentaire.

## Fonctionnement de l'image

1. SteamCMD est téléchargé et extrait dans `STEAMCMD_DIR` (voir `Dockerfile`).
2. Au démarrage, l'entrypoint construit une commande SteamCMD :
   - `+login <STEAM_LOGIN> [STEAM_PASSWORD]`
   - `+force_install_dir <SERVER_DIR>`
   - `+app_update <STEAM_APP_ID> [-beta <STEAM_BRANCH>] [validate]`
   - `+quit`
3. `steamcmd.sh` exécute cette séquence, téléchargeant ou mettant à jour les fichiers serveur dans `SERVER_DIR`.
4. La commande serveur (`SERVER_CMD`) est ensuite lancée depuis `SERVER_DIR` via `bash -lc`, ce qui permet d'inclure des arguments entre guillemets dans une seule chaîne (ex. noms avec espaces).

## Mise à jour manuelle recommandée (VPS)

L'accès Steam pouvant être instable (restrictions d'accès anonyme, Steam Guard, pannes transitoires), cette image **ne lance aucune mise à jour au démarrage par défaut**.

1. Garder `STEAMCMD=0` pour les conteneurs en production.
2. Installer/mettre à jour les binaires manuellement depuis le VPS avant le premier lancement (et à chaque maintenance).
3. Démarrer/redémarrer le conteneur uniquement une fois les binaires présents dans le `SERVER_DIR` monté.

Exemple de commande d'installation/mise à jour manuelle depuis le VPS :

```bash
docker run --rm -it \
  -v /opt/gaming/my-server:/opt/server \
  -e STEAMCMD=1 \
  -e START_SERVER=0 \
  -e STEAM_APP_ID=123456 \
  -e STEAM_LOGIN=your_steam_login \
  -e STEAM_PASSWORD=your_steam_password \
  monolithoid/steamcmd-linux-core:latest
```

Puis lance ton conteneur serveur habituel avec `STEAMCMD=0`.

## Exemple d'utilisation

```bash
docker run --rm \
  -e STEAM_APP_ID=123456 \
  -e SERVER_CMD="./start-server.sh" \
  -p 2456-2458:2456-2458/udp \
  monolithoid/steamcmd-linux-core:latest
```

Remplace `123456` par l'App ID Steam de ton serveur.

- Monte un volume sur `/opt/server` pour persister les données et la configuration.
- Remplace `SERVER_CMD` par le script fourni par ton jeu.
- Assure-toi que le dossier monté sur l'hôte Coolify appartient à l'UID/GID `1000` (utilisateur `steam` par défaut dans le conteneur), par exemple : `sudo chown -R 1000:1000 /chemin/vers/tes/données`.
- Ouvre et redirige les ports UDP/TCP requis sur ton pare-feu/routeur (et dans Coolify) pour que les joueurs puissent atteindre le serveur. Exemple sur Debian/Ubuntu avec UFW : `sudo ufw allow 2456:2458/udp` (adapter à ton jeu).

## Personnalisation

- Cibler une branche beta : `-e STEAM_BRANCH=experimental`.
- Forcer la validation en cas de fichiers corrompus : `-e STEAM_VALIDATE=1`.
- Ajouter ta propre configuration/scripts via un volume ou une image dérivée.
