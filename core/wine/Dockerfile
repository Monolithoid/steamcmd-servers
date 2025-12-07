FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    STEAMCMD_ROOT=/home/steam/Steam \
    WINEARCH=win64

RUN useradd --create-home --shell /bin/bash steam

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        wine64 \
        wine32 \
        xvfb \
        lib32gcc-s1 && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/steamcmd && \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -o /tmp/steamcmd.zip && \
    apt-get update && apt-get install --yes unzip && \
    unzip /tmp/steamcmd.zip -d /opt/steamcmd && \
    rm /tmp/steamcmd.zip && \
    apt-get purge --yes unzip && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

USER steam
WORKDIR /opt/steamcmd

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
