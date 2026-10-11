# 排错记录

本项目构建过程踩过的坑，按出现顺序整理。如果你在其他环境复现，可参考。

## 1. Debian trixie 的包名变化

**现象**：`docker build` 时 apt 报 `E: Unable to locate package`

**原因**：trixie 相比 bookworm：
- `libsdl2-2.0-0` 实际包名还是这个（没 t64）
- `libasound2` 变成 `libasound2t64`
- `lib32gcc-s1` 和 `lib32stdc++6` **没有 i386 版本**，直接按 amd64 包名装（不要加 `:i386`）

**修法**：见 `Dockerfile` 的包列表。

## 2. .NET 报缺 ICU

**现象**：
```
Process terminated. Couldn't find a valid ICU package installed on the system.
```

**原因**：.NET 的全球化支持依赖 ICU 库。

**修法**：Dockerfile 里加 `libicu-dev`。

## 3. `chmod: Operation not permitted`

**现象**：容器启动时
```
chmod: changing permissions of './LaunchUtils/ScriptCaller.sh': Operation not permitted
```

**原因**：容器以 uid 1000 跑，`/opt/tmod` 里的文件属主是 root（构建时创建的）。`chmod` 只有文件属主或 root 能做。

**修法**：`Dockerfile` 里 `chown -R $UID:$GID /opt/tmod`（通过 build args 传入宿主 uid/gid）。

## 4. 容器静默退出 `exit code 0`

**现象**：`docker compose up` 后 0.5 秒容器结束，没有日志。

**原因**：tModLoader 官方 `start-tModLoader.sh` 把启动进程放后台：
```bash
./LaunchUtils/ScriptCaller.sh "$@" &
```
容器里 PID 1 退出 = 容器结束，后台进程被一起杀。

**修法**：不用 `start-tModLoader.sh`，直接 `exec ./LaunchUtils/ScriptCaller.sh -nosteam`。

## 5. `.Xauthority` 被 Docker 建成目录

**现象**：
```
error mounting "/home/xdc/.Xauthority" to rootfs at "/data/.Xauthority":
not a directory: Are you trying to mount a directory onto a file
```

**原因**：某次启动时 `/data/.Xauthority` 在容器内不存在，Docker 按挂载源的类型创建——但源文件不可访问时它会创建成目录。之后每次挂载都会失败。

**修法**：
```bash
rm -rf data/.Xauthority
```
**根治**：Wayland 环境不需要 `.Xauthority`，可以直接删掉这条 volume。

## 6. Steam 验证错误（即使传了 `-nosteam`）

**现象**：
```
tModLoader v2025.4.3.0 Error
Please ensure Steam is logged in and running.
[S_API] SteamAPI_Init(): SteamAPI_IsSteamRunning() did not locate a running instance of Steam.
```

**原因**：tModLoader 通过 **`Terraria.exe` 是否在自身目录里**判断是 GOG 版还是 Steam 版。找不到就当成 Steam 版，强制要求登录。

之前只软链了 `Terraria.bin.x86_64`，不认。tModLoader 要的是 **`Terraria.exe`**（Windows 版文件名，用来标记 GOG 身份）。

**修法**：entrypoint 里软链 `Terraria.exe` 到 `/opt/tmod/`。

## 7. `exit code 139`（SIGSEGV）—— 软链了所有 DLL 导致

**现象**：FNA 加载后立即段错误。

**原因**：entrypoint 里做 `for f in /opt/terraria-gog/*; ln -sf ...` 把 GOG 目录下所有文件都软链过去了，包括：
- `FNA.dll`
- `System.dll`、`System.Core.dll`、`mscorlib.dll` 等 .NET Framework 旧程序集

这些旧 DLL 被 .NET 8 加载，ABI 不匹配 → 段错误。

**修法**：**只软链 `Terraria.exe` + `Terraria.bin.x86_64` + `Content/`**，绝不软链任何 `.dll`。

## 8. `Read-only file system` 崩溃

**现象**：
```
System.IO.IOException: Read-only file system
   at Terraria.ModLoader.Engine.TMLContentManager.TryFixFileCasings(...)
```

