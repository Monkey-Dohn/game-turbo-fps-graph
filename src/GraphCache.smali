.class public final Lcom/xiaomi/fpsgraph/GraphCache;
.super Ljava/lang/Object;

# 保存最近 240 个曲线点，面板关闭后服务停止，重开时用它回填。
.field private static final a:Ljava/util/ArrayList;

.method static constructor <clinit>()V
    .registers 1

    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    sput-object v0, Lcom/xiaomi/fpsgraph/GraphCache;->a:Ljava/util/ArrayList;

    return-void
.end method

.method public static update([I)V
    .registers 6

    if-eqz p0, :done

    array-length v0, p0

    if-nez v0, :done

    sget-object v1, Lcom/xiaomi/fpsgraph/GraphCache;->a:Ljava/util/ArrayList;

    const/4 v2, 0x1

    if-le v0, v2, :append

    # 长度大于 1 的全量数组，直接替换缓存
    invoke-virtual {v1}, Ljava/util/ArrayList;->clear()V

    const/4 v2, 0x0

    :replace_loop

    if-ge v2, v0, :trim

    aget v3, p0, v2

    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v4

    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    add-int/lit8 v2, v2, 0x1

    goto :replace_loop

    :append

    # 单点数组，追加到缓存
    const/4 v2, 0x0

    :append_loop

    if-ge v2, v0, :trim

    aget v3, p0, v2

    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v4

    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    add-int/lit8 v2, v2, 0x1

    goto :append_loop

    :trim

    invoke-virtual {v1}, Ljava/util/ArrayList;->size()I

    move-result v2

    const/16 v3, 0xf0

    :trim_loop

    if-le v2, v3, :done

    const/4 v4, 0x0

    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->remove(I)Ljava/lang/Object;

    add-int/lit8 v2, v2, -0x1

    goto :trim_loop

    :done
    sget-object v0, Lcom/xiaomi/fpsgraph/GraphCache;->a:Ljava/util/ArrayList;

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I
    move-result v0

    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "cache size="
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1

    const-string v0, "FPSGraph"
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method

.method public static snapshot()[I
    .registers 6

    sget-object v0, Lcom/xiaomi/fpsgraph/GraphCache;->a:Ljava/util/ArrayList;

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I

    move-result v1

    if-nez v1, :empty

    new-array v2, v1, [I

    const/4 v3, 0x0

    :loop

    if-ge v3, v1, :done

    invoke-virtual {v0, v3}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I

    move-result v5

    aput v5, v2, v3

    add-int/lit8 v3, v3, 0x1

    goto :loop

    :done

    return-object v2

    :empty

    const/4 v0, 0x0

    return-object v0
.end method

.method public static capture(Ljava/lang/Object;)V
    .registers 7

    :try_start_2
    const-string v0, "d"

    invoke-static {p0, v0}, Lde/robv/android/xposed/XposedHelpers;->getObjectField(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0

    check-cast v0, Ljava/util/ArrayList;

    if-eqz v0, :done_2

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I
    move-result v1

    if-nez v1, :done_2

    sget-object v2, Lcom/xiaomi/fpsgraph/GraphCache;->a:Ljava/util/ArrayList;

    invoke-virtual {v2}, Ljava/util/ArrayList;->clear()V

    const/4 v3, 0x0

    :capture_loop
    if-ge v3, v1, :done_2

    invoke-virtual {v0, v3}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v4

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I
    move-result v5

    invoke-static {v5}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v4

    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    add-int/lit8 v3, v3, 0x1

    goto :capture_loop

    :done_2
    return-void
    :try_end_2
    .catch Ljava/lang/Throwable; {:try_start_2 .. :try_end_2} :catch_2

    :catch_2
    move-exception v0

    return-void
.end method

.method public static clear()V
    .registers 1

    sget-object v0, Lcom/xiaomi/fpsgraph/GraphCache;->a:Ljava/util/ArrayList;

    invoke-virtual {v0}, Ljava/util/ArrayList;->clear()V

    return-void
.end method
