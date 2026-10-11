# build/

这个目录存放构建镜像所需的文件。**这些文件受各自版权保护，不随仓库上传**。

## 必需文件

| 文件 | 获取方式 | 用途 |
|---|---|---|
| `tModLoader.zip` | tModLoader 官方 GitHub Release（选 Linux 客户端） | tModLoader 本体 |
| `CalamityMod2.0.5.tmod` | tModLoader 模组浏览器 / 创意工坊离线包 | Calamity 主模组 |
| `CalamityModMusic2.0.5.tmod` | 同上 | Calamity 音乐 |
| `CalamityCN2.0.5.tmod` | 汉化社区 | Calamity 汉化 |

## 可选文件

| 文件 | 用途 |
|---|---|
| `terraria_v1_4_4_9_v4_*.sh` | GOG 版 Terraria 安装包，用于在主机安装 GOG 版（**不参与镜像构建**，只是备份） |

## 版本对齐要求

- tModLoader 版本必须匹配 `Terraria.runtimeconfig.json` 里的 `net8.0` 目标框架
- 三个 `.tmod` 文件都必须是 **1.4.4** 版本才能跟 tModLoader 兼容
- Calamity 各模块版本号应一致（都是 2.0.5）

不匹配的表现：
- `The mod was built for a different tModLoader version`
- 加载模组时崩溃或功能异常
