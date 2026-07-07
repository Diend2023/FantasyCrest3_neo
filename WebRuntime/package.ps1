chcp 65001
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertFile  = "$ScriptDir\testcert.pfx"
$CertPass  = "password"

# 1. 编译（MainTimeline.as 已含全部帧代码，可直接用 mxmlc 编译）
Write-Host "[1/2] Compile..."
Push-Location $ScriptDir
mxmlc -debug=true -swf-version=51 -default-background-color=#ffffff -default-frame-rate=24 -default-size 1000 550 -source-path . -output WebRuntime.swf -- WebRuntime_fla/MainTimeline.as
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "COMPILE FAILED" }
Pop-Location

# 2. 打包（只含 WebRuntime.swf + 图标）
Write-Host "[2/2] Package..."
Push-Location $ScriptDir
adt -package `
    -storetype pkcs12 -keystore $CertFile -storepass $CertPass `
    -target bundle `
    "WebRuntime.app" `
    "WebRuntime-app.xml" `
    "WebRuntime.swf" `
    "AppIconsForPublish/48.png"
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "PACKAGE FAILED" }
Pop-Location

Write-Host "DONE: $ScriptDir\WebRuntime.app"
Read-Host
