.class public Lcom/xiaomi/fpsgraph/ControllerRegistry;
.super Ljava/lang/Object;


# static fields
.field private static final CONTROLLERS:Ljava/util/ArrayList;


# direct methods
.method static constructor <clinit>()V
    .registers 1

    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    sput-object v0, Lcom/xiaomi/fpsgraph/ControllerRegistry;->CONTROLLERS:Ljava/util/ArrayList;

    return-void
.end method

.method public static add(Ljava/lang/Object;)V
    .registers 4

    if-eqz p0, :done

    new-instance v0, Ljava/lang/ref/WeakReference;

    invoke-direct {v0, p0}, Ljava/lang/ref/WeakReference;-><init>(Ljava/lang/Object;)V

    const-string v1, "FPSGraph"
    const-string v2, "controller add"
    invoke-static {v1, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    sget-object v1, Lcom/xiaomi/fpsgraph/ControllerRegistry;->CONTROLLERS:Ljava/util/ArrayList;

    invoke-virtual {v1, v0}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    :done
    return-void
.end method

.method public static unbindAll()V
    .registers 8

    const-string v7, "FPSGraph"
    const-string v6, "unbindAll"
    invoke-static {v7, v6}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    sget-object v0, Lcom/xiaomi/fpsgraph/ControllerRegistry;->CONTROLLERS:Ljava/util/ArrayList;

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I

    move-result v1

    const/4 v2, 0x0

    :goto_loop
    if-ge v2, v1, :done

    invoke-virtual {v0, v2}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/lang/ref/WeakReference;

    invoke-virtual {v3}, Ljava/lang/ref/WeakReference;->get()Ljava/lang/Object;

    move-result-object v4

    if-eqz v4, :next

    :try_start
    iget-object v5, v4, Lcom/miui/gamebooster/framerate/FrameRateViewController;->a:Ljava/lang/ref/WeakReference;

    invoke-virtual {v5}, Ljava/lang/ref/Reference;->get()Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Lcom/miui/gamebooster/framerate/FrameRateView;

    if-eqz v5, :next

    invoke-virtual {v5}, Landroid/view/View;->getContext()Landroid/content/Context;

    move-result-object v6

    if-eqz v6, :next

    iget-object v7, v4, Lcom/miui/gamebooster/framerate/FrameRateViewController;->c:Lcom/miui/gamebooster/framerate/FrameRateViewController$c;

    invoke-virtual {v6, v7}, Landroid/content/Context;->unbindService(Landroid/content/ServiceConnection;)V

    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch

    goto :next

    :catch
    goto :next

    :next
    add-int/lit8 v2, v2, 0x1

    goto :goto_loop

    :done
    return-void
.end method
