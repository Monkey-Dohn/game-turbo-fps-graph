# 给小米澎湃 OS4 的 Game Turbo 性能面板恢复帧率曲线

---

## 效果

| | 改造前 | 改造后 |
|---|---|---|
| 帧率曲线 | 被隐藏，只剩圆形表盘和大号数字 | 顶部显示约 60dp 高的青色曲线 |
| 圆形表盘 | 显示 | 隐藏 |
| FPS 数字 | 居中大号数字 | 移到 CPU / 内存中间：`82 FPS` |
| 样式 | — | 无背景、无描边；数字 16sp 青色，`FPS` 8sp 灰白 |
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
| 模块 | `com.doubao.fpsgraph`，versionName `1.0` |

其它机型或 HyperOS 版本可以复用思路，但布局资源 ID 和混淆后的类名可能不同，**不保证直接可用**。不要为了适配其它版本去替换系统 APK。

---

## 实现过程

### 1. 确认宿主

Game Turbo 没有独立 APK，它内嵌在系统应用 `com.miui.securitycenter` 里，并使用小米平台签名。直接用 debug 签名重打包替换 `/product/priv-app/MIUISecurityCenter/MIUISecurityCenter.apk` 会签名不匹配，也不能随意写系统分区。

所以这条路从一开始就排除了：

```text
改系统 APK → 重新签名 → 替换系统分区
```

只能走运行时 Hook：

```text
LSPosed 模块 → 进入 securitycenter 进程 → Hook 面板 View → 改内存里的 View 树
```

### 2. 定位被隐藏的控件

新版布局：

| 项目 | 值 |
|---|---|
| 布局名 | `game_toolbox_performance_panel_view_new` |
| 资源 ID | `0x7f0e01e0` |
| 默认文件 | `res/cO0.xml` |
| 横屏变体 | `res/vN1.xml` |
| sw600dp 横屏 | `res/Kgp.xml` |

关键控件：

| 控件 | 资源 ID | 原状态 |
|---|---|---|
| `FrameRateView` | `0x7f0b04f1` | `visibility=gone`，宽高 `0dp` |
| 顶部 `FrameLayout` | `0x7f0b04a3` | 曲线的父容器 |
| 圆形表盘 `ImageView` | `0x7f0b08fb` | 可见 |
| 大号 FPS `TextView` | `0x7f0b0e85` | 可见，位于表盘下方 |
| CPU / 内存行 | `0x7f0b082B` | `ConstraintLayout` |
| CPU 列 | `0x7f0b07FF` | 用于克隆 `LayoutParams` |

结论：曲线代码没有删，数据也还在，只是控件被设成了不可见、零尺寸。

旧布局 `game_toolbox_performance_panel_view`（`0x7f0e01df`，`res/iwB.xml`）里 `FrameRateView` 是可见的、251×54dp，但旧类 `PerformancePanelView` 已经不在 dex 里，直接换布局会找不到类，所以放弃“切旧布局”的方案。

### 3. 选择 Hook 点

最终 Hook 的是：

```text
PerformancePanelViewNew.onAttachedToWindow
```

没有 Hook 构造器，原因是构造器可能错过已经预加载的面板；面板 attach 到窗口时，View 树已经完整，适合做恢复。

Hook 里全部通过 `XposedHelpers` / 反射访问目标类，模块自身只引用 framework 类型和 Xposed API，避免：

```text
NoClassDefFoundError / check-cast 目标类失败
```

### 4. 恢复曲线

在 `onAttachedToWindow` 之后：

1. 找到 `FrameRateView`；
2. 设 `visibility=VISIBLE`；
3. 把布局参数改为 `MATCH_PARENT × 60dp`，`topMargin=20dp`；
4. 从原父容器移除，再 `addView` 到顶部父容器的 index 0；
5. 隐藏圆形表盘。

曲线刚打开时只有左侧短段，因为 `MAX_FRAME_RATE_DATA_COUNT=240`，约 1 秒 1 点；等待约 60 秒才会铺满，这不是布局截断。

### 5. 调整 FPS 读数

原来的大号 `TextView` 是居中显示的。最终没有做“徽章”，而是把它改成水平内联：

```text
CPU 49%        82 FPS        内存 59%
```

做法：

