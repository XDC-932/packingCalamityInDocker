FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

# ── 系统运行库 ──
# trixie 下：
#   libasound2 → libasound2t64
#   lib32gcc-s1 / lib32stdc++6 无 i386 版本，直接按 amd64 包名装
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

# ── tModLoader 客户端 ──
ARG UID=1000
ARG GID=1000
WORKDIR /opt/tmod
COPY build/tModLoader.zip /tmp/
RUN unzip -q /tmp/tModLoader.zip -d /opt/tmod && \
    rm /tmp/tModLoader.zip && \
    find /opt/tmod -name '*.sh' -exec chmod a+x {} + && \
    chown -R $UID:$GID /opt/tmod

# ── 模组（冻结在镜像里）──
COPY build/*.tmod /opt/tmod/Mods-injected/
RUN chown -R $UID:$GID /opt/tmod/Mods-injected

# ── 启动脚本 ──
#
# 关键设计：
#
#   1. 只软链 Terraria.exe + Terraria.bin.x86_64 + Content 到 /opt/tmod/
#      —— tModLoader 靠 "Terraria.exe 是否存在" 判断是否是 GOG 版；
#         软链之后它就走 GOG 分支，跳过 Steam 验证。
#
#   2. 绝不软链任何 .dll（FNA.dll、System.dll、mscorlib.dll 等）
#      —— GOG 自带的 .NET Framework 旧程序集会"抢"tModLoader 的
#         .NET 8 程序集加载，导致 SIGSEGV 段错误（exit code 139）。
#
#   3. Content 必须复制到可写的 /data 里
#      —— tModLoader 启动时会尝试修复资源文件的大小写（Windows 打包的
#         文件名常与 Linux 大小写不一致），只读挂载会报 "Read-only file system"。
#         复制一次到 /data/Content，之后一直复用。
#
#   4. 用 exec 启动 ScriptCaller，让它成为 PID 1
#      —— 官方 start-tModLoader.sh 里把 ScriptCaller 放后台（`&`），
#         在 Docker 里会导致 PID 1 退出 → 容器立即结束。
#
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    'cd /opt/tmod' \
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

ENTRYPOINT ["/opt/entrypoint.sh"]
