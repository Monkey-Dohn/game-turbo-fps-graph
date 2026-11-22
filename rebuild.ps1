param(
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

# 该脚本只重建 classes.dex 并替换进 unsigned.apk，不重新生成 manifest/资源。
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $Root) { $Root = (Get-Location).Path }
$Java = 'C:\Program Files (x86)\Common Files\Oracle\Java\java8path\java.exe'
$SmaliRoot = 'C:\Users\Dohn\AppData\Local\Temp\smali'
$BuildTools = 'C:\Users\Dohn\AppData\Local\Temp\bt35\android-15'
$Adb = 'C:\platform-tools\adb.exe'
$Dex = Join-Path $Root 'classes.dex'
$Unsigned = Join-Path $Root 'unsigned.apk'
$Repacked = Join-Path $Root 'unsigned2.apk'
$Aligned = Join-Path $Root 'aligned.apk'
$Signed = Join-Path $Root 'fpsgraph.apk'

$SmaliClasspath = @(
    (Join-Path $SmaliRoot 'smali.jar'),
    (Join-Path $SmaliRoot 'dexlib2.jar'),
    (Join-Path $SmaliRoot 'guava.jar'),
    (Join-Path $SmaliRoot 'antlr.jar'),
    (Join-Path $SmaliRoot 'jcommander.jar'),
    (Join-Path $SmaliRoot 'util.jar')
) -join ';'

if (Test-Path -LiteralPath $Dex) { Remove-Item -LiteralPath $Dex -Force }

& $Java -cp $SmaliClasspath org.jf.smali.Main assemble -a 28 -o $Dex (Join-Path $Root 'src')
if (-not (Test-Path -LiteralPath $Dex)) { throw 'smali assemble failed: classes.dex not produced' }

Copy-Item -LiteralPath $Unsigned -Destination $Repacked -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($Repacked, 'Update')
try {
    $old = $zip.GetEntry('classes.dex')
    if ($null -ne $old) { $old.Delete() }
    $entry = $zip.CreateEntry('classes.dex')
    $stream = $entry.Open()
    try {
        $bytes = [IO.File]::ReadAllBytes($Dex)
        $stream.Write($bytes, 0, $bytes.Length)
    }
    finally {
        $stream.Dispose()
    }
}
finally {
    $zip.Dispose()
}

& (Join-Path $BuildTools 'zipalign.exe') -f 4 $Repacked $Aligned
& (Join-Path $BuildTools 'apksigner.bat') sign `
    --ks (Join-Path $Root 'debug.keystore') `
    --ks-pass pass:android `
    --key-pass pass:android `
    --ks-key-alias androiddebugkey `
    --out $Signed $Aligned

Write-Output "Signed APK: $Signed"

if ($Install) {
    & $Adb install -r $Signed
    & $Adb shell 'am force-stop com.miui.securitycenter'
    # 按使用习惯，安装后删除本地安装包；保留源码与 unsigned.apk。
    Remove-Item -LiteralPath $Signed -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "${Signed}.idsig" -Force -ErrorAction SilentlyContinue
    Write-Output 'Installed. Force-stopped com.miui.securitycenter; reopen the game/sidebar to test.'
}