1. 把大号 TextView 从原父容器移除；
2. 外面包一层透明 `FrameLayout`，布局参数克隆 CPU 列的 `ConstraintLayout.LayoutParams`；
3. 内部放一个水平 `LinearLayout`，底部对齐；
4. 数字 16sp、青色 `#FF3CEDFF`、`sans-serif-medium`、字距 `0.01`；
5. `FPS` 标签 8sp、`#99FFFFFF`、字距 `0.12`、左 padding 4dp；
6. 无背景、无描边、无圆角；整体 `translationY=5dp`；
7. 最后调用 `setRenderEnabled(true)`。

### 6. 验证与回滚

验证点：

- 顶部曲线出现，右侧刻度 120 / 90 / 60；
- 圆形表盘消失；
- CPU / 内存中间只有一个 `FPS` 读数，没有重复标签；
- 数字随游戏帧率变化；
- 曲线等待约 60 秒铺满；
- LSPosed 日志只出现一次面板应用记录。

回滚：

```text
LSPosed 停用模块 → 重启
```

模块只改运行时 View，不写系统分区，也不替换系统 APK。

---

## 关键坑

### 不能直接引用目标类

模块的类加载器看不到 `com.miui.securitycenter` 的类。不能写：

```text
check-cast 到 PerformancePanelViewNew / FrameRateView
```

否则运行时会 `NoClassDefFoundError`。全部改用 `XposedHelpers.findClass`、`findViewByResourceId` 和反射字段/方法。

### ConstraintLayout 被 R8 混淆

`androidx.constraintlayout.widget.ConstraintLayout` 的内部类被混淆成类似 `ConstraintLayout$b`，不能按 `startToStart` 等字段名反射设置约束。

可靠做法是克隆 CPU 列已有的 `LayoutParams`，再用 `XposedHelpers.newInstance` 复制，只改公开的 `width/height`。

### 构造器 Hook 会重复或错过

只 Hook 构造器时，预加载面板可能已存在；同时 Hook 构造器和 `onAttachedToWindow` 又会重复应用，出现两个 `FPS` 标签，曲线也被反复 reparent 导致数据重置。

最终只 Hook `onAttachedToWindow`，并用静态 `int lastCurve` 保存 `System.identityHashCode(FrameRateView)`；同一个曲线 View 只应用一次。

### View tag 不能当守卫

目标代码会覆盖 View 的 tag，用 `getTag()` 做“已处理”标记不可靠。这也是 v8–v13 出现重复标签的原因之一。

### 曲线短不是布局问题

刚打开只有左侧一小段是正常累积过程。等待约 60 秒再判断。

---

## 迭代记录

- v1：直接 `check-cast` 目标类，运行时类加载失败；改为全反射。
- v2–v4：恢复 `FrameRateView`，曲线重新出现。
- v5：尝试按字段名设置 ConstraintLayout 约束，触发混淆字段异常；改为克隆 CPU 列 LayoutParams。
- v6：裸数字放进 CPU/内存行，视觉不合格。
- v7：尝试 FPS 徽章，被否决。
- v8–v13：水平内联方案出现重复 `FPS` 标签、曲线数据重置；定位为重复 Hook / tag 守卫失效。
- v15–v17：只 Hook `onAttachedToWindow`，加 `identityHashCode` 守卫；最终稳定为单个内联 `FPS`。

---

## 从源码重建

依赖：

- Windows + PowerShell
- Java 8
- smali / dexlib2 / guava / antlr / jcommander / util
- Android SDK Build-Tools（`zipalign`、`apksigner`）
- ADB（仅部署调试时需要）

步骤：

1. 打开 `rebuild.ps1`，按本机路径修改顶部变量：
   - `$Java`
   - `$SmaliRoot`
   - `$BuildTools`
   - `$Adb`
2. 执行：

   ```powershell
   .\rebuild.ps1
   ```

脚本会把 `src/*.smali` 汇编成 `classes.dex`，替换进 `unsigned.apk`，再对齐、签名，输出 `fpsgraph.apk`。构建产物不提交进仓库。

> `debug.keystore` 只用于调试签名；长期维护建议换成自己的 key，并固定同一个 key 更新。

---

## 项目结构

| 路径 | 用途 |
|---|---|
| `src/Main.smali` | 模块入口，注册 LSPosed Hook |
| `src/PanelHook.smali` | 恢复曲线、隐藏表盘、调整 FPS 位置 |
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
