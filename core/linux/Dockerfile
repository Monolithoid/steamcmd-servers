FROM debian:12-slim

ENV STEAMCMD_DIR=/opt/steamcmd \
    SERVER_DIR=/opt/server \
    STEAM_HOME=/home/steam \
    PERSIST_STEAM_HOME=0 \
    PERSIST_STEAM_HOME_DIR=/opt/steam-home \
    STEAM_LOGIN=anonymous \
    STEAM_BRANCH=public \
    STEAM_VALIDATE=0 \
    LD_LIBRARY_PATH=/opt/steamcmd/linux64

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      lib32gcc-s1 \
      lib32stdc++6 \
      tini \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${STEAMCMD_DIR}" "${SERVER_DIR}" && \
    cd "${STEAMCMD_DIR}" && \
    curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
      | tar -xz

RUN mkdir -p "${PERSIST_STEAM_HOME_DIR}" && \
    useradd -m -d "${STEAM_HOME}" -s /bin/bash steam && \
    chown -R steam:steam "${STEAMCMD_DIR}" "${SERVER_DIR}" "${PERSIST_STEAM_HOME_DIR}"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER steam
WORKDIR "${SERVER_DIR}"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
