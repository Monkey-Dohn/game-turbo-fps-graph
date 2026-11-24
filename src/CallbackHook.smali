.class public Lcom/xiaomi/fpsgraph/CallbackHook;
.super Lde/robv/android/xposed/XC_MethodHook;

# 挂在 FrameRateViewController$callback$1.V3(I) / f5([I) 之后：
# 这两个是 IFrameRateDataCallback 的实现，也是帧率数据真正进入 Java 层的入口。


.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Lde/robv/android/xposed/XC_MethodHook;-><init>()V

    return-void
.end method


.method protected afterHookedMethod(Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;)V
    .registers 5

    :try_start
    iget-object v0, p1, Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;->args:[Ljava/lang/Object;

    const/4 v1, 0x0

    aget-object v0, v0, v1

    if-eqz v0, :done

    instance-of v1, v0, [I

    if-eqz v1, :asArray

    check-cast v0, Ljava/lang/Integer;

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    invoke-static {v0}, Lcom/xiaomi/fpsgraph/DataCache;->pushOne(I)V

    goto :done

    :asArray
    check-cast v0, [I

    invoke-static {v0}, Lcom/xiaomi/fpsgraph/DataCache;->pushAll([I)V

    :done
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_all

    return-void

    :catch_all
    move-exception v0

    return-void
.end method
