chcp 65001
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertFile  = "$ScriptDir\testcert.pfx"
$CertPass  = "password"

# 1. 编译
Write-Host "[1/2] Compile..."
Push-Location $ScriptDir
mxmlc -debug=true -swf-version=51 -default-background-color=#000000 -default-frame-rate=24 -default-size 1000 550 -output Bootstrap.swf -- Bootstrap.as
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "COMPILE FAILED" }
Pop-Location

# 2. 打包（只含 Bootstrap.swf + 图标）
Write-Host "[2/2] Package..."
Push-Location $ScriptDir
adt -package `
    -storetype pkcs12 -keystore $CertFile -storepass $CertPass `
    -target bundle `
    "Bootstrap.app" `
    "Bootstrap-app.xml" `
    "Bootstrap.swf" `
    "AppIconsForPublish/48.png"
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "PACKAGE FAILED" }
Pop-Location

Write-Host "DONE: $ScriptDir\Bootstrap.app"
Read-Host
