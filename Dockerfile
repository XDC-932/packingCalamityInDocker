FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

# trixie 下：
#   libasound2 → libasound2t64
#   lib32gcc-s1 / lib32stdc++6 无 i386 版本
#   libicu-dev 是 .NET 全球化支持必需
#   fonts-noto-cjk 让汉化包中文不显示成方块
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates wget curl unzip file \
        libicu-dev fonts-noto-cjk \
        lib32gcc-s1 lib32stdc++6 libc6-i386 \
        libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 \
        libfreetype6 libfontconfig1 \
        libgl1 libgl1-mesa-dri libegl1 libglu1-mesa \
        libx11-6 libxext6 libxrandr2 libxinerama1 \
        libxcursor1 libxi6 libxfixes3 libxxf86vm1 \
        libopenal1 libpulse0 pulseaudio-utils \
        libasound2t64 dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    'cd /opt/tmod' \
    'find /opt/tmod -maxdepth 2 -name "*.sh" -not -perm -u+x -exec chmod +x {} + 2>/dev/null || true' \
    '[ -e /opt/tmod/Terraria.exe ] || ln -sf /opt/terraria-gog/Terraria.exe /opt/tmod/Terraria.exe' \
    '[ -e /opt/tmod/Terraria.bin.x86_64 ] || ln -sf /opt/terraria-gog/Terraria.bin.x86_64 /opt/tmod/Terraria.bin.x86_64' \
    'if [ ! -d /data/Content ]; then' \
    '  echo "[entrypoint] 首次启动，复制 Content 到 /data（一次性，几百 MB）..."' \
    '  cp -r /opt/terraria-gog/Content /data/Content' \
    'fi' \
    '[ -e /opt/tmod/Content ] || ln -sf /data/Content /opt/tmod/Content' \
    'exec ./LaunchUtils/ScriptCaller.sh -nosteam' \
    > /opt/entrypoint.sh && \
    chmod +x /opt/entrypoint.sh

WORKDIR /opt/tmod
ENTRYPOINT ["/opt/entrypoint.sh"]
