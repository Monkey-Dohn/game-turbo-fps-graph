# 小米 Game Turbo 帧率曲线恢复改造 — 开发与调试笔记（v1.01）

> **这是开发/调试文档，不是普通用户安装说明。** 含具体设备、资源 ID、本机构建路径、测试命令和排错记录；普通用户请回到根目录 [README.md](../README.md)。

> 给小米 / 澎湃 OS 的 Game Turbo 性能面板**恢复被隐藏的帧率曲线**，并把帧率数字改成 36dp 圆形细环表盘：只保留顶部“帧率”和中间 12sp 数字，不再显示底部 `FPS`；均衡模式圆环蓝色，性能模式圆环红色。纯 LSPosed 运行时 Hook：不改系统分区、不重打包系统 APK，停用模块即完全回滚。
>
> **适用**：小米 `M2007J17C`（gauguinpro）+ HyperOS `4.0.5.0.XPCCNXM`，宿主 `com.miui.securitycenter` `13.6.5-261003.0.1`。其它机型/版本可参考思路，资源 ID 需重新核对。
>
> **快速开始**：`.\rebuild.ps1 -Install`（依赖 Java 8 + smali 工具链 + Build Tools + ADB，路径见[第 7 节](#7-构建与部署)）。前提是已解锁 BL、装好 Magisk + Zygisk + LSPosed，并在 LSPosed 里把作用域勾选 `com.miui.securitycenter`。
>
> 许可证：MIT（见 [LICENSE](../LICENSE)）。

## 直接安装（普通用户）

不需要自己编译，直接下载 Release 里的签名 APK：

1. 打开 [Releases](https://github.com/Monkey-Dohn/game-turbo-fps-graph/releases/latest)，下载 `game-turbo-fps-graph-v1.01.apk`。
2. 手机需已解锁 BL，并装好 **Magisk + Zygisk + LSPosed**。
3. 安装 APK；在 LSPosed 中启用模块 **FPS Graph**，作用域只勾选 **`com.miui.securitycenter`**。
4. 强制停止 `com.miui.securitycenter`，或重启手机；打开游戏后从屏幕左侧滑出 Game Turbo 侧边栏，进入性能面板。
5. 顶部应出现帧率曲线，CPU / 内存中间显示 36dp 圆形表盘；均衡模式蓝环、性能模式红环。曲线从 Game Turbo 助手启动时就开始采集，打开面板时已经有历史；关闭面板后继续记录，直到游戏助手退出。

> 仅保证文档中记录的 `M2007J17C` / HyperOS `4.0.5.0.XPCCNXM` / `com.miui.securitycenter` `13.6.5-261003.0.1`。其它机型或系统版本资源 ID 可能不同，需自行核对；停用模块即可回滚，不会修改系统分区。

---

- 生成时间：2026-11-23
- 设备：Xiaomi `M2007J17C` / `gauguinpro`
- 系统：HyperOS `4.0.5.0.XPCCNXM`，Android 17 / SDK 37，build `CP2A.260605.016`
- 屏幕：1080 × 2400，120 Hz
- Root：Bootloader 已解锁，Magisk 31.1 + Zygisk + LSPosed 2.2.1
- 模块：`com.xiaomi.fpsgraph`，versionName `1.01`
- LSPosed 作用域：仅 `com.miui.securitycenter`
- 当前代码：**v1.01**（v17 作为 v1.00 基线；包名 `com.xiaomi.fpsgraph`；36dp 圆形细环表盘）
- 当前视觉：**36dp 圆形细环，顶部 6sp `帧率`，中心 12sp 白色数字，无底部 `FPS`**；均衡模式蓝环 `#3A8DFF`，性能模式红环 `#FF5A4A`，随模式切换自动更新。
- 当前 Hook：`DockWindowManagerService.onCreate` 启动 `FrameRateDataService`，`onDestroy` 停止；`PerformancePanelViewNew.onAttachedToWindow` 负责恢复曲线和圆环；`FrameRateViewController.g` 在面板释放时清 Handler 回调、解绑 ServiceConnection，并拦截 `stopService` 保留历史数据。
- v1.01 变更：去掉原表盘和底部 `FPS`，自绘 36dp 圆环；数字移到 CPU / 内存中间并放大到 12sp；新增均衡蓝 / 性能红动态着色，修复首次着色早于面板可见导致颜色不刷新的问题。

> 本目录是给后续 agent 的独立交接包，同时作为开源仓库发布。`README.md` 是主文档；`src/` 是 v1.01 源码；`rebuild.ps1` 可重建。

---

## 0. TL;DR

Game Turbo 的帧率曲线没有被删除，而是新版布局把 `FrameRateView` 设成了 `visibility=gone`、宽高 `0dp`。Game Turbo 没有独立 APK，实际内嵌在系统应用 `com.miui.securitycenter` 中，且使用小米平台签名，不能直接重打包替换。

解决方式是一个只作用于 `com.miui.securitycenter` 的 LSPosed 模块：在 `PerformancePanelViewNew.onAttachedToWindow` 时：

1. 把 `FrameRateView` 设为可见，改高 60dp、上边距 20dp，并移到顶部容器 index 0；
2. 移除原圆形表盘 `ImageView`；
3. 把原来的大号 FPS 数字移到 CPU / 内存行中间，改成 36dp 自绘圆形细环表盘：
   - 圆环填充 `#171A1C`、3px 描边，直径 36dp；
   - 顶部 `帧率` 6sp `#9AA0A6`；
   - 中心数字 12sp、白色、`sans-serif-medium`，`includeFontPadding=false`；
   - 不再保留底部 `FPS` 字样。
4. 新增 `RingTint`：通过模式按钮文字颜色判断当前模式，均衡蓝 `#3A8DFF`、性能红 `#FF5A4A`，每次可见轮询重建背景，确保切换模式后立即刷新。
5. 调用 `setRenderEnabled(true)`（默认已开启，冗余保险）。

曲线数据仍在，约 1 秒 1 个点，`MAX_FRAME_RATE_DATA_COUNT=240`。v1.01 改成在 `DockWindowManagerService.onCreate` 时就启动 `FrameRateDataService`，所以面板打开前数据已经在累积；面板打开时直接显示完整历史，关闭面板后服务继续记录，直到 Game Turbo 助手退出。

---

## 1. 最终效果

```text
┌─────────────────────────────────────────────┐
│  60dp 高、20dp 上边距的青色帧率曲线区域       │
│  右侧刻度 90 / 60 / 30，正常青色 #3CEDFF     │
│  异常帧率红色 #FF001F                         │
├─────────────────────────────────────────────┤
│  CPU 49%        ( 帧率 77 )      内存 52%    │
│  ███████░░░     36dp 圆环           ██████░  │
├─────────────────────────────────────────────┤
│  均衡模式（蓝）             性能模式（红）    │
└─────────────────────────────────────────────┘
```

实测 v1.01：

- 曲线：顶部青色曲线，右侧刻度 90 / 60 / 30；从 Game Turbo 助手启动时开始采集，打开面板时已有历史。
- 帧率：36dp 圆形细环，中心 12sp 白色数字，无底部 `FPS`。
- 配色：均衡模式蓝环，性能模式红环；切换后 500ms 内刷新。
- 位置：圆环位于 CPU / 内存中间，整体 `translationY=5dp`。

> v7 曾尝试“圆角半透明 FPS 徽章”，用户认为“还是丑”，已放弃。v8–v13 的重复标签问题已在 v16 修复。

---

## 2. 设备与环境

| 项目 | 值 |
|---|---|
| 型号 | `M2007J17C` |
| 代号 | `gauguinpro` |
| 系统 | HyperOS `4.0.5.0.XPCCNXM` |
| Android | 17 / SDK 37 |
| Build | `CP2A.260605.016` |
| 分辨率 / 刷新率 | 1080 × 2400 / 120 Hz |
| Root | Magisk 31.1 + Zygisk |
| Hook 框架 | LSPosed 2.2.1 |
| ADB | `C:\platform-tools\adb.exe` |
| 设备号 | `bd1a576` |

### Game Turbo 宿主

| 项目 | 值 |
|---|---|
| 包名 | `com.miui.securitycenter` |
| versionName | `13.6.5-261003.0.1` |
| codePath | `/product/priv-app/MIUISecurityCenter/MIUISecurityCenter.apk` |
| 大小 | 66,997,874 B |
| 类型 | system app |
| sharedUserId | `android.uid.system` |
| 签名 | 小米 MIUI 平台签名 |

不能用自己的 debug 签名重打包替换 `/product/priv-app/...`，只能 LSPosed 运行时 Hook（或 RRO，本项目未使用 RRO）。

---

## 3. 根因分析

### 3.1 新版布局把曲线控件藏起来了

关键布局资源：

| 名称 | 资源 ID | 默认文件 |
|---|---|---|
| `game_toolbox_performance_panel_view_new` | `0x7f0e01e0` | `res/cO0.xml` |
| 横屏变体 | 同上 | `res/vN1.xml` |
| sw600dp 横屏变体 | 同上 | `res/Kgp.xml` |
| 旧版 `game_toolbox_performance_panel_view` | `0x7f0e01df` | `res/iwB.xml` |

新版布局中：

| 控件 | ID | 原状态 |
|---|---|---|
| `FrameRateView`（真正画曲线的 View） | `0x7f0b04f1` | `visibility=gone`，宽高 `0dp` |
| 圆形表盘 `ImageView` | `0x7f0b08fb` | 可见 |
| 大号 FPS `TextView` | `0x7f0b0e85` | 可见，居中 |
| 曲线父容器 `FrameLayout` | `0x7f0b04a3` | 顶部区域 |
| CPU / 内存行 `ConstraintLayout` | `0x7f0b082B` | 可见 |
| CPU 列 | `0x7f0b07FF` | 可见 |
| 内存列 | `0x7f0b080A` | 可见 |
| 根 `FrameLayout` | `0x7f0b0A15` | 面板根 |
| 外层 `ConstraintLayout` | `0x7f0b0A14` | 面板外层 |

曲线代码、数据源、绘制逻辑都还在，只是布局把它设为 GONE + 0dp，视觉上只剩表盘和数字。

### 3.2 旧布局还在，但不能直接切

旧布局 `game_toolbox_performance_panel_view`（`0x7f0e01df`，`res/iwB.xml`）仍然存在，`FrameRateView` 可见，尺寸约 `251dp × 54dp`，`innerPadding=6dp`。

但旧布局对应的类 `PerformancePanelView` 已不在 dex 中。直接把布局 ID 切到旧版会在 inflate 时找不到类，导致 `ClassNotFound` / `InflateException`。所以不能走“换布局”这条路。

### 3.3 为什么选择运行时 Hook

| 方案 | 可行性 | 结论 |
|---|---|---|
| 替换系统 APK | 需要小米平台签名，系统分区写入风险高 | 放弃 |
| 直接改布局资源 / RRO | 资源可覆盖，但类与逻辑仍绑定 `PerformancePanelViewNew` | 未采用 |
| 旧布局切换 | 旧类已删除，inflate 会失败 | 不可行 |
| LSPosed Hook `PerformancePanelViewNew` | 类仍在，`FrameRateView` 与 `FrameRateViewController` 仍被持有 | **采用** |

`PerformancePanelViewNew` 仍持有 `FrameRateView` 和 `FrameRateViewController`，因此可以在面板显示时拿到控件引用并改布局参数。

---

## 4. 模块结构

```text
com.xiaomi.fpsgraph
├── Main                    入口，实现 IXposedHookLoadPackage
├── RecorderHook            拉起 / 停止 FrameRateDataService
├── ReleaseHook             拦截 FrameRateViewController.g()，清回调并解绑
├── PanelHook               核心视觉 Hook
└── RingTint                均衡蓝 / 性能红动态着色
```

> v1.00（v17）已删除 `RateHook`：它 hook `FrameRateView.onDraw` 并读字段 `"d"`，实测从未命中，属于无效 Hook 面。

### 4.1 Manifest

`AndroidManifest.xml`：

```xml
<manifest package="com.xiaomi.fpsgraph"
    android:versionCode="1"
    android:versionName="1.01">
    <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="36"/>
    <application android:label="FPS Graph" android:hasCode="true">
        <meta-data android:name="xposedmodule" android:value="true"/>
        <meta-data android:name="xposeddescription"
            android:value="Restore Game Turbo FPS graph"/>
        <meta-data android:name="xposedminversion" android:value="93"/>
    </application>
</manifest>
```

`assets/xposed_init` 内容：

```text
com.xiaomi.fpsgraph.Main
```

### 4.2 Main（v1.01）

`Main.handleLoadPackage` 的逻辑：

1. 只处理 `com.miui.securitycenter`，其他包直接 return。
2. 通过 `XposedHelpers.findClass` 找到 `com.miui.gamebooster.service.DockWindowManagerService`，hook `onCreate` / `onDestroy`：
   - `onCreate` after：`startService(FrameRateDataService)`；
   - `onDestroy` after：`stopService(FrameRateDataService)`。
3. 找到 `com.miui.gamebooster.windowmanager.newbox.newpanel.PerformancePanelViewNew`，hook `onAttachedToWindow`，负责恢复曲线、圆环和模式着色。
4. 找到 `com.miui.gamebooster.framerate.FrameRateViewController`，hook 私有 `g()`（release），在面板关闭时清 Handler 回调、解绑 `ServiceConnection`，并 `setResult(null)` 拦截原方法的 `stopService`，让历史数据保留。

> **v1.01 的坑**：`Main` 里三个 `findClass` 判空曾写成 `if-nez v2, :cond_xxx`，含义是“非空才跳过 Hook”，正好写反，导致三个 Hook 实际一个都没挂上。v1.01 已全部改成 `if-eqz`，并在 `Log.i("FPSGraph", ...)` 里输出加载与 Hook 结果。

**v16 起不再 hook 构造器**。原因：

- 构造函数触发时，`FrameRateView` 可能还是 GONE / 0dp，且布局未完成；
- 某些启动时序下，`PerformancePanelViewNew` 实例在模块加载前就已经 inflate 好，构造器 Hook 会完全错过；
- 构造器和 `onAttachedToWindow` 同时 Hook 会导致同一面板被应用多次，产生重复 `FPS` 标签、`FrameRateView` 被反复 reparent，曲线数据也被重置。

`onAttachedToWindow` 是面板真正显示时必走的回调，能同时解决“错过实例”和“重复应用”两个问题。

关键点：**模块类加载器看不到目标 APK 的类**，所以不能写 `check-cast` 到目标类型；全部通过 `findClass` + `XposedHelpers` 反射访问。`Main` 里只引用 framework 类型和 Xposed API 类型。

### 4.3 PanelHook（v1.01）

`PanelHook.afterHookedMethod` 在 `PerformancePanelViewNew.onAttachedToWindow` 之后执行，`param.thisObject` 是面板实例。

#### 幂等守卫

```java
private static int lastCurve;
```

流程：

1. 找到 `FrameRateView`（ID `0x7f0b04f1`）。
2. 取 `System.identityHashCode(frameRateView)`。
3. `lastCurve == 0`（从未应用）→ 直接应用；否则仅当 `lastCurve` 与该 hash **相等**时才 return（说明是同一个 View 的二次 attach）。
4. 全部应用成功后，把该 hash 写入 `lastCurve`。

这样同一个 `FrameRateView` 只会被应用一次；面板被重建、出现新的 `FrameRateView` 时仍会重新应用。

对应的 smali 判断（`src/PanelHook.smali` 第 28–34 行）：

```smali
sget v2, Lcom/xiaomi/fpsgraph/PanelHook;->lastCurve:I
invoke-static {v1}, Ljava/lang/System;->identityHashCode(Ljava/lang/Object;)I
move-result v3
if-eqz v2, :first_apply    # lastCurve==0 → 首次应用
if-eq v2, v3, :done        # 同一个 View → 跳过
```

> **v16 的坑**：这里曾误写成 `if-ne v2, v3, :done`。`if-ne` 是「不相等就跳」，于是 `lastCurve≠0` 之后任何**新的** `FrameRateView` 都会被跳过，表现为「只有 force-stop 后的第一次打开面板生效，关掉再开就没有曲线、没有读数」。改回 `if-eq` 即修复。

> v7–v13 曾尝试 `View.getTag()` 做守卫，但目标应用/其他代码会覆盖 `FrameRateView` 的 tag，导致守卫失效。`identityHashCode` 静态 int 更可靠。

#### 步骤 1：恢复曲线

- `findViewById(0x7f0b04f1)` 找到 `FrameRateView`。
- `setVisibility(VISIBLE)`。
- 取父容器（顶部 `FrameLayout`，ID `0x7f0b04a3`）。
- 把 `FrameRateView` 的 `LayoutParams` 改为：
  - `width = MATCH_PARENT`
  - `height = 60dp`（按 `displayMetrics.density` 换算）
  - `topMargin = 20dp`
- 从父容器移除后重新 `addView(view, 0, params)`，确保它在顶部区域最前面，不被表盘 / 文字盖住。

#### 步骤 2：移除原圆形表盘

- `findViewById(0x7f0b08fb)` 找到原表盘 `ImageView`，从父容器 `removeView`，不再显示。

#### 步骤 3：把大号帧率数字改成 36dp 圆形表盘

1. 找到大号 `TextView`（ID `0x7f0b0e85`）和 CPU / 内存行 `ConstraintLayout`（ID `0x7f0b082B`）。
2. 把 `TextView` 从原父容器移除，后面复用它作为中心数字。
3. 创建外层透明 `FrameLayout`，克隆 CPU 列（ID `0x7f0b07FF`）的 `LayoutParams`，设为 `MATCH_PARENT × MATCH_PARENT`，`gravity=0x11`，`translationY=5dp`。
4. 创建 36dp 内层 `FrameLayout`，背景为 `GradientDrawable`：
   - `OVAL`，填充 `#171A1C`，描边 `3px`；
   - 默认红色 `#FF5A4A`，由 `RingTint` 按模式改成蓝色 `#3A8DFF` 或红色 `#FF5A4A`。
5. 复用原 `TextView` 作为中心数字：
   - `12sp`，白色 `#FFFFFFFF`，`sans-serif-medium`，`includeFontPadding=false`；
   - `gravity=0x11`，不再保留底部 `FPS`。
6. 新建顶部小标签 `TextView`：`帧率`，`6sp`，`#9AA0A6`，`gravity=0x31`，`topMargin=3dp`。
7. 内层 36dp `FrameLayout` 居中放入外层；外层放入 CPU / 内存行。
8. 外层 `setClickable(false)`、`setFocusable(false)`，避免遮挡 CPU / 内存行的交互。

模式着色由 `RingTint` 完成：在 `PanelHook` 中查找均衡按钮 `0x7f0b0ae3`、性能按钮 `0x7f0b0ae4` 和 `RadioGroup 0x7f0b0b20`，注册点击 / 选中监听，并以 500ms 轮询兜底。切换模式后重建 `GradientDrawable` 并 `setBackground`，避免只改旧 drawable 不刷新。

#### 步骤 4：开启渲染并写守卫

- `XposedHelpers.callMethod(frameRateView, "setRenderEnabled", true)`。
- 成功后把 `identityHashCode` 写入 `lastCurve`。

`FrameRateView` 默认 `renderEnabled=true`，这一步是冗余保险。

### 4.4 RateHook（v1.00 已移除）

早期版本还有一个 `RateHook`，hook `FrameRateView.onDraw`、读字段 `"d"` 打印数据点数量用于诊断。日志里始终没有命中（大概率是字段名混淆后不匹配），对功能无贡献，v17 已删除源码并在 `Main` 中移除对应 hook。v1.01 只保留 `DockWindowManagerService`、`PerformancePanelViewNew`、`FrameRateViewController` 三个 Hook 面。

---

## 5. 当前视觉参数（v1.01）

| 元素 | 参数 |
|---|---|
| 曲线 `FrameRateView` | 可见，`MATCH_PARENT × 60dp`，`topMargin=20dp`，父容器 index 0 |
| 曲线父容器 | 顶部 `FrameLayout`，ID `0x7f0b04a3` |
| 原圆形表盘 `ImageView` | 已从父容器移除 |
| 表盘外层 | 透明 `FrameLayout`，`MATCH_PARENT × MATCH_PARENT`，克隆 CPU 列的 `ConstraintLayout.LayoutParams`，`gravity=0x11`，`translationY=5dp` |
| 表盘 | 36dp `GradientDrawable`，`OVAL`，填充 `#171A1C`，3px 描边 |
| 圆环颜色 | 均衡模式 `#3A8DFF`，性能模式 `#FF5A4A` |
| 顶部标签 | `帧率` 6sp `#9AA0A6`，`gravity=0x31`，`topMargin=3dp` |
| 中心数字 | 12sp 白色 `#FFFFFFFF`，`sans-serif-medium`，`includeFontPadding=false`，居中 |
| 底部 `FPS` | 无 |
| 模式监听 | `RingTint` 注册两个模式按钮的 `OnClickListener` 和 `RadioGroup.OnCheckedChangeListener`，另按 500ms 轮询兜底 |

### 旧版与 v1.01 的差异

| 版本 | 做法 | 结果 |
|---|---|---|
| v6 | 大号 `TextView` 直接塞进 CPU / 内存行，`18sp` 居中 | 数字落在 CPU / 内存中间，但用户认为“太丑” |
| v7 | 外层 FrameLayout + 竖向徽章，`FPS` 标签 + 16sp 数字 + 青色圆角底 | 用户认为“还是丑”，否决 |
| v8–v13 | 水平内联，但构造器 + onAttached 重复应用，出现两个 `FPS` 标签、曲线被重置 | 失败 / 中间版本 |
| v15 | attach-only + 静态守卫，水平内联 `81 FPS`，数字 18sp | 单个标签，视觉可行 |
| v16 | 数字降到 16sp，`FPS` 8sp、`#99FFFFFF`，底对齐，保留 5dp 下移 | 视觉可行；守卫条件 `if-ne` 写反，二次打开失效 |
| **v1.00（v17）** | 守卫改回 `if-eq`、`Main` 补 null 判断、删除 `RateHook` | 已发布基线 |
| **v1.01** | 去掉原表盘和底部 `FPS`；36dp 圆环 + 12sp 数字；均衡蓝 / 性能红 | **当前版本，已安装并实测** |

---

## 6. 关键坑与经验

### 6.1 不能直接引用目标类

早期版本在 `PanelHook` 里写：

```java
PerformancePanelViewNew panel = (PerformancePanelViewNew) param.thisObject;
FrameRateView view = panel.findViewById(...);
```

运行时报 `NoClassDefFoundError`，因为模块的类加载器看不到目标 APK 的类。

**解决**：模块里只引用 framework 类型（`View`、`ViewGroup`、`TextView`、`FrameLayout`、`LinearLayout`、`Typeface` 等）；目标类只通过 `findViewById` 和 `XposedHelpers` 反射访问。

### 6.2 ConstraintLayout 被 R8 混淆，不能按字段名设约束

尝试：

```java
XposedHelpers.setIntField(lp, "startToStart", cpuId);
```

会报：

```text
java.lang.NoSuchFieldError: androidx.constraintlayout.widget.ConstraintLayout$b#startToStart
```

`ConstraintLayout` 内部类显示为 `$b`，字段名被混淆，不存在这些公开字段。

**可靠做法**：

```java
Object cpuLp = cpuView.getLayoutParams();
Object newLp = XposedHelpers.newInstance(cpuLp.getClass(), cpuLp);
XposedHelpers.setIntField(newLp, "width", ViewGroup.LayoutParams.MATCH_PARENT);
XposedHelpers.setIntField(newLp, "height", ViewGroup.LayoutParams.MATCH_PARENT);
```

或者：

```java
ViewGroup.LayoutParams newLp = (ViewGroup.LayoutParams)
    XposedHelpers.newInstance(cpuLp.getClass(), cpuLp);
newLp.width = ViewGroup.LayoutParams.MATCH_PARENT;
newLp.height = ViewGroup.LayoutParams.MATCH_PARENT;
```

**不要**用 `generateDefaultLayoutParams()`：它返回的对象字段名同样被混淆，不能用来设置约束。

### 6.3 旧布局不能直接换

旧布局 `iwB.xml` 的 `FrameRateView` 是可见的 `251 × 54dp`，但旧类 `PerformancePanelView` 已不在 dex。直接切布局会在 inflate 时找不到类。必须继续使用 `PerformancePanelViewNew` + Hook。

### 6.4 构造器 Hook 会错过预加载的面板

v11 实测出现过：`Main` 日志显示 hook 注册成功，但面板显示的是原版表盘，日志里没有 `panel enter`。原因是 `:ui` 进程启动时 `PerformancePanelViewNew` 已经在模块加载前 inflate 好，构造器 Hook 来不及。

**解决**：改 hook `onAttachedToWindow`。它是面板真正 attach 时必走的回调，即使实例提前创建也能命中。

### 6.5 重复 Hook 会产生两个 `FPS` 标签

构造器 + onAttached 同时 hook 时，同一个面板会执行多次：

- 第一次创建徽章 A，把数字放进 A；
- 第二次把数字从 A 移出，创建徽章 B；
- 徽章 A 只剩一个 `FPS` 标签，徽章 B 有数字 + 标签；
- 视觉上就是两个 `FPS`，一个在数字上方、一个在下方。

同时 `FrameRateView` 被反复 remove/add，曲线数据会被重置，表现为顶部只有一小段。

**解决**：

1. 只 hook `onAttachedToWindow`；
2. 用静态 `lastCurve`（`identityHashCode`）守卫，同一个 `FrameRateView` 只应用一次。

`View.getTag()` 不可靠：目标代码会覆盖 tag，导致守卫失效。

### 6.6 本机 Smali 工具链的寄存器限制

本机使用的 smali 工具链在把 `PanelHook.afterHookedMethod` 写成 `.registers 24` 时，汇编直接报：

```text
Invalid register: v23. Must be between v0 and v15, inclusive.
```

当前版本压缩到 `.registers 16`，只使用 `v0–v15`。如果后续加逻辑，优先复用寄存器，不要盲目调大 `.registers`；或者换一套正常的 smali / baksmali 工具链。

### 6.7 曲线数据从 Game Turbo 助手启动时开始累积

`FrameRateView` 的 `MAX_FRAME_RATE_DATA_COUNT=240`，数据点约 1 秒 1 个。v1.01 把 `FrameRateDataService` 的启动提前到 `DockWindowManagerService.onCreate`，所以进入游戏、Game Turbo 助手服务创建后就开始采样；打开性能面板时曲线已经有一段历史，不会从空白开始。面板关闭时 `ReleaseHook` 只清回调、解绑，不停止服务，因此再次打开面板仍能接上历史。

如果看到曲线只有左侧一小段，说明 `DockWindowManagerService.onCreate` 的 `startService` 没执行，或 `FrameRateDataService` 被系统杀掉；优先检查 LSPosed 作用域是否只勾选 `com.miui.securitycenter`、模块是否启用，以及 `logcat -s FPSGraph` 是否打出 `FrameRateDataService startService`。

### 6.8 `setRenderEnabled` 不是关键

`FrameRateView` 默认 `renderEnabled=true`；Hook 里调 `setRenderEnabled(true)` 只是保险。真正关键的是 `visibility`、宽高、父容器和布局位置。

### 6.9 移走原表盘后不要留下空白

原表盘 `ImageView` 从顶部 `FrameLayout` 移除后，曲线 `FrameRateView` 重新 `addView` 到 index 0，才能占满顶部区域。否则可能出现顶部空白或曲线被原表盘占位。

---

## 7. 构建与部署

### 7.1 目录与工具

| 用途 | 路径 |
|---|---|
| 模块工作目录 | `C:\Users\Dohn\AppData\Local\Temp\fpsgraph` |
| Smali 源码 | `...\FPS帧率图改造\src\`（`Main` / `PanelHook` / `RingTint`） |
| 汇编后 dex | `...\fpsgraph\classes_new.dex` |
| 基础 APK | `...\fpsgraph\unsigned.apk`（含 manifest、资源、assets） |
| 重打包脚本 | `...\fpsgraph\repack.py` |
| 自建签名 | `...\fpsgraph\debug.keystore`（storepass/keypass 均为 `android`，alias `androiddebugkey`） |
| aapt2 / zipalign / apksigner | `C:\Users\Dohn\AppData\Local\Temp\bt35\android-15\` |
| smali 工具链 | `C:\Users\Dohn\AppData\Local\Temp\smali\` |
| framework-res.apk | `C:\Users\Dohn\AppData\Local\Temp\framework-res.apk` |
| Java 8 | `C:\Program Files (x86)\Common Files\Oracle\Java\java8path\java.exe` |
| ADB | `C:\platform-tools\adb.exe` |

> `smali.jar` 没有 `Main-Class`，必须用 `org.jf.smali.Main`，并把 `dexlib2/guava/antlr/jcommander/util` 一起放进 classpath。

### 7.2 汇编

```powershell
$java = "C:\Program Files (x86)\Common Files\Oracle\Java\java8path\java.exe"
$smali = "C:\Users\Dohn\AppData\Local\Temp\smali"
$cp = "$smali\smali.jar;$smali\dexlib2.jar;$smali\guava.jar;$smali\antlr.jar;$smali\jcommander.jar;$smali\util.jar"
$out = "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\classes_new.dex"

& $java -cp $cp org.jf.smali.Main assemble -a 28 -o $out `
  "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\smali"
```

### 7.3 替换 dex、对齐、签名

```powershell
python "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\repack.py"

& "C:\Users\Dohn\AppData\Local\Temp\bt35\android-15\zipalign.exe" `
  -f 4 `
  "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\unsigned2.apk" `
  "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\aligned.apk"

& "C:\Users\Dohn\AppData\Local\Temp\bt35\android-15\apksigner.bat" sign `
  --ks "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\debug.keystore" `
  --ks-pass pass:android `
  --key-pass pass:android `
  --ks-key-alias androiddebugkey `
  --out "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\fpsgraph_v17.apk" `
  "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\aligned.apk"
```

`repack.py` 会把 `classes_new.dex` 写进 `unsigned.apk` 的 `classes.dex` 条目，输出 `unsigned2.apk`。

### 7.4 安装与启用

```powershell
& "C:\platform-tools\adb.exe" install -r `
  "C:\Users\Dohn\AppData\Local\Temp\fpsgraph\fpsgraph_v17.apk"

& "C:\platform-tools\adb.exe" shell am force-stop com.miui.securitycenter
```

然后在 LSPosed Manager 中确认：

- 模块 `com.xiaomi.fpsgraph` 已启用；
- 作用域勾选 `com.miui.securitycenter`；
- 必要时重启手机，或至少强制停止 `com.miui.securitycenter` 后重新打开游戏。

### 7.5 一键重建脚本

本目录的 `rebuild.ps1` 已封装：

```powershell
# 只构建并签名
.\rebuild.ps1

# 构建、安装，并在安装后删除本地安装包
.\rebuild.ps1 -Install
```

依赖本机 smali 工具链、Build Tools、Java 8、ADB 和 `unsigned.apk`。路径变化时改脚本顶部变量。

---

## 8. 测试方法

### 8.1 触发 Game Turbo

测试游戏：`com.game.silksong`（空洞骑士：丝之歌）。启动后从屏幕左边缘滑出 Game Turbo 侧边栏。

```powershell
$adb = "C:\platform-tools\adb.exe"

& $adb shell "am force-stop com.miui.securitycenter"
& $adb shell "input keyevent 3"
& $adb shell "monkey -p com.game.silksong -c android.intent.category.LAUNCHER 1"
Start-Sleep -Seconds 10
& $adb shell "input swipe 2 70 900 70 600"
Start-Sleep -Seconds 12

& $adb shell "su -c 'screencap -p /data/local/tmp/s.png'"
& $adb pull /data/local/tmp/s.png "C:\Users\Dohn\AppData\Local\Temp\s_v17.png"
& $adb shell "su -c 'rm /data/local/tmp/s.png'"
```

`com.tencent.tmgp.sgame`（王者荣耀）也可触发；王者荣耀曾用：

```text
input swipe 5 950 720 950 350
```

### 8.2 验证点

1. 顶部出现青色曲线区域，高度约 60dp，右侧刻度 120 / 90 / 60。
2. 圆形表盘消失。
3. CPU / 内存行中间只出现 **一个 36dp 圆形表盘**，中心 12sp 数字，没有底部 `FPS`。
4. 数字随着游戏帧率变化。
5. 均衡模式圆环蓝色，性能模式圆环红色；切换后 500ms 内更新。
6. 进游戏后先不要滑侧边栏，等 30 秒再打开性能面板；曲线应已有历史，而不是只剩左侧 1–2 个点。
7. LSPosed / logcat 中应出现：

```text
FPSGraph: loaded in com.miui.securitycenter
FPSGraph: DockWindowManagerService hooked
FPSGraph: PerformancePanelViewNew hooked
FPSGraph: FrameRateViewController hooked
FPSGraph: FrameRateDataService startService
FPSGraph: release() intercepted
```

8. 如出现异常，抓日志：

```powershell
& $adb shell 'su -c "grep -h -A10 Exception /data/adb/lspd/log/modules_*.log | tail -30"'
```

> `NoSuchFieldError: ConstraintLayout$b#startToStart` 是 v5/v6 旧代码的典型异常。v17 不应再出现；如果出现，说明安装的 APK 不是最新 dex，或 LSPosed 仍加载旧模块。

### 8.3 实测记录

- v4：首次把曲线区域改为 60dp 高、下移 20dp、隐藏大数字后，顶部出现青色曲线和 90 / 60 / 30 刻度。
- 等待约 60 秒后曲线铺满整个宽度，确认数据累积正常。
- v5：尝试用 `ConstraintLayout` 字段名设置约束，`NoSuchFieldError` 失败。
- v6：克隆 CPU 列 LayoutParams，成功把数字 93 放到 CPU 48% 与内存 55% 中间，但用户认为“太丑”。
- v7：改成 `FPS` 徽章，16sp，整体下移 5dp；用户认为“还是丑”，否决。
- v8–v13：水平内联，但重复应用，出现两个 `FPS`、曲线被重置；失败。
- v15：attach-only + 静态守卫，水平内联 `81 FPS`，18sp；单个标签，曲线正常。
- v16：数字降到 16sp，`FPS` 8sp `#99FFFFFF`，底对齐；实测 `82 FPS`、CPU 49%、内存 59%，曲线正常累积。
- v17：修正守卫 `if-ne`→`if-eq`、`Main.findClass` 判空、删除 `RateHook`；实测 `84 FPS`、CPU 49%、内存 60%，关闭侧边栏后重新打开仍正常应用（日志出现两次 `panel apply`，界面上只有一个读数）。
- v1.01：去掉原表盘和底部 `FPS`，改成 36dp 圆形细环 + 12sp 中心数字；均衡模式实测蓝环 `77`，性能模式红环 `79`，切换后自动刷新。
- v1.01 生命周期修复：`Main` 三个 `findClass` 判空从 `if-nez` 改成 `if-eqz`（否则 Hook 全部被跳过）；LSPosed 里启用模块并只勾选 `com.miui.securitycenter`。实测进游戏后不滑侧边栏，`FrameRateDataService` 已按约 1.2 秒一次输出 `maxFps/limitedFps`；等 30 秒再开面板，曲线已有完整历史。关闭面板后 `securitycenter:ui` 回到 0% CPU，再次打开仍能接上历史。
- v1.02 实验（三个方向，全部留档）：
  1. **拦截 `FrameRateViewController.g()`（阻止 release）**：关面板后 `FrameRateDataService` 保持 8，重开曲线完整重现关闭前的形状 → 历史接上；但每个 `ServiceConnection` 永不释放，服务每秒向所有历史连接推送，**越开越卡，最终卡爆**，此路不可用。
  2. **在 `onDetachedFromWindow` 读 `FrameRateView.d`**：`cached points=0`。`onDraw` 只读 `h/k/m/l/g`，`d` 只是内部暂存，不是绘制数据源。
  3. **Hook 数据入口 `FrameRateView.g([I)` 与 AIDL 回调 `FrameRateViewController$callback$1.V3/f5`**：`replayed points=0`，两个入口实机均未被调用；帧率点由 `FrameRateView` 内部（`i` / `kp/q`）自取，不在 AIDL 链上。
  结论：想重现旧版“关掉再开接上历史”，仍需定位 `FrameRateView` 内部取数路径；现有实现保持“首次打开有曲线、重开为空”，与 v1.01 行为一致且**不增加任何常驻开销**。
  量化：面板开着 144 帧，均隔 33.47ms（29.9fps）、p95 41.36ms、jank 0；关闭后面板进程 CPU 0.0%。

---

## 9. 回滚

模块没有修改系统分区，回滚很简单：

1. LSPosed Manager 中停用 `com.xiaomi.fpsgraph`；
2. 强制停止 `com.miui.securitycenter`；
3. 重新打开游戏 / 侧边栏，面板恢复原状；
4. 如需彻底移除：

```powershell
& "C:\platform-tools\adb.exe" uninstall com.xiaomi.fpsgraph
```

不需要刷机，不需要还原 `/product`。

---

## 10. 已知问题与后续建议

### 10.1 当前限制

| 项目 | 说明 |
|---|---|
| 横屏 / 平板布局 | 只按默认 `cO0.xml` 的控件 ID 做运行时查找；`vN1.xml`、`Kgp.xml` 未单独验证。ID 大概率一致，但未实测。 |
| 三位数 FPS | 内层是 `WRAP_CONTENT`，理论上可容纳 100–120；未专门截三位数验证。 |
| 曲线数据 | 只能显示 `FrameRateView` 已有数据；没有做平均帧率 / 1% low 等额外统计。 |
| ~~`RateHook`~~ | v17 已删除；历史上是从未命中的诊断 Hook。 |
| 模块健壮性 | `Main.findClass` 已对每个类判空，找不到时只跳过对应 Hook；但 `Main` 仍未包整体 try/catch，宿主大改后需看 `logcat -s FPSGraph` 是否打出三行 hooked。 |
| 布局假设 | `PanelHook` 假设 `FrameRateView` 的父容器是 `FrameLayout`、CPU 列存在；系统大版本更新后需要重新核对 ID。 |
| 静态守卫 | `lastCurve` 是单进程单 int；如果一个进程同时存在多个面板，只有最后应用的那个会被记住。当前使用场景只有一个可见面板，够用。 |

### 10.2 后续可做

1. ~~清理 `RateHook`~~：v17 已完成，`Main` 不再挂 `onDraw`。
2. ~~加空判断~~：v17 已对 `findClass` 结果判空；`findViewById` 的判空更早就已存在。
3. **适配横屏**：在 `vN1.xml` / `Kgp.xml` 下实测，必要时按 `orientation` 调整曲线高度 / 文字位置。
4. **视觉微调**：36dp 尺寸、12sp 数字、`translationY` 集中在 `PanelHook.smali`；蓝 / 红颜色在 `RingTint.smali`。当前是 36dp 圆形细环，中心数字，无底部 `FPS`。
5. **数据增强**：若要显示平均 FPS / 1% low，需要深入 `FrameRateViewController` 和 `FrameRateDataService`，当前未做。

---

## 11. 版本演进

| 版本 | 改动 | 结果 |
|---|---|---|
| v1 | 直接 `check-cast` 到 `PerformancePanelViewNew` / `FrameRateView` | `NoClassDefFoundError`，失败 |
| v2 | 全部改 framework 类型 + 反射 | 模块可加载 |
| v3 | `FrameRateView` 设可见、改尺寸 | 曲线出现 |
| v4 | 曲线 60dp 高、topMargin 20dp、隐藏表盘 / 大数字 | 曲线完整，等待 60 秒铺满 |
| v5 | 用 `ConstraintLayout` 字段名把数字移入 CPU / 内存行 | `NoSuchFieldError: startToStart`，失败 |
| v6 | 克隆 CPU 列 LayoutParams，数字 18sp 居中 | 成功，但视觉被否决 |
| v7 | 外层 FrameLayout + 竖向 `FPS` 徽章，16sp，下移 5dp | 用户认为“还是丑”，否决 |
| v8–v13 | 水平内联，但构造器 + onAttached 重复应用 | 两个 `FPS` 标签、曲线重置，失败 |
| v15 | 改 attach-only + 静态守卫，水平内联 18sp | 单个标签，曲线正常 |
| v16 | 数字 16sp、`FPS` 8sp、底对齐、5dp 下移 | 视觉定稿；但守卫 `if-ne` 写反，二次打开面板失效 |
| **v1.00（v17）** | 守卫 `if-eq`、`findClass` 判空、删除 `RateHook` | 已发布基线 |
| v1.01 | 36dp 圆形细环、12sp 数字、无底部 `FPS`、均衡蓝 / 性能红；`Main` 判空方向修复；采集服务提前到 Game Turbo 助手启动 | 视觉定稿，已安装并实测 |
| **v1.02** | 砍掉 v1.01 的采集服务/释放拦截，只保留 `onAttachedToWindow` + `getCoordinatorSizeX`；新增 `DataCache` + `CallbackHook`（挂在 `FrameRateViewController$callback$1.V3/f5`）做历史回灌，实机未命中（`replayed points=0`），当前等价于无回灌 | **当前版本（`fpsgraph_v1.02.apk`，md5 `54a5f33f…`），已安装并实测** |

---

## 12. 关键资源 ID 速查

| 名称 | ID |
|---|---|
| 新版面板布局 `game_toolbox_performance_panel_view_new` | `0x7f0e01e0` |
| 旧版面板布局 `game_toolbox_performance_panel_view` | `0x7f0e01df` |
| `FrameRateView` | `0x7f0b04f1` |
| 曲线父容器 `FrameLayout` | `0x7f0b04a3` |
| 圆形表盘 `ImageView` | `0x7f0b08fb` |
| 大号 FPS `TextView` | `0x7f0b0e85` |
| CPU / 内存行 `ConstraintLayout` | `0x7f0b082B` |
| CPU 列 | `0x7f0b07FF` |
| 内存列 | `0x7f0b080A` |
| 根 `FrameLayout` | `0x7f0b0A15` |
| 外层 `ConstraintLayout` | `0x7f0b0A14` |

---

## 13. 文件索引

### 本目录（桌面交接包）

| 文件 | 说明 |
|---|---|
| `README.md` | 本文档 |
| `src/Main.smali` | 模块入口（v1.02：只挂 `PerformancePanelViewNew.onAttachedToWindow`、`FrameRateView.getCoordinatorSizeX`、回调层探针） |
| `src/PanelHook.smali` | 核心视觉 Hook（v1.02：恢复曲线、36dp 圆形表盘、模式监听） |
| `src/DataCache.smali` | 曲线点累积与回灌（v1.02 实验，实机未命中） |
| `src/CallbackHook.smali` | AIDL 回调层探针（`V3/f5`，v1.02 实验） |
| `src/RingTint.smali` | 均衡蓝 / 性能红动态着色 |
| `.gitignore` | 排除签名 APK / 中间产物 |
| `LICENSE` | MIT |
| `AndroidManifest.xml` | 模块 manifest 参考 |
| `xposed_init.txt` | 入口类名 |
| `unsigned.apk` | 含 manifest / 资源 / assets 的基础 APK |
| `classes.dex` / `unsigned2.apk` / `aligned.apk` | 最近一次重建的中间产物，可删，可用 `rebuild.ps1` 重新生成 |
| `debug.keystore` | 调试签名 |
| `rebuild.ps1` | 重建脚本 |

### 临时工作目录（可能被系统清理）

| 路径 | 说明 |
|---|---|
| `C:\Users\Dohn\AppData\Local\Temp\fpsgraph\` | 模块构建目录 |
| `...\fpsgraph\classes_new.dex` | v17 汇编产物 |
| `...\fpsgraph\fpsgraph_v17.apk` | v17 签名 APK（安装后按习惯删除） |
| `C:\Users\Dohn\AppData\Local\Temp\MIUISecurityCenter.apk` | 从设备拉取的原包，66,997,874 B |
| `C:\Users\Dohn\AppData\Local\Temp\sec_smali\` / `sec_smali3\` | SecurityCenter dex 的 baksmali 输出 |
| `...\layout_res_cO0.xml.xml` | 新版布局反编译 |
| `...\layout_game_toolbox_performance_panel_view_res_iwB.xml.xml` | 旧版布局反编译 |
| `C:\Users\Dohn\AppData\Local\Temp\modules_config.db` | LSPosed 配置副本（含 `-wal`/`-shm`） |

### 关键反编译文件

- `sec_smali\...\FrameRateView.smali`：曲线绘制、`MAX_FRAME_RATE_DATA_COUNT=240`、正常青色 / 异常红色。
- `sec_smali\...\FrameRateViewController.smali`：数据绑定。
- `sec_smali3\...\PerformancePanelViewNew.smali`：面板类，持有 `FrameRateView` 和 `FrameRateViewController`；含 `onAttachedToWindow`。

---

## 14. 给下一个 Agent 的最短路径

1. 先读 `src/PanelHook.smali`，重点看：
   - `lastCurve` 静态守卫；
   - `60dp`、`20dp`；
   - 数字 `0x41800000`（16sp）；
   - `FPS` 标签 `0x41000000`（8sp）、`0x99ffffff`；
   - `translationY` 的 `0x40a00000`（5dp）。
2. 要改视觉，只改这些常量；不要动 `ConstraintLayout` 字段名，继续用“克隆 CPU LayoutParams”的方式。
3. 改完运行：

```powershell
cd "C:\Users\Dohn\Desktop\FPS帧率图改造"
.\rebuild.ps1 -Install
```

4. 强制停止 `com.miui.securitycenter`，启动 `com.game.silksong`，从左边缘滑出侧边栏。
5. 进游戏后先等 30 秒再滑出侧边栏；验证打开面板时曲线已有历史，而不是只有左侧一小段。
6. 截图确认后立即删除临时截图；安装包已在脚本安装后删除；不要用 `uiautomator dump` 抓 UI。
7. 如果改动了行为 / 参数，回来更新本 README 的“当前视觉参数”和“版本演进”。

### 用户偏好（与本任务相关）

- 安装 APK 后立即删除安装包，不在本地留存。
- 临时截图用完立即删除。
- 删除类操作先列清单确认，不要凭“全部清理”直接删。
- 不接受 `uiautomator dump` 抓 UI；需要 UI 信息用 `dumpsys` / 截图 / 布局反编译。
- 小事可全权决定，但删除和系统级高风险操作要谨慎。

---

## 15. 结论

- 根因：新版布局把 `FrameRateView` 设为 GONE + 0dp，曲线代码仍在。
- 方案：LSPosed Hook `PerformancePanelViewNew.onAttachedToWindow`，运行时恢复曲线并重排数字。
- 当前：v1.02 已安装（`fpsgraph_v1.02.apk`），曲线、36dp 圆环、均衡蓝 / 性能红均正常；关掉侧边栏再打开**曲线为空**（历史未回灌，见 v1.02 实验结论）；面板开着实测 0 jank，关闭后进程 CPU 0.0%。
- 关键修复：`Main` 三个 `findClass` 判空方向由 `if-nez` 改为 `if-eqz`，否则 Hook 全部被跳过；`ReleaseHook` 清 Handler 回调后再解绑并拦截 `stopService`，避免面板关闭后残留回调；onAttached-only + `identityHashCode` 守卫解决重复贴标签、二次打开失效。
- 回滚：停用模块 / 卸载即可，系统分区未改动。
- 可复现：源码、基础 APK、签名、构建脚本均在本目录；按 `rebuild.ps1` 可重建。
