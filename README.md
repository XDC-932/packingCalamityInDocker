# packingCalamityInDocker

> Pack your favorite Calamity version into a Docker container and play it directly.

**🌐 Language:** **English** · [中文](README.zh-CN.md)

[![Platform](https://img.shields.io/badge/platform-Linux-blue)]()
[![Docker](https://img.shields.io/badge/docker-compose%20v2-blue)]()
[![tModLoader](https://img.shields.io/badge/tModLoader-1.4.4-green)]()
[![Calamity](https://img.shields.io/badge/Calamity-2.0.5-red)]()

---

## Introduction

Run **tModLoader 1.4.4 client** + **Calamity 2.0.5** inside a Docker container,
fully isolated from the host's Steam installation, with saves persisted to a
host directory.

This setup uses **host-mount mode**. tModLoader is not baked into the image.
Instead, you mount the tModLoader directory from your host. This means upgrading
tModLoader requires only replacing files on the host, without rebuilding the image.

**Target environment**: Debian trixie + Wayland (e.g., niri) + Intel iGPU.

## Features

- ✅ **No Steam dependency**: tModLoader runs with `-nosteam`, no Steam inside the container
- ✅ **Persistent saves**: `./data/` is bind-mounted to the host, survives container deletion
- ✅ **Easy version switching**: Upgrade tModLoader by replacing host files + `docker compose restart`
- ✅ **GPU acceleration**: DRI passthrough + native Wayland
- ✅ **Proxy support**: container `http_proxy` points to host Clash (`network_mode: host`)

## Requirements

| Component | Requirement |
|---|---|
| Host OS | Linux with Docker + docker-compose |
| Docker | 20.10+ with compose v2 |
| Desktop | Wayland (recommended) or X11 |
| GPU | Intel iGPU (Mesa) preferred |
| Host files | GOG Terraria 1.4.4, tModLoader zip, Calamity mods |

## Directory Layout

```text
.
├── build/                # Build inputs (.gitignore excludes copyrighted files)
├── tmodloader/           # tModLoader client (Extracted here on host)
├── data/                 # Persistent data (saves, mods, Content)
├── dotnet/               # .NET runtime cache
├── logs/                 # tModLoader logs
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── docs/
```

## Quick Start

### 1. Obtain the required files

**tModLoader client** (1.4.4):
- Download the Linux client package from official sources.
- Extract it directly into `./tmodloader/` on your host.
- Ensure `LaunchUtils/`, `tModLoader.dll`, etc., are in the root of `tmodloader/`.

**Terraria GOG edition** (1.4.4.9):
- Install on host, e.g., `~/Documents/Calamity/Terraria/game/`.

**Calamity mods**:
- Place your `.tmod` files into `data/.local/share/Terraria/tModLoader/Mods/`.

### 2. Configure environment

```bash
cp .env.example .env
vim .env
```
Set `HOST_UID` and `HOST_GID` (`id -u` / `id -g`).

### 3. Edit paths in `docker-compose.yml`

**Must edit** paths:
- Replace `/home/xdc` with your actual home directory.
- Update `/run/user/1000` with your actual UID.
- Update `group_add` (992/44) with your actual GIDs (`getent group render video`).
- (Optional) Update proxy port `7890`.

### 4. Prepare directories & Launch

```bash
mkdir -p data dotnet logs
xhost +SI:localuser:$(whoami) # X11 only
docker compose up
```

## Upgrading tModLoader

Because of host-mount mode, no image rebuild is needed:
1. Delete the contents of `tmodloader/`
2. Extract the new tModLoader zip into `tmodloader/`
3. `docker compose restart`

## Save Files & Mods

Saves are at `./data/.local/share/Terraria/tModLoader/`.
Fully isolated from host Steam.

## Disclaimer

This repository **does not contain** any copyrighted files.
