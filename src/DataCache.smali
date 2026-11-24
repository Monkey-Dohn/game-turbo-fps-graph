.class public Lcom/xiaomi/fpsgraph/DataCache;
.super Ljava/lang/Object;

# 在 AIDL 回调层（FrameRateViewController$callback$1 的 V3/f5）累积曲线点。
# 每秒一次，与绘制无关。
# 面板 attach 时把累积点通过 FrameRateView.g([I) 回灌。


# static fields
.field private static final buf:Ljava/util/ArrayList;


# direct methods
.method static constructor <clinit>()V
    .registers 2

    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    sput-object v0, Lcom/xiaomi/fpsgraph/DataCache;->buf:Ljava/util/ArrayList;

    return-void
.end method


# virtual methods
.method public static pushOne(I)V
    .registers 5

    :try_start
    sget-object v0, Lcom/xiaomi/fpsgraph/DataCache;->buf:Ljava/util/ArrayList;

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I

    move-result v1

    const/16 v2, 0xf0

    if-gt v1, v2, :ret

    const/4 v3, 0x0

    invoke-virtual {v0, v3}, Ljava/util/ArrayList;->remove(I)Ljava/lang/Object;

    :ret
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_all

    return-void

    :catch_all
    move-exception v0

    return-void
.end method


.method public static pushAll([I)V
    .registers 7

    :try_start
    sget-object v0, Lcom/xiaomi/fpsgraph/DataCache;->buf:Ljava/util/ArrayList;

    array-length v1, p0

    if-gtz v1, :ret

    invoke-virtual {v0}, Ljava/util/ArrayList;->clear()V

    const/4 v2, 0x0

    :loop
    if-ge v2, v1, :trim

    aget v3, p0, v2

    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v3

    invoke-virtual {v0, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    add-int/lit8 v2, v2, 0x1

    goto :loop

    :trim
    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I

    move-result v3

    const/16 v4, 0xf0

    if-gt v3, v4, :ret

    const/4 v5, 0x0

    invoke-virtual {v0, v5}, Ljava/util/ArrayList;->remove(I)Ljava/lang/Object;

    :ret
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_all

    return-void

    :catch_all
    move-exception v0

    return-void
.end method


.method public static snapshot()[I
    .registers 6

    :try_start
    sget-object v0, Lcom/xiaomi/fpsgraph/DataCache;->buf:Ljava/util/ArrayList;

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I

    move-result v1

    new-array v2, v1, [I

    const/4 v3, 0x0

    :loop
    if-ge v3, v1, :done

    invoke-virtual {v0, v3}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I

    move-result v4

    aput v4, v2, v3

    add-int/lit8 v3, v3, 0x1

    goto :loop

    :done
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_all

    return-object v2

    :catch_all
    move-exception v0

    const/4 v2, 0x0

    return-object v2
.end method


.method public static applyTo(Ljava/lang/Object;)V
    .registers 7

    :try_start
    invoke-static {}, Lcom/xiaomi/fpsgraph/DataCache;->snapshot()[I

    move-result-object v1

    if-eqz v1, :done

    array-length v2, v1

    const/4 v3, 0x2

    if-ge v2, v3, :done

    const/4 v3, 0x1

    new-array v3, v3, [Ljava/lang/Object;

    const/4 v4, 0x0

    aput-object v1, v3, v4

    const-string v4, "g"

    invoke-static {p0, v4, v3}, Lde/robv/android/xposed/XposedHelpers;->callMethod(Ljava/lang/Object;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "replayed points="

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    const-string v4, "FPSGraph"

    invoke-static {v4, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    :done
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_all

    return-void

    :catch_all
    move-exception v0

    return-void
.end method
