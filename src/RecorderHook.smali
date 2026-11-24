.class public Lcom/xiaomi/fpsgraph/RecorderHook;
.super Lde/robv/android/xposed/XC_MethodHook;


# instance fields
.field private final a:I


# direct methods
.method public constructor <init>(I)V
    .registers 2

    invoke-direct {p0}, Lde/robv/android/xposed/XC_MethodHook;-><init>()V

    iput p1, p0, Lcom/xiaomi/fpsgraph/RecorderHook;->a:I

    return-void
.end method


# virtual methods
.method protected afterHookedMethod(Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;)V
    .registers 7

    :try_start_0
    iget-object v0, p1, Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;->thisObject:Ljava/lang/Object;

    check-cast v0, Landroid/content/Context;

    new-instance v1, Landroid/content/Intent;

    invoke-direct {v1}, Landroid/content/Intent;-><init>()V

    const-string v2, "com.miui.securitycenter"

    const-string v3, "com.miui.gamebooster.gbservices.FrameRateDataService"

    invoke-virtual {v1, v2, v3}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v1

    iget v2, p0, Lcom/xiaomi/fpsgraph/RecorderHook;->a:I

    if-nez v2, :cond_stop

    invoke-virtual {v0, v1}, Landroid/content/Context;->startService(Landroid/content/Intent;)Landroid/content/ComponentName;

    const/4 v4, 0x3
    invoke-static {v0, v4}, Lcom/xiaomi/fpsgraph/ServiceControl;->send(Landroid/content/Context;I)V

    const-string v4, "FPSGraph"
    const-string v5, "FrameRateDataService startService"
    invoke-static {v4, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_end

    :cond_stop
    invoke-static {}, Lcom/xiaomi/fpsgraph/ControllerRegistry;->unbindAll()V

    invoke-virtual {v0, v1}, Landroid/content/Context;->stopService(Landroid/content/Intent;)Z

    const-string v4, "FPSGraph"
    const-string v5, "FrameRateDataService stopService"
    invoke-static {v4, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    :goto_end
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    return-void
.end method
