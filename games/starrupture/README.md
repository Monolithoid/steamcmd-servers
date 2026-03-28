# monolithoid/starrupture-server

Serveur dédié StarRupture basé sur SteamCMD + Wine, mis à jour automatiquement à chaque démarrage.
Cette image applique les recommandations de démarrage et la structure de configuration publiées ici :
https://wiki.starrupture-utilities.com/en/dedicated-server/configuration

## Démarrage rapide

```bash
docker run -d \
  --name starrupture \
  -p 7777:7777/udp \
  -e STEAM_APP_ID="3809400" \
  -e SERVER_EXE="StarRuptureServerEOS.exe" \
  -e SERVER_ARGS="-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable" \
  -e SR_WRITE_DSSETTINGS="1" \
  -e SR_SESSION_NAME="StarRuptureServer" \
  -e SR_SAVE_GAME_INTERVAL="300" \
  -e SR_START_NEW_GAME="false" \
  -e SR_LOAD_SAVED_GAME="true" \
  -e SR_SAVE_GAME_NAME="AutoSave0.sav" \
  -v $(pwd)/data:/opt/server \
  monolithoid/starrupture-server:latest
```

## Ce que fait l'image au démarrage

1. Met à jour/installe le serveur dédié via SteamCMD (AppID `3809400`).
2. Crée ou met à jour `DSSettings.txt` (si `SR_WRITE_DSSETTINGS=1`).
3. Écrit `Password.json` et `PlayerPassword.json` si tu fournis les variables dédiées.
4. Lance `StarRuptureServerEOS.exe` avec les arguments recommandés.

## Variables de configuration StarRupture

### Paramètres de lancement

- `SERVER_EXE` : exécutable du serveur (par défaut `StarRuptureServerEOS.exe`).
- `SERVER_ARGS` : arguments de lancement (par défaut `-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable`).

### DSSettings.txt

- `SR_WRITE_DSSETTINGS` : `1` pour générer automatiquement le fichier, `0` pour conserver ton fichier existant.
- `SR_DSSETTINGS_PATH` : chemin du fichier (par défaut `/opt/server/DSSettings.txt`).
- `SR_SESSION_NAME` : nom de session du monde (max conseillé 20 caractères).
- `SR_SAVE_GAME_INTERVAL` : intervalle de sauvegarde en secondes (`300` recommandé).
- `SR_START_NEW_GAME` : `true` ou `false`.
- `SR_LOAD_SAVED_GAME` : `true` ou `false`.
- `SR_SAVE_GAME_NAME` : fichier de sauvegarde (par défaut `AutoSave0.sav`).

### Mots de passe (optionnel)

- `SR_ADMIN_PASSWORD_JSON` : contenu complet de `Password.json`.
- `SR_PLAYER_PASSWORD_JSON` : contenu complet de `PlayerPassword.json`.

Tu peux générer ces JSON depuis : https://starrupture-utilities.com/passwords

## Exemple `docker-compose.yml`

Un exemple prêt à l'emploi est fourni dans `games/starrupture/docker-compose.yml`.

## Notes importantes (réseau et sécurité)

- Ce jeu nécessite une connexion client vers l'IP WAN publique du serveur.
- La redirection de port est obligatoire (exemple inclus : UDP `7777`).
- Vérifie la publication de sécurité indiquée sur la page officielle de configuration.
- Assure-toi que le dossier monté depuis Coolify est possédé par l'UID/GID `1000` (`steam`) :
  `sudo chown -R 1000:1000 /path/to/your/data`
- Si tu gardes un `DSSettings.txt` déjà existant en lecture seule, définis `SR_WRITE_DSSETTINGS=0` pour éviter la régénération automatique.