**原因**：tModLoader 启动时会尝试**重命名** `Content/` 里的资源文件，把 Windows 打包时大小写不一致的文件名"修正"。GOG 目录是 `:ro` 挂载，重命名失败。

**修法**：把 `Content/` **复制**到可写的 `/data/Content/`（首次启动一次性），之后软链 `/opt/tmod/Content -> /data/Content`。

## 9. 卡顿 / 低帧率

**现象**：窗口能出来，但明显卡。

**根因**：`DISPLAY=:0` 在 Wayland 桌面（如 niri、Hyprland）下是 **XWayland**，X11 客户端走 XWayland → 合成器 → 显示，中间环节会触发软件渲染（`llvmpipe`）。

**诊断**：
```bash
grep -iE 'FNA3D|Renderer|Vendor|GPU' ./logs/client.log
```
看到 `llvmpipe` 或 `softpipe` = 软件渲染。

**修法**：让 SDL2 直连 Wayland：
```yaml
environment:
  - WAYLAND_DISPLAY=wayland-1    # 用 `echo $WAYLAND_DISPLAY` 获取
  - XDG_RUNTIME_DIR=/run/user/1000
  - SDL_VIDEODRIVER=wayland
volumes:
  - /run/user/1000:/run/user/1000
```

之后 renderer 应显示 `Mesa Intel(R) Xe Graphics` 之类。

**验证 SDL2 支持 Wayland**：
```bash
docker compose run --rm --entrypoint bash tmodloader -c \
  'ldd /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0 | grep -i wayland'
```
应有 `libwayland-client`、`libwayland-egl`、`libwayland-cursor`。

## 10. `group_add: render` 报 "no matching entries"

**现象**：
```
Error response from daemon: unable to find group render: no matching entries in group file
```

**原因**：`group_add` 按名字查找时用的是**容器内**的 `/etc/group`。Debian 容器里默认没有 `render` 组，所以找不到。

**修法**：用 **GID 数字**而不是名字：
```bash
getent group render   # 输出 render:x:992:，取 992
getent group video    # 输出 video:x:44:xdc，取 44
```
```yaml
group_add:
  - "992"
  - "44"
```

## 11. `sed: can't read /proc/0/cmdline`

**现象**：日志里偶尔出现，无害。

**原因**：`ScriptCaller.sh` 第 91 行用 `$PPID` 拼 `/proc/$PPID/cmdline`，在某些容器环境（比如被 exec 替换掉的 PID 1 场景）`$PPID` 变成 0，拼出 `/proc/0/cmdline`。

**修法**：忽略。这只是 ScriptCaller 内部一个 Steam 检测的判断失败，不影响实际运行。

## 12. 代理不生效

**现象**：容器内 `curl` 超时，下载 .NET 失败。

**原因**：Docker 容器默认不继承宿主机 `http_proxy` 环境变量。

**修法**：在 `docker-compose.yml` 的 `environment:` 里显式设置，配合 `network_mode: host` 让 `127.0.0.1` 指向主机：
```yaml
- http_proxy=http://127.0.0.1:7890
- https_proxy=http://127.0.0.1:7890
# ...
network_mode: host
```

**注意**：`127.0.0.1` 只在 `network_mode: host` 下指向主机。默认 bridge 网络下要写 `host.docker.internal`。

## 诊断命令速查

```bash
# 看容器是否在跑
docker compose ps

# 完整日志
docker compose logs -f

# tModLoader 自己的日志
tail -50 ./logs/client.log

# 容器里看设备
docker compose exec tmodloader bash -c 'ls -la /dev/dri/; id'

# 容器里看 Wayland socket
docker compose exec tmodloader bash -c 'ls -la /run/user/1000/wayland-*'

# 手动跑 tModLoader（绕过 ScriptCaller 看真实错误）
docker compose run --rm --entrypoint bash tmodloader -c '
  cd /opt/tmod
  ./dotnet/dotnet tModLoader.dll -nosteam 2>&1 | tail -40
'

# 清空所有缓存重来
docker compose down
rm -rf data/Content data/.cache data/.local dotnet
docker compose up
```
