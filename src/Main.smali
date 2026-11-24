.class public Lcom/xiaomi/fpsgraph/Main;
.super Ljava/lang/Object;

# interfaces
.implements Lde/robv/android/xposed/IXposedHookLoadPackage;


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public handleLoadPackage(Lde/robv/android/xposed/callbacks/XC_LoadPackage$LoadPackageParam;)V
    .registers 12

    iget-object v0, p1, Lde/robv/android/xposed/callbacks/XC_LoadPackage$LoadPackageParam;->packageName:Ljava/lang/String;

    const-string v1, "com.miui.securitycenter"

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_pkg

    return-void

    :cond_pkg
    const-string v4, "FPSGraph"
    const-string v5, "loaded in com.miui.securitycenter"
    invoke-static {v4, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    iget-object v1, p1, Lde/robv/android/xposed/callbacks/XC_LoadPackage$LoadPackageParam;->classLoader:Ljava/lang/ClassLoader;

    :cond_panel
    const-string v0, "com.miui.gamebooster.windowmanager.newbox.newpanel.PerformancePanelViewNew"

    invoke-static {v0, v1}, Lde/robv/android/xposed/XposedHelpers;->findClass(Ljava/lang/String;Ljava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v2

    if-eqz v2, :end

    new-instance v3, Lcom/xiaomi/fpsgraph/PanelHook;

    invoke-direct {v3}, Lcom/xiaomi/fpsgraph/PanelHook;-><init>()V

    const-string v0, "onAttachedToWindow"

    invoke-static {v2, v0, v3}, Lde/robv/android/xposed/XposedBridge;->hookAllMethods(Ljava/lang/Class;Ljava/lang/String;Lde/robv/android/xposed/XC_MethodHook;)Ljava/util/Set;

    const-string v4, "FPSGraph"
    const-string v5, "PerformancePanelViewNew hooked"
    invoke-static {v4, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    # 曲线视图：只保留自适应铺满，历史由系统服务自行保留
    const-string v0, "com.miui.gamebooster.framerate.FrameRateView"

    invoke-static {v0, v1}, Lde/robv/android/xposed/XposedHelpers;->findClass(Ljava/lang/String;Ljava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v2

    if-eqz v2, :end

    # 让曲线在点数不足时也能横向铺满，避免刚打开只看到左端一个点
    new-instance v3, Lcom/xiaomi/fpsgraph/GraphScaleHook;

    invoke-direct {v3}, Lcom/xiaomi/fpsgraph/GraphScaleHook;-><init>()V

    const-string v0, "getCoordinatorSizeX"

    invoke-static {v2, v0, v3}, Lde/robv/android/xposed/XposedBridge;->hookAllMethods(Ljava/lang/Class;Ljava/lang/String;Lde/robv/android/xposed/XC_MethodHook;)Ljava/util/Set;

    # AIDL 回调层：帧率数据真正进入 Java 的地方
    const-string v0, "com.miui.gamebooster.framerate.FrameRateViewController$callback$1"

    invoke-static {v0, v1}, Lde/robv/android/xposed/XposedHelpers;->findClass(Ljava/lang/String;Ljava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v2

    if-eqz v2, :end

    new-instance v3, Lcom/xiaomi/fpsgraph/CallbackHook;

    invoke-direct {v3}, Lcom/xiaomi/fpsgraph/CallbackHook;-><init>()V

    const-string v0, "V3"

    invoke-static {v2, v0, v3}, Lde/robv/android/xposed/XposedBridge;->hookAllMethods(Ljava/lang/Class;Ljava/lang/String;Lde/robv/android/xposed/XC_MethodHook;)Ljava/util/Set;

    const-string v0, "f5"

    invoke-static {v2, v0, v3}, Lde/robv/android/xposed/XposedBridge;->hookAllMethods(Ljava/lang/Class;Ljava/lang/String;Lde/robv/android/xposed/XC_MethodHook;)Ljava/util/Set;

    :end
    return-void
.end method
