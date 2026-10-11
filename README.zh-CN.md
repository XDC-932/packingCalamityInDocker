# packingCalamityInDocker

> 把你喜欢的 Calamity 版本打包进 Docker，直接游玩。

**🌐 语言：** [English](README.md) · **中文**

[![Platform](https://img.shields.io/badge/platform-Linux-blue)]()
[![Docker](https://img.shields.io/badge/docker-compose%20v2-blue)]()
[![tModLoader](https://img.shields.io/badge/tModLoader-1.4.4-green)]()
[![Calamity](https://img.shields.io/badge/Calamity-2.0.5-red)]()

---

## 简介

在 Docker 里运行 **tModLoader 1.4.4 客户端** + **Calamity 2.0.5**，
完全隔离于主机 Steam，存档持久化到宿主机本地目录。

**目标环境**：Debian trixie + niri (Wayland) + Intel Iris Xe / NVIDIA 混合显卡。
其他发行版/桌面环境可能需要微调，
见 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。

## 特性

- ✅ **不依赖 Steam**：tModLoader 用 `-nosteam` 启动，容器里没有 Steam
- ✅ **存档持久化**：`./data/` 目录挂载到宿主机，容器删了也不丢
- ✅ **版本冻结**：tModLoader 和模组打包在镜像里，不自动更新
- ✅ **硬件加速**：GPU 直通 + Wayland 直连，不经过 XWayland 软渲染
- ✅ **代理支持**：容器内 `http_proxy` 指向宿主机的 Clash（`network_mode: host`）
- ✅ **模组免下载**：本地 `.tmod` 文件打包进镜像，不联创意工坊

## 依赖

| 组件 | 要求 |
|---|---|
| 主机 OS | Linux，含 Docker + docker-compose |
| Docker | 20.10+，支持 compose v2 |
| 桌面环境 | Wayland（推荐）或 X11 |
| GPU | Intel 集显（Mesa）最佳；NVIDIA 独显见下方说明 |
| 主机文件 | GOG 版 Terraria 1.4.4 安装包、tModLoader.zip、Calamity 模组 |

## 目录结构

```
.
├── build/                # 构建材料（.gitignore 排除版权文件）
│   ├── tModLoader.zip         ← 需自行下载
│   ├── terraria_*.sh          ← GOG 安装包（可选）
│   ├── CalamityMod2.0.5.tmod          ← 需自行准备
│   ├── CalamityModMusic2.0.5.tmod     ← 需自行准备
│   └── CalamityCN2.0.5.tmod           ← 需自行准备
├── data/                 # 持久化数据（.gitignore 排除）
│   ├── Content/             ← 首次启动自动复制
│   ├── .local/share/Terraria/tModLoader/   ← 存档、玩家、ModConfigs
│   ├── .cache/
│   └── .runtime/
├── dotnet/               # .NET 8 运行时缓存（.gitignore 排除）
├── logs/                 # tModLoader 日志（.gitignore 排除）
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── docs/
    └── TROUBLESHOOTING.md
```

## 快速开始

### 1. 获取所需的文件

**tModLoader 客户端**（1.4.4，含 `.NET 8` 目标框架）：
- 从 tModLoader 官方 GitHub Release 或论坛下载 Linux 客户端包
- 解压后目录里应有 `start-tModLoader.sh`、`tModLoader.dll`、`LaunchUtils/` 等
- 把 zip 放到 `build/tModLoader.zip`

**Terraria GOG 版**（1.4.4.9 或对应版本）：
- 从 GOG.com 购买并下载 Linux 安装包
- 安装到一个目录，例如 `~/Documents/Calamity/Terraria/`
- 最终路径应为 `~/Documents/Calamity/Terraria/game/`，里面有
  `Terraria.exe`、`Content/`、`FNA.dll` 等

**Calamity 模组**：
- 从 tModLoader 模组浏览器下载 2.0.5 版本（或从创意工坊离线包提取）
- 需要三个文件：
  - `CalamityMod2.0.5.tmod`
  - `CalamityModMusic2.0.5.tmod`
  - `CalamityCN2.0.5.tmod`（汉化包）
- 全部放入 `build/`

### 2. 配置环境变量

```bash
cp .env.example .env
vim .env
```

按实际修改：

```bash
HOST_UID=1000
HOST_GID=1000
```

`id -u` / `id -g` 确认。

### 3. 修改 `docker-compose.yml` 里的路径

**必须修改**以下绝对路径（把 `/home/xdc` 换成你的用户主目录）：
- `/home/xdc/.Xauthority:/data/.Xauthority:ro`
- `/home/xdc/Documents/Calamity/Terraria/game:/opt/terraria-gog:ro`
- `/run/user/1000:/run/user/1000`

**按需修改**：
- `WAYLAND_DISPLAY=wayland-1`：`echo $WAYLAND_DISPLAY`，X11 用户删掉这行
- `SDL_VIDEODRIVER=wayland`：X11 用户改为 `x11`
- 代理端口 `7890`：改为实际值，不用代理可整段删除
- `group_add` 里的 `992`/`44`：`getent group render video` 获取实际 GID

### 4. 准备目录

```bash
mkdir -p build data dotnet logs
```

### 5. 构建并启动

```bash
docker compose build
docker compose up
```

**首次启动**会：
- 复制 GOG 的 `Content/` 到 `data/Content/`（几百 MB，一次性）
- 下载 .NET 8 运行时到 `dotnet/`（约 30 MB，一次性）
- 启动 tModLoader

### 6. 加载模组

窗口出来后：
1. 进主菜单 → **Mods**
2. 勾选 `CalamityMod`、`CalamityModMusic`、`CalamityCN`
3. 点 **Reload Mods**

### 7. 玩完停

```bash
docker compose down
# Wayland 环境不需要 xhost，X11 环境可选：
# xhost -SI:localuser:$(whoami)
```

## 存档位置

**所有数据**都在宿主机的 `./data/` 下：

```
data/
├── Content/                                      ← Terraria 资源
└── .local/share/Terraria/tModLoader/
    ├── Mods/                                     ← 模组（.tmod 文件）
    ├── Worlds/                                   ← 世界存档
    ├── Players/                                  ← 玩家存档
    ├── ModConfigs/                               ← 模组配置
    └── config.json
```

**跟主机 Steam 完全隔离**。Steam 版 tModLoader 的存档在 Proton prefix
里，路径完全不同。

备份：

```bash
tar czf tmod-backup-$(date +%F).tar.gz -C data .
```

## 常用命令

```bash
docker compose up                     # 前台启动，看日志
docker compose up -d                  # 后台启动
docker compose logs -f                # 看日志
docker compose exec tmodloader bash   # 进容器
docker compose restart                # 重启
docker compose build --no-cache       # 完全重建（改 Dockerfile 后）
docker compose down                   # 停止并删除容器（保留 data/）
```

## 版本锁定原理

| 层 | 机制 |
|---|---|
| tModLoader 本体 | `COPY build/tModLoader.zip`，镜像一旦构建版本即固定 |
| 模组 | `.tmod` 文件 COPY 进 `Mods-injected/`，首次启动拷到 `/data` |
| 更新检查 | `ScriptCaller.sh -nosteam` 跳过 Steam 分支，不联创意工坊 |
| .NET 运行时 | `data/dotnet` 持久化，版本由 `runtimeconfig.json` 决定 |

**重建镜像 = 换版本**。日常使用不会自动更新。

## 关于 GPU

本仓库默认走 **Intel 集显 + Mesa**（`iris_dri.so`）。
NVIDIA 独显需要额外的 `nvidia-container-toolkit` 和 Prime Render Offload
环境变量，超出本仓库范围。

**没有独显也可以软件渲染**，但会明显卡顿（2D 像素游戏勉强能玩，
大世界 + Calamity 会掉到 20-30 fps）。
软件渲染的临时方案：在 `docker-compose.yml` 的 `environment:` 里加

```yaml
- LIBGL_ALWAYS_SOFTWARE=1
- GALLIUM_DRIVER=llvmpipe
```

## 已知限制

- **不支持 Steam 创意工坊**：模组通过 `.tmod` 文件手动管理
- **不支持 Steam 云存档**：存档只在 `./data/`
- **不支持 Steam 多人联机**：可以 IP 直连，但不能通过 Steam 好友加入
- **玩家名是本地名**，不是 Steam 昵称
- **trixie 的包名变化**：`libasound2` → `libasound2t64`，
  `lib32gcc-s1` 没有 i386 版本；见 Dockerfile 注释

## 排错

见 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。

## 免责声明

本仓库**不包含**任何 Terraria / tModLoader / Calamity 的版权文件。
使用者需自行从合法渠道获取这些文件，并遵守其各自的授权条款。

## 许可

本仓库的构建脚本和配置文件以 MIT 许可证发布。游戏和模组本身遵循各自的授权。
