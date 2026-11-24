.class public Lcom/xiaomi/fpsgraph/RingTint;
.super Ljava/lang/Object;

# interfaces
.implements Ljava/lang/Runnable;
.implements Landroid/view/View$OnClickListener;
.implements Landroid/view/View$OnAttachStateChangeListener;
.implements Landroid/widget/RadioGroup$OnCheckedChangeListener;


# instance fields
.field private final balanced:Landroid/widget/RadioButton;

.field private final bg:Landroid/graphics/drawable/GradientDrawable;

.field private lastColor:I

.field private final performance:Landroid/widget/RadioButton;

.field private final ring:Landroid/view/View;


# direct methods
.method public constructor <init>(Landroid/view/View;Landroid/graphics/drawable/GradientDrawable;Landroid/widget/RadioButton;Landroid/widget/RadioButton;)V
    .registers 6

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    iput-object p2, p0, Lcom/xiaomi/fpsgraph/RingTint;->bg:Landroid/graphics/drawable/GradientDrawable;

    iput-object p3, p0, Lcom/xiaomi/fpsgraph/RingTint;->balanced:Landroid/widget/RadioButton;

    iput-object p4, p0, Lcom/xiaomi/fpsgraph/RingTint;->performance:Landroid/widget/RadioButton;

    invoke-virtual {p1, p0}, Landroid/view/View;->addOnAttachStateChangeListener(Landroid/view/View$OnAttachStateChangeListener;)V

    return-void
.end method

.method private static maxChannel(I)I
    .registers 4

    # alpha 优先（未选中态常是白字降低透明度），alpha 相同再比最大 RGB 通道
    invoke-static {p0}, Landroid/graphics/Color;->alpha(I)I

    move-result v0

    shl-int/lit8 v0, v0, 0x8

    invoke-static {p0}, Landroid/graphics/Color;->red(I)I

    move-result v1

    invoke-static {p0}, Landroid/graphics/Color;->green(I)I

    move-result v2

    if-le v2, v1, :green

    move v1, v2

    :green
    invoke-static {p0}, Landroid/graphics/Color;->blue(I)I

    move-result v2

    if-le v2, v1, :blue

    move v1, v2

    :blue
    or-int/2addr v0, v1

    return v0
.end method


# virtual methods
.method public onCheckedChanged(Landroid/widget/RadioGroup;I)V
    .registers 3

    invoke-virtual {p0}, Lcom/xiaomi/fpsgraph/RingTint;->run()V

    return-void
.end method

.method public onClick(Landroid/view/View;)V
    .registers 2

    invoke-virtual {p0}, Lcom/xiaomi/fpsgraph/RingTint;->run()V

    return-void
.end method

.method public onViewAttachedToWindow(Landroid/view/View;)V
    .registers 2

    invoke-virtual {p0}, Lcom/xiaomi/fpsgraph/RingTint;->run()V

    return-void
.end method

.method public onViewDetachedFromWindow(Landroid/view/View;)V
    .registers 2

    invoke-virtual {p0}, Lcom/xiaomi/fpsgraph/RingTint;->stop()V

    return-void
.end method

.method public stop()V
    .registers 2

    iget-object v0, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    invoke-virtual {v0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z

    return-void
.end method

.method public run()V
    .registers 6

    iget-object v0, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    invoke-virtual {v0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z

    iget-object v2, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    invoke-virtual {v2}, Landroid/view/View;->isShown()Z

    move-result v2

    if-eqz v2, :not_shown

    new-instance v0, Landroid/graphics/Rect;

    invoke-direct {v0}, Landroid/graphics/Rect;-><init>()V

    iget-object v2, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    invoke-virtual {v2, v0}, Landroid/view/View;->getGlobalVisibleRect(Landroid/graphics/Rect;)Z

    move-result v0

    if-eqz v0, :not_shown

    # 以两个模式按钮当前文字颜色为准：亮的是当前选中模式
    iget-object v1, p0, Lcom/xiaomi/fpsgraph/RingTint;->balanced:Landroid/widget/RadioButton;

    invoke-virtual {v1}, Landroid/widget/TextView;->getCurrentTextColor()I

    move-result v2

    iget-object v1, p0, Lcom/xiaomi/fpsgraph/RingTint;->performance:Landroid/widget/RadioButton;

    invoke-virtual {v1}, Landroid/widget/TextView;->getCurrentTextColor()I

    move-result v3

    invoke-static {v2}, Lcom/xiaomi/fpsgraph/RingTint;->maxChannel(I)I

    move-result v2

    invoke-static {v3}, Lcom/xiaomi/fpsgraph/RingTint;->maxChannel(I)I

    move-result v3

    if-le v2, v3, :red

    goto :blue

    :red
    const v1, 0xffff5a4a

    goto :apply

    :blue
    const v1, 0xff3a8dff

    :apply
    iget v2, p0, Lcom/xiaomi/fpsgraph/RingTint;->lastColor:I

    if-eq v2, v1, :post

    iput v1, p0, Lcom/xiaomi/fpsgraph/RingTint;->lastColor:I

    new-instance v3, Landroid/graphics/drawable/GradientDrawable;

    invoke-direct {v3}, Landroid/graphics/drawable/GradientDrawable;-><init>()V

    const/4 v4, 0x1

    invoke-virtual {v3, v4}, Landroid/graphics/drawable/GradientDrawable;->setShape(I)V

    const v4, 0xff171a1c

    invoke-virtual {v3, v4}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V

    const/4 v4, 0x3

    invoke-virtual {v3, v4, v1}, Landroid/graphics/drawable/GradientDrawable;->setStroke(II)V

    iget-object v2, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    invoke-virtual {v2, v3}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V

    goto :post

    :not_shown
    iget-object v1, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    const-wide/16 v2, 0x7d0

    invoke-virtual {v1, p0, v2, v3}, Landroid/view/View;->postDelayed(Ljava/lang/Runnable;J)Z

    return-void

    :post
    iget-object v1, p0, Lcom/xiaomi/fpsgraph/RingTint;->ring:Landroid/view/View;

    const-wide/16 v2, 0x1f4

    invoke-virtual {v1, p0, v2, v3}, Landroid/view/View;->postDelayed(Ljava/lang/Runnable;J)Z

    return-void
.end method
