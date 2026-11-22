.class public Lcom/xiaomi/fpsgraph/PanelHook;
.super Lde/robv/android/xposed/XC_MethodHook;

.field private static lastCurve:I


.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Lde/robv/android/xposed/XC_MethodHook;-><init>()V
    return-void
.end method

.method protected afterHookedMethod(Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;)V
    .registers 16

    iget-object v0, p1, Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;->thisObject:Ljava/lang/Object;

    check-cast v0, Landroid/view/View;

    const-string v1, "FPSGRAPH panel enter"
    invoke-static {v1}, Lde/robv/android/xposed/XposedBridge;->log(Ljava/lang/String;)V

    const v1, 0x7f0b04f1
    invoke-virtual {v0, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v1
    if-eqz v1, :done

    sget v2, Lcom/xiaomi/fpsgraph/PanelHook;->lastCurve:I

    invoke-static {v1}, Ljava/lang/System;->identityHashCode(Ljava/lang/Object;)I
    move-result v3

    if-eqz v2, :first_apply
    if-eq v2, v3, :done

    :first_apply
    const-string v2, "FPSGRAPH panel apply"
    invoke-static {v2}, Lde/robv/android/xposed/XposedBridge;->log(Ljava/lang/String;)V

    const/4 v2, 0x0
    invoke-virtual {v1, v2}, Landroid/view/View;->setVisibility(I)V

    invoke-virtual {v1}, Landroid/view/View;->getParent()Landroid/view/ViewParent;
    move-result-object v3
    if-eqz v3, :done
    check-cast v3, Landroid/view/ViewGroup;

    invoke-virtual {v1}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v4
    invoke-virtual {v4}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v4
    iget v4, v4, Landroid/util/DisplayMetrics;->density:F

    const v5, 0x42700000
    mul-float/2addr v5, v4
    float-to-int v5, v5

    const/4 v6, -0x1
    new-instance v7, Landroid/widget/FrameLayout$LayoutParams;
    invoke-direct {v7, v6, v5}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    const v6, 0x41a00000
    mul-float/2addr v6, v4
    float-to-int v6, v6
    iput v6, v7, Landroid/widget/FrameLayout$LayoutParams;->topMargin:I

    invoke-virtual {v3, v1}, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V
    invoke-virtual {v3, v1, v2, v7}, Landroid/view/ViewGroup;->addView(Landroid/view/View;ILandroid/view/ViewGroup$LayoutParams;)V

    const v1, 0x7f0b08fb
    invoke-virtual {v0, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v1
    if-eqz v1, :nodial
    const/16 v2, 0x8
    invoke-virtual {v1, v2}, Landroid/view/View;->setVisibility(I)V

    :nodial
    const v1, 0x7f0b0e85
    invoke-virtual {v0, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v8

    const v1, 0x7f0b082b
    invoke-virtual {v0, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v9

    if-eqz v8, :nofps
    if-eqz v9, :nofps

    check-cast v8, Landroid/widget/TextView;
    check-cast v9, Landroid/view/ViewGroup;

    invoke-virtual {v0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v13

    invoke-virtual {v8}, Landroid/view/View;->getParent()Landroid/view/ViewParent;
    move-result-object v10
    if-eqz v10, :skipremove
    check-cast v10, Landroid/view/ViewGroup;
    invoke-virtual {v10, v8}, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V

    :skipremove
    new-instance v10, Landroid/widget/FrameLayout;
    invoke-direct {v10, v13}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V

    const/4 v14, 0x0
    invoke-virtual {v10, v14}, Landroid/view/View;->setClickable(Z)V
    invoke-virtual {v10, v14}, Landroid/view/View;->setFocusable(Z)V

    new-instance v11, Landroid/widget/LinearLayout;
    invoke-direct {v11, v13}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V

    const/4 v14, 0x0
    invoke-virtual {v11, v14}, Landroid/widget/LinearLayout;->setOrientation(I)V

    const/16 v14, 0x50
    invoke-virtual {v11, v14}, Landroid/widget/LinearLayout;->setGravity(I)V

    const v14, 0x41800000
    invoke-virtual {v8, v14}, Landroid/widget/TextView;->setTextSize(F)V

    const v14, 0xff3cedff
    invoke-virtual {v8, v14}, Landroid/widget/TextView;->setTextColor(I)V

    const/4 v14, 0x0
    invoke-virtual {v8, v14}, Landroid/widget/TextView;->setIncludeFontPadding(Z)V

    const/16 v14, 0x11
    invoke-virtual {v8, v14}, Landroid/widget/TextView;->setGravity(I)V

    const-string v14, "sans-serif-medium"
    const/4 v15, 0x0
    invoke-static {v14, v15}, Landroid/graphics/Typeface;->create(Ljava/lang/String;I)Landroid/graphics/Typeface;
    move-result-object v14
    invoke-virtual {v8, v14}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V

    const v14, 0x3c23d70a
    invoke-virtual {v8, v14}, Landroid/widget/TextView;->setLetterSpacing(F)V

    new-instance v14, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v15, -0x2
    invoke-direct {v14, v15, v15}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v11, v8, v14}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    new-instance v12, Landroid/widget/TextView;
    invoke-direct {v12, v13}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    const-string v14, "FPS"
    invoke-virtual {v12, v14}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const v14, 0x41000000
    invoke-virtual {v12, v14}, Landroid/widget/TextView;->setTextSize(F)V

    const v14, 0x99ffffff
    invoke-virtual {v12, v14}, Landroid/widget/TextView;->setTextColor(I)V

    const/16 v14, 0x11
    invoke-virtual {v12, v14}, Landroid/widget/TextView;->setGravity(I)V

    const v14, 0x3df5c28f
    invoke-virtual {v12, v14}, Landroid/widget/TextView;->setLetterSpacing(F)V

    const/4 v14, 0x0
    invoke-virtual {v12, v14}, Landroid/widget/TextView;->setIncludeFontPadding(Z)V

    invoke-virtual {v13}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v15
    invoke-virtual {v15}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v15
    iget v15, v15, Landroid/util/DisplayMetrics;->density:F

    const v14, 0x40800000
    mul-float/2addr v14, v15
    float-to-int v14, v14

    const/4 v15, 0x0
    invoke-virtual {v12, v14, v15, v15, v15}, Landroid/widget/TextView;->setPadding(IIII)V

    new-instance v14, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v15, -0x2
    invoke-direct {v14, v15, v15}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v11, v12, v14}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    new-instance v14, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v15, -0x2
    const/16 v12, 0x11
    invoke-direct {v14, v15, v15, v12}, Landroid/widget/FrameLayout$LayoutParams;-><init>(III)V
    invoke-virtual {v10, v11, v14}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    const v1, 0x7f0b07ff
    invoke-virtual {v0, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v5

    if-eqz v5, :noadd

    invoke-virtual {v5}, Landroid/view/View;->getLayoutParams()Landroid/view/ViewGroup$LayoutParams;
    move-result-object v6

    invoke-virtual {v6}, Ljava/lang/Object;->getClass()Ljava/lang/Class;
    move-result-object v7

    const/4 v14, 0x1
    new-array v14, v14, [Ljava/lang/Object;
    const/4 v15, 0x0
    aput-object v6, v14, v15
    invoke-static {v7, v14}, Lde/robv/android/xposed/XposedHelpers;->newInstance(Ljava/lang/Class;[Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v6

    check-cast v6, Landroid/view/ViewGroup$LayoutParams;
    const/4 v7, -0x1
    iput v7, v6, Landroid/view/ViewGroup$LayoutParams;->width:I
    iput v7, v6, Landroid/view/ViewGroup$LayoutParams;->height:I

    invoke-virtual {v9, v10, v6}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    invoke-virtual {v10}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v5
    invoke-virtual {v5}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v5
    iget v5, v5, Landroid/util/DisplayMetrics;->density:F

    const v6, 0x40a00000
    mul-float/2addr v6, v5
    invoke-virtual {v10, v6}, Landroid/view/View;->setTranslationY(F)V

    :noadd
    const/4 v14, 0x0
    invoke-virtual {v8, v14}, Landroid/view/View;->setVisibility(I)V

    :nofps
    const v1, 0x7f0b04f1
    invoke-virtual {v0, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v1
    if-eqz v1, :done

    const-string v2, "setRenderEnabled"
    const/4 v3, 0x1
    invoke-static {v3}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;
    move-result-object v3
    const/4 v4, 0x1
    new-array v4, v4, [Ljava/lang/Object;
    const/4 v5, 0x0
    aput-object v3, v4, v5
    invoke-static {v1, v2, v4}, Lde/robv/android/xposed/XposedHelpers;->callMethod(Ljava/lang/Object;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;

    invoke-static {v1}, Ljava/lang/System;->identityHashCode(Ljava/lang/Object;)I
    move-result v2
    sput v2, Lcom/xiaomi/fpsgraph/PanelHook;->lastCurve:I

    :done
    return-void
.end method
