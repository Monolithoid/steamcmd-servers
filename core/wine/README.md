# Wine Core Runtime

Image de base minimale pour exécuter un serveur Windows déjà installé sur l’hôte.

Cette image **n’installe plus rien via SteamCMD**. Elle sert uniquement à :

- monter le dossier serveur existant dans `/opt/server` ;
- lancer l’exécutable Windows via Wine ;
- permettre un mode terminal de debug.

Le runtime installe les composants `wine64` et `wine32` (multiarch `i386`) pour conserver `win64` par défaut tout en permettant l’exécution de binaires 32-bit via `WINEARCH=win32`.
Il inclut aussi `winetricks`, utile pour installer des dépendances Windows comme les runtimes Microsoft Visual C++.

## Variables d'environnement

- `SERVER_DIR` (par défaut `/opt/server`) : dossier du serveur monté depuis l’hôte.
- `SERVER_EXE` (par défaut `Server.exe`) : exécutable Windows à lancer.
- `SERVER_ARGS` (par défaut vide) : arguments de lancement.
- `WINEPREFIX` (par défaut `/home/steam/.wine`) : préfixe Wine.
- `WINEARCH` (par défaut `win64`) : architecture demandée pour le préfixe (`win64` ou `win32`).
- `WINE_MISMATCH_STRATEGY` (par défaut `switch`) : stratégie si l’architecture du préfixe existant ne correspond pas à `WINEARCH`.
  - `switch` : **recommandé**, ne supprime rien et bascule vers un nouveau préfixe `${WINEPREFIX}-${WINEARCH}`.
  - `recreate` : supprime/recrée le préfixe courant.
  - `error` : échoue avec un message explicite.
- `USE_XVFB` (par défaut `1`) : démarre Wine avec `xvfb-run` pour fournir un `DISPLAY` virtuel en environnement headless.
- `XVFB_SCREEN` (par défaut `0 1024x768x16`) : valeur passée à `xvfb-run -s "-screen ..."` pour régler l’écran virtuel.
- `WINETRICKS_PACKAGES` (par défaut `vcrun2022`) : liste de paquets `winetricks` à installer dans le préfixe (séparateur espace ou virgule). Exemples : `vcrun2019`, `vcrun2022`, `dotnet48`.
- `WINETRICKS_QUIET` (par défaut `1`) : passe `-q` à `winetricks` pour réduire l’interaction (`0` pour mode verbeux).
- `ENABLE_TERMINAL` (par défaut `0`) : si `1`, ouvre un shell dans `SERVER_DIR`.
- `START_SERVER` (par défaut `1`) : si `0`, n’exécute pas le serveur.

## Erreur d’architecture de préfixe Wine

Si tu vois une erreur du type :

`wine: WINEARCH set to win64 but '<prefix>' is a 32-bit installation.`

cela signifie que le dossier `WINEPREFIX` existant a été créé en `win32`.

Solutions :

1. Utiliser `WINE_MISMATCH_STRATEGY=switch` pour basculer automatiquement sur un préfixe compatible, sans suppression.
2. Ou `WINE_MISMATCH_STRATEGY=recreate` pour forcer une recréation.
3. Ou corriger manuellement le préfixe puis redémarrer.

## Erreur `nodrv_CreateWindow` / `$DISPLAY`

Si tu vois :

`Application tried to create a window, but no driver could be loaded`  
`Make sure that your X server is running and that $DISPLAY is set correctly`

alors Wine essaie d’ouvrir un contexte graphique sans serveur X disponible.

Le runtime active désormais `xvfb-run` par défaut (`USE_XVFB=1`) pour créer un affichage virtuel.
En cas de besoin, tu peux :

1. Laisser `USE_XVFB=1` (recommandé en conteneur/headless).
2. Ajuster la résolution/profondeur via `XVFB_SCREEN`.
3. Désactiver explicitement (`USE_XVFB=0`) seulement si tu fournis déjà un `DISPLAY` fonctionnel.

## Installer Microsoft Visual C++ Runtime via Winetricks

Le runtime installe désormais **par défaut** Visual C++ 2022 via `WINETRICKS_PACKAGES=vcrun2022`.
Tu peux surcharger la variable pour installer d’autres dépendances, ou la vider pour désactiver complètement Winetricks.

Exemple (Visual C++ 2022 explicite) :

```bash
docker run --rm \
  -v /opt/gaming/my-windows-server:/opt/server \
  -e SERVER_EXE="MyServer.exe" \
  -e WINETRICKS_PACKAGES="vcrun2022" \
  monolithoid/steamcmd-wine-core:latest
```

Tu peux aussi chaîner plusieurs dépendances, par exemple :

```bash
-e WINETRICKS_PACKAGES="vcrun2019,dotnet48"
```

Pour désactiver l’installation Winetricks :

```bash
-e WINETRICKS_PACKAGES=""
```

## Exemple de lancement

```bash
docker run --rm \
  -v /opt/gaming/my-windows-server:/opt/server \
  -e SERVER_EXE="MyServer.exe" \
  -e SERVER_ARGS="-log -config=server.ini" \
  -p 7777:7777/udp \
  monolithoid/steamcmd-wine-core:latest
```

## Préparation manuelle SteamCMD (sur l’hôte)

Cette commande est à exécuter **directement sur la machine d’hébergement** (hors conteneur runtime) pour installer ou mettre à jour les fichiers Windows :

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/my-windows-server \
  +login <steam_user> <steam_password> \
  +app_update <app_id> validate \
  +quit
```

Notes :

- Utilise `+login anonymous` si le serveur le permet.
- Remplace `<app_id>` par l’AppID du serveur dédié.
- Donne les droits UID/GID `1000:1000` sur le dossier monté si nécessaire.
