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

**Target environment**: Debian trixie + niri (Wayland) + Intel Iris Xe / NVIDIA hybrid GPU.
Other distros / desktop environments may need adjustments —
see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Features

- ✅ **No Steam dependency**: tModLoader runs with `-nosteam`, no Steam inside the container
- ✅ **Persistent saves**: `./data/` is bind-mounted to the host, survives container deletion
- ✅ **Version pinning**: tModLoader and mods are baked into the image, no auto-update
- ✅ **GPU acceleration**: DRI passthrough + native Wayland, avoids XWayland software rendering
- ✅ **Proxy support**: container `http_proxy` points to host Clash (`network_mode: host`)
- ✅ **No mod downloads**: local `.tmod` files baked into the image, no Workshop access

## Requirements

| Component | Requirement |
|---|---|
| Host OS | Linux with Docker + docker-compose |
| Docker | 20.10+ with compose v2 |
| Desktop | Wayland (recommended) or X11 |
| GPU | Intel iGPU (Mesa) preferred; NVIDIA dGPU see note below |
| Host files | GOG Terraria 1.4.4 installer, tModLoader.zip, Calamity mods |

## Directory Layout

```
.
├── build/                # Build inputs (.gitignore excludes copyrighted files)
│   ├── tModLoader.zip         ← download yourself
│   ├── terraria_*.sh          ← GOG installer (optional)
│   ├── CalamityMod2.0.5.tmod          ← prepare yourself
│   ├── CalamityModMusic2.0.5.tmod     ← prepare yourself
│   └── CalamityCN2.0.5.tmod           ← prepare yourself
├── data/                 # Persistent data (.gitignore excluded)
│   ├── Content/             ← copied on first launch
│   ├── .local/share/Terraria/tModLoader/   ← worlds, players, ModConfigs
│   ├── .cache/
│   └── .runtime/
├── dotnet/               # .NET 8 runtime cache (.gitignore excluded)
├── logs/                 # tModLoader logs (.gitignore excluded)
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── docs/
    └── TROUBLESHOOTING.md
```

## Quick Start

### 1. Obtain the required files

**tModLoader client** (1.4.4, targeting `.NET 8`):
- Download the Linux client package from tModLoader's official GitHub release or forum
- The unzipped directory should contain `start-tModLoader.sh`, `tModLoader.dll`, `LaunchUtils/`, etc.
- Place the zip at `build/tModLoader.zip`

**Terraria GOG edition** (1.4.4.9 or matching version):
- Purchase and download the Linux installer from GOG.com
- Install to a directory, e.g. `~/Documents/Calamity/Terraria/`
- Final path should be `~/Documents/Calamity/Terraria/game/` containing
  `Terraria.exe`, `Content/`, `FNA.dll`, etc.

**Calamity mods**:
- Get version 2.0.5 from the tModLoader mod browser (or extract from a Workshop package)
- Three files needed:
  - `CalamityMod2.0.5.tmod`
  - `CalamityModMusic2.0.5.tmod`
  - `CalamityCN2.0.5.tmod` (Chinese localization)
- Place all in `build/`

### 2. Configure environment

```bash
cp .env.example .env
vim .env
```

Adjust to your actual values:

```bash
HOST_UID=1000
HOST_GID=1000
```

Verify with `id -u` / `id -g`.

### 3. Edit paths in `docker-compose.yml`

**Must edit** these absolute paths (replace `/home/xdc` with your actual home):
- `/home/xdc/.Xauthority:/data/.Xauthority:ro`
- `/home/xdc/Documents/Calamity/Terraria/game:/opt/terraria-gog:ro`
- `/run/user/1000:/run/user/1000`

**Edit as needed**:
- `WAYLAND_DISPLAY=wayland-1`: get from `echo $WAYLAND_DISPLAY`;
  X11 users should delete this line
- `SDL_VIDEODRIVER=wayland`: X11 users change to `x11`
- Proxy port `7890`: change to your actual port; delete the whole block if you don't use a proxy
- `group_add` values `992`/`44`: get real GIDs from `getent group render video`

### 4. Prepare directories

```bash
mkdir -p build data dotnet logs
```

### 5. Build and launch

```bash
docker compose build
docker compose up
```

**First launch** will:
- Copy GOG `Content/` to `data/Content/` (a few hundred MB, one-time)
- Download .NET 8 runtime to `dotnet/` (~30 MB, one-time)
- Start tModLoader

### 6. Enable mods

Once the window appears:
1. Main menu → **Mods**
2. Check `CalamityMod`, `CalamityModMusic`, `CalamityCN`
3. Click **Reload Mods**

### 7. Stopping

```bash
docker compose down
# Wayland: xhost not needed. X11 users may want:
# xhost -SI:localuser:$(whoami)
```

## Save Files

**All data** lives under `./data/` on the host:

```
data/
├── Content/                                      ← Terraria assets
└── .local/share/Terraria/tModLoader/
    ├── Mods/                                     ← mods (.tmod files)
    ├── Worlds/                                   ← world saves
    ├── Players/                                  ← player saves
    ├── ModConfigs/                               ← mod configs
    └── config.json
```

**Fully isolated from host Steam**. Steam tModLoader saves live in a Proton
prefix with a completely different path.

Backup:

```bash
tar czf tmod-backup-$(date +%F).tar.gz -C data .
```

## Common Commands

```bash
docker compose up                     # foreground, shows logs
docker compose up -d                  # background
docker compose logs -f                # tail logs
docker compose exec tmodloader bash   # shell into container
docker compose restart                # restart
docker compose build --no-cache       # full rebuild (after Dockerfile changes)
docker compose down                   # stop and remove (keeps data/)
```

## Version Locking

| Layer | Mechanism |
|---|---|
| tModLoader itself | `COPY build/tModLoader.zip`; version frozen once image is built |
| Mods | `.tmod` files COPY'd into `Mods-injected/`, copied to `/data` on first launch |
| Update check | `ScriptCaller.sh -nosteam` skips Steam branch, no Workshop access |
| .NET runtime | Persisted in `data/dotnet`, version from `runtimeconfig.json` |

**Rebuild image = version change**. No auto-updates during normal use.

## About GPU

This repo defaults to **Intel iGPU + Mesa** (`iris_dri.so`).
NVIDIA dGPU requires `nvidia-container-toolkit` and Prime Render Offload env
vars, which is out of scope here.

**Software rendering works without a dGPU**, but is noticeably slow (playable
for a 2D pixel game, but big worlds + Calamity will drop to 20-30 fps).
Quick software-render workaround: add to `docker-compose.yml`'s `environment:`:

```yaml
- LIBGL_ALWAYS_SOFTWARE=1
- GALLIUM_DRIVER=llvmpipe
```

## Known Limitations

- **No Steam Workshop**: mods managed manually via `.tmod` files
- **No Steam Cloud saves**: saves only in `./data/`
- **No Steam multiplayer**: IP direct connect works, Steam friend join does not
- **Player name is local**, not your Steam nickname
- **trixie package names**: `libasound2` → `libasound2t64`,
  `lib32gcc-s1` has no i386 variant; see Dockerfile comments

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Disclaimer

This repository **does not contain** any copyrighted Terraria / tModLoader /
Calamity files. Users must obtain these files from legitimate sources and
comply with their respective licenses.

## License

Build scripts and config files in this repo are released under the MIT License.
The game and mods follow their own licenses.
