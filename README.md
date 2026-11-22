# Game Turbo FPS Graph

给小米 / 澎湃 OS 的 **Game Turbo 性能面板**恢复被新版布局隐藏的帧率曲线，并把大号 FPS 数字改成 CPU / 内存中间的极简内联读数。

*Restore the hidden frame-rate graph in Xiaomi Game Turbo and turn the FPS number into a minimal inline readout.*

**v17** · [下载 APK](https://github.com/Monkey-Dohn/game-turbo-fps-graph/releases/latest) · [Releases](https://github.com/Monkey-Dohn/game-turbo-fps-graph/releases) · [源码](https://github.com/Monkey-Dohn/game-turbo-fps-graph) · [MIT License](LICENSE)

> 这是一个 **LSPosed 模块**，不是普通独立 App。需要解锁 BL、Magisk、Zygisk 和 LSPosed。

---

## 效果

| | 默认 Game Turbo | 安装后 |
|---|---|---|
| 帧率曲线 | 被隐藏，只剩表盘和大号数字 | 顶部显示约 60dp 高的青色曲线 |
| 圆形表盘 | 显示 | 隐藏 |
| FPS 数字 | 居中大号数字 | 移到 CPU / 内存中间：`82 FPS` |
| 样式 | — | 无背景、无描边，数字 16sp 青色，`FPS` 8sp 灰白 |
| 曲线数据 | — | 约 1 秒 1 点，刚打开只有左侧短段，约 60 秒铺满 |

示意：

```text
┌──────────────────────────────────────────┐
│  帧率曲线（60dp）          刻度 120/90/60 │
├──────────────────────────────────────────┤
│  CPU 49%          82 FPS          内存 59% │
├──────────────────────────────────────────┤
│  均衡模式                      性能模式   │
└──────────────────────────────────────────┘
```

---

## 下载安装

### 直接下载

- [最新 Release](https://github.com/Monkey-Dohn/game-turbo-fps-graph/releases/latest)
- 当前附件：[`game-turbo-fps-graph-v17.apk`](https://github.com/Monkey-Dohn/game-turbo-fps-graph/releases/download/v17/game-turbo-fps-graph-v17.apk)

APK 信息：

| 项 | 值 |
|---|---|
| 包名 | `com.doubao.fpsgraph` |
| versionName | `1.0` |
| 大小 | 12,755 B |
| SHA256 | `231B0FE06CBEFD8A3937156245ED922F0018BFB9BDF019277E2AB5FB74EBD00F` |
| 签名 | Android Debug（个人模块，非生产签名） |

### 前置条件

- 小米 `M2007J17C` / `gauguinpro`
- HyperOS `4.0.5.0.XPCCNXM`，Android 17 / SDK 37
- Game Turbo 宿主：`com.miui.securitycenter` `13.6.5-261003.0.1`
- Bootloader 已解锁
- Magisk + Zygisk
- LSPosed 2.2.1（模块声明 `xposedminversion=93`）

### 安装步骤

1. 下载并安装上面的 APK。
2. 打开 **LSPosed**，进入「模块」，启用 **FPS Graph**。
3. 在作用域里只勾选 **`com.miui.securitycenter`**；如果列表里看不到，先开启「显示系统应用」。
4. 重启手机，或强制停止安全中心：

   ```bash
   adb shell am force-stop com.miui.securitycenter
   ```

5. 打开游戏，从屏幕左侧滑出 Game Turbo 侧边栏，进入性能面板。
6. 顶部出现曲线、CPU / 内存中间出现内联 FPS 即生效。

> 刚打开时曲线只有左侧一小段是正常的：数据约 1 秒 1 点，等待约 60 秒会铺满整个宽度。

---

## 兼容性

当前只在下面这套环境完整验证：

| 项目 | 值 |
|---|---|
| 机型 | Xiaomi `M2007J17C` / `gauguinpro` |
| 系统 | HyperOS `4.0.5.0.XPCCNXM` |
| Android | 17 / SDK 37 |
| Build | `CP2A.260605.016` |
| Game Turbo 宿主 | `com.miui.securitycenter` `13.6.5-261003.0.1` |
| Root | Magisk 31.1 + Zygisk |
| Hook 框架 | LSPosed 2.2.1 |
| 模块 | `com.doubao.fpsgraph`，versionName `1.0` |

其它机型或 HyperOS 版本可以复用思路，但布局资源 ID 和混淆后的类名可能不同，**不保证直接可用**。不要为了适配其它版本去替换系统 APK。

---

## 工作原理

Game Turbo 没有独立 APK，它内嵌在系统应用 `com.miui.securitycenter` 里，并使用小米平台签名，不能直接重打包替换。

新版布局把真正画曲线的 `FrameRateView` 设成了：

```text
visibility = gone
width = 0dp
height = 0dp
```

曲线代码本身还在。模块在 `PerformancePanelViewNew.onAttachedToWindow` 时：

1. 找到 `FrameRateView`，恢复可见；
2. 把高度改为 60dp、上边距 20dp，并移到顶部容器；
3. 隐藏圆形表盘；
4. 把原来的大号 FPS 数字移到 CPU / 内存中间，改成水平内联读数。

整个过程只修改运行时的 View 树，**不修改系统分区，也不修改 APK 文件**。停用模块即可回滚。

---

## 常见问题

### 装了但没效果

按顺序检查：

1. LSPosed 里模块是否已启用；
2. 作用域是否勾了 `com.miui.securitycenter`；
3. 是否重启过，或执行过 `am force-stop com.miui.securitycenter`；
4. 系统版本是否与上面的兼容表一致；
5. 是否安装了旧版本模块；同包名换签名时需要先卸载旧版。

### 曲线为什么只有一小段

正常。`FrameRateView` 约 1 秒采集 1 个点，`MAX_FRAME_RATE_DATA_COUNT=240`，所以要等约 60 秒才铺满，不是布局被截断。

### 能不能不用 root

不能。模块依赖 LSPosed，而 LSPosed 需要 Magisk/Zygisk 环境。

### 会不会改系统、影响 OTA

不会写系统分区，也不替换系统 APK；它只在目标进程运行时改 View。停用模块或卸载后即恢复原样。但解锁 BL、root 本身会影响 OTA/保修状态，这部分风险由使用者承担。

### 为什么 APK 这么小

这是一个 smali 编写的 Hook 模块，只包含模块入口、Hook 代码和清单，不包含 Game Turbo 或系统应用的代码。

### 支持其它小米机型吗

不保证。不同 HyperOS 版本的布局资源 ID、类名混淆结果可能不同；需要重新核对 `FrameRateView`、`PerformancePanelViewNew` 和父容器 ID。当前仓库只针对上面这套环境。

### 为什么是 debug 签名

这是个人维护的 LSPosed 模块，没有上架应用商店。debug 签名不影响 LSPosed 使用；但同一包名的更新必须使用同一签名，否则要先卸载旧版。

### 模块会联网/收集数据吗

模块 manifest 未申请网络权限。它只在 `com.miui.securitycenter` 进程内做 View Hook。

---

## 从源码构建

普通用户不需要自己编译，直接下载 Release APK 即可。

### 依赖

- Windows + PowerShell
- Java 8
- smali / dexlib2 / guava / antlr / jcommander / util
- Android SDK Build-Tools（`zipalign`、`apksigner`）
- ADB（仅 `-Install` 时需要）

### 构建

1. 打开 `rebuild.ps1`，按本机路径修改顶部变量：
   - `$Java`
   - `$SmaliRoot`
   - `$BuildTools`
   - `$Adb`
2. 执行：

   ```powershell
   # 只构建并签名
   .\rebuild.ps1

   # 构建、安装，并在安装后删除本地安装包
   .\rebuild.ps1 -Install
   ```

脚本会把 `src/*.smali` 汇编成 `classes.dex`，替换进 `unsigned.apk`，再对齐、签名，输出 `fpsgraph.apk`。签名 APK 不会提交进仓库。

> `debug.keystore` 只用于本地调试。如果要长期分发，建议换成自己的签名 key，并固定使用同一个 key 更新。

---

## 项目结构

| 路径 | 用途 |
|---|---|
| `src/Main.smali` | 模块入口，注册 LSPosed Hook |
| `src/PanelHook.smali` | 恢复曲线、隐藏表盘、调整 FPS 位置 |
| `unsigned.apk` | 含 manifest、资源、assets 的基础 APK |
| `AndroidManifest.xml` | LSPosed 模块清单 |
| `xposed_init.txt` | 模块入口类 |
| `rebuild.ps1` | 汇编、替换 dex、对齐、签名、可选安装 |
| `debug.keystore` | 调试签名，非生产 key |
| `docs/DEVELOPMENT.md` | 开发与调试笔记：根因、资源 ID、构建、排错 |
| `PUBLISH-TO-GITHUB.md` | GitHub 发布/Release 操作记录 |
| `LICENSE` | MIT |

---

## 安全与回滚

- 模块不修改 `/system`、`/product` 等系统分区，也不替换系统 APK。
- 回滚：在 LSPosed 中停用模块 → 重启；或直接卸载模块。
- 解锁 BL、root、LSPosed 都有设备风险；请先备份，不要在主业务机上直接试验。
- 本模块只针对上述兼容环境，不保证其它机型/版本。

---

## 开发者文档

更深入的内容在 [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)：布局资源 ID、`PerformancePanelViewNew` / `FrameRateView` 结构、Smali Hook 细节、重复 Hook 的坑、构建命令和实测记录。

发布流程见 [`PUBLISH-TO-GITHUB.md`](PUBLISH-TO-GITHUB.md)。

问题反馈：[GitHub Issues](https://github.com/Monkey-Dohn/game-turbo-fps-graph/issues)

---

## License

[MIT](LICENSE)

本项目与小米 / 小米澎湃 OS 官方无关；Xiaomi、HyperOS、Game Turbo 是其各自权利人的商标。使用本模块造成的设备问题由使用者自行承担。
