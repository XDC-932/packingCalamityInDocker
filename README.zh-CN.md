# packingCalamityInDocker

> 把你喜欢的 Calamity 版本打包进 Docker，直接游玩。

**🌐 语言:** [English](README.md) · **中文**

[![Platform](https://img.shields.io/badge/platform-Linux-blue)]()
[![Docker](https://img.shields.io/badge/docker-compose%20v2-blue)]()
[![tModLoader](https://img.shields.io/badge/tModLoader-1.4.4-green)]()
[![Calamity](https://img.shields.io/badge/Calamity-2.0.5-red)]()

---

## 简介

在 Docker 里运行 **tModLoader 1.4.4 客户端** + **Calamity 2.0.5**，
完全隔离于主机 Steam，存档持久化到宿主机本地目录。

本项目采用 **宿主机挂载模式**。tModLoader 不打包进镜像，而是将宿主机的目录挂载进容器。
这意味着**更换 tModLoader 版本只需替换宿主机文件，无需重新构建镜像**。

**目标环境**：Debian trixie + Wayland (如 niri) + Intel 集显。

## 特性

- ✅ **不依赖 Steam**：tModLoader 用 `-nosteam` 启动
- ✅ **存档持久化**：`./data/` 挂载到宿主机，容器删了也不丢
- ✅ **秒级换版本**：替换宿主机 `tmodloader/` 文件后 `docker compose restart` 即可
- ✅ **硬件加速**：GPU 直通 + Wayland 直连
- ✅ **代理支持**：容器内代理指向宿主机 Clash (`network_mode: host`)

## 依赖

| 组件 | 要求 |
|---|---|
| 主机 OS | Linux，含 Docker + docker-compose |
| Docker | 20.10+ |
| 桌面环境 | Wayland（推荐）或 X11 |
| GPU | Intel 集显（Mesa）最佳 |
| 主机文件 | GOG 版 Terraria、tModLoader 客户端、Calamity 模组 |

## 目录结构

```text
.
├── build/                # 构建材料
├── tmodloader/           # tModLoader 本体（宿主机解压于此，挂载进容器）
├── data/                 # 持久化数据（存档、模组、Content）
├── dotnet/               # .NET 运行时缓存
├── logs/                 # 日志
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── docs/
```

## 快速开始

### 1. 获取所需的文件

**tModLoader 客户端**（1.4.4）：
- 从官方 GitHub Release 下载 Linux 客户端包。
- **直接解压到宿主机的 `./tmodloader/` 目录下**。
- 确保 `LaunchUtils/`、`tModLoader.dll` 等在 `tmodloader/` 根目录。

**Terraria GOG 版**：
- 在主机安装，例如 `~/Documents/Calamity/Terraria/game/`。

**Calamity 模组**：
- 将 `.tmod` 文件放入 `data/.local/share/Terraria/tModLoader/Mods/`。

### 2. 配置环境变量

```bash
cp .env.example .env
vim .env
```
修改 `HOST_UID` 和 `HOST_GID`（用 `id -u` / `id -g` 确认）。

### 3. 修改 `docker-compose.yml` 里的路径

**必须修改**：
- 把 `/home/xdc` 换成你的实际用户主目录。
- 把 `/run/user/1000` 里的 1000 换成你的 UID。
- `group_add` 里的 `992`/`44` 换成 `getent group render video` 的实际 GID。
- （可选）代理端口 `7890`。

### 4. 准备目录并启动

```bash
mkdir -p data dotnet logs
xhost +SI:localuser:$(whoami) # 仅限 X11
docker compose up
```

## 如何升级 tModLoader 版本

得益于挂载模式，升级无需重新构建镜像：
1. 清空 `tmodloader/` 目录
2. 将新版 tModLoader 解压到 `tmodloader/` 目录
3. 运行 `docker compose restart`

## 存档与模组位置

存档位于 `./data/.local/share/Terraria/tModLoader/`。
与主机 Steam 完全隔离。

## 免责声明

本仓库**不包含**任何版权文件。
