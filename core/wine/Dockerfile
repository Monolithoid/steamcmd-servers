FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV SERVER_DIR=/opt/server \
    WINEPREFIX=/home/steam/.wine \
    WINEARCH=win64

RUN apt-get update && \
    sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      cabextract \
      unzip \
      wine \
      wine32:i386 \
      wine64 \
      winetricks \
      xvfb \
      xauth \
      winbind \
      tini \
    && rm -rf /var/lib/apt/lists/*

RUN wine --version

RUN mkdir -p "${SERVER_DIR}"

RUN useradd -m -d /home/steam -s /bin/bash steam && \
    chown -R steam:steam "${SERVER_DIR}"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER steam
WORKDIR "${SERVER_DIR}"

# Pré-initialisation du préfixe Wine (non bloquant)
RUN winecfg || true

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
