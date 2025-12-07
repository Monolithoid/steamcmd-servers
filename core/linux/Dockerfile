FROM debian:12-slim

ENV STEAMCMD_DIR=/opt/steamcmd \
    SERVER_DIR=/opt/server \
    STEAM_LOGIN=anonymous \
    STEAM_BRANCH=public \
    STEAM_VALIDATE=0

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

RUN useradd -m -d /home/steam -s /bin/bash steam && \
    chown -R steam:steam "${STEAMCMD_DIR}" "${SERVER_DIR}"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER steam
WORKDIR "${SERVER_DIR}"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
