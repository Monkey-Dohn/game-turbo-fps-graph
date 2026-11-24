# 给小米澎湃 OS4 的 Game Turbo 性能面板恢复帧率曲线

---

## 适用环境

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
| 模块 | `com.xiaomi.fpsgraph`，versionName `1.01`（构建标记 v1.02，md5 `54a5f33f50b8c232d4d28f2887fa7f2d`） |

其它机型或 HyperOS 版本可以复用思路，但布局资源 ID 和混淆后的类名可能不同，**不保证直接可用**。不要为了适配其它版本去替换系统 APK。

---

## 项目结构

| 路径 | 用途 |
|---|---|
| `src/Main.smali` | 模块入口，注册 LSPosed Hook |
| `src/PanelHook.smali` | 恢复曲线、自绘圆形表盘、调整 FPS 读数位置 |
| `unsigned.apk` | 含 manifest、资源、assets 的基础 APK |
| `AndroidManifest.xml` | LSPosed 模块清单 |
| `xposed_init.txt` | 模块入口类 |
| `rebuild.ps1` | 汇编、替换 dex、对齐、签名 |
| `debug.keystore` | 调试签名，非生产 key |
| `docs/DEVELOPMENT.md` | 更完整的开发与调试笔记 |
| `LICENSE` | MIT |

---

## 开发者文档

更深入的内容在 [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)：完整资源 ID、`PerformancePanelViewNew` / `FrameRateView` 结构、Smali 细节、构建命令、日志和实测记录。

---

## License

[MIT](LICENSE)

本项目与小米 / 小米澎湃 OS 官方无关；Xiaomi、HyperOS、Game Turbo 是其各自权利人的商标。使用本改造造成的设备问题由使用者自行承担。
