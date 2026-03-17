$ErrorActionPreference = "Stop"

$NODE_HOME = "C:\Users\iherefor\Desktop\Environment\node-v24.13.1-win-x64"
$DEVECO_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk\default"
$HVIGORW_PATH = "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat"
$PROJECT_PATH = "C:\Users\iherefor\MyApplication05"
$HAP_PATH = "$PROJECT_PATH\entry\build\default\outputs\default\entry-default-unsigned.hap"
$PACKAGE_NAME = "com.example.myapplication05"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HarmonyOS Application Build & Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 1/7] Setting environment variables..." -ForegroundColor Yellow
$env:NODE_HOME = $NODE_HOME
$env:DEVECO_SDK_HOME = $DEVECO_SDK_HOME
Write-Host "NODE_HOME: $NODE_HOME" -ForegroundColor Green
Write-Host "DEVECO_SDK_HOME: $DEVECO_SDK_HOME" -ForegroundColor Green
Write-Host ""

Write-Host "[Step 2/7] Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path "$PROJECT_PATH\entry\build") {
    Remove-Item -Recurse -Force "$PROJECT_PATH\entry\build"
    Write-Host "Previous build cleaned." -ForegroundColor Green
} else {
    Write-Host "No previous build found." -ForegroundColor Green
}
Write-Host ""

Write-Host "[Step 3/7] Building HAP package..." -ForegroundColor Yellow
Set-Location $PROJECT_PATH
& $HVIGORW_PATH assembleHap --no-daemon 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $HAP_PATH)) {
    Write-Host "HAP file not found at: $HAP_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "[Step 4/7] Stopping application..." -ForegroundColor Yellow
hdc shell aa force-stop $PACKAGE_NAME
Write-Host "Application stopped." -ForegroundColor Green
Write-Host ""

$tempDir = "data/local/tmp/" + [Guid]::NewGuid().ToString("N")

Write-Host "[Step 5/7] Installing application..." -ForegroundColor Yellow
Write-Host "Temp Directory: $tempDir" -ForegroundColor Cyan
hdc shell mkdir $tempDir
hdc file send $HAP_PATH $tempDir
hdc shell bm install -p $tempDir
hdc shell rm -rf $tempDir
Write-Host "Application installed." -ForegroundColor Green
Write-Host ""

Write-Host "[Step 6/7] Starting application..." -ForegroundColor Yellow
hdc shell aa start -a EntryAbility -b $PACKAGE_NAME
Write-Host "Application started." -ForegroundColor Green
Write-Host ""

Write-Host "[Step 7/7] Build & Deploy Summary" -ForegroundColor Yellow
Write-Host "  - HAP Path: $HAP_PATH" -ForegroundColor Cyan
Write-Host "  - Package: $PACKAGE_NAME" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build & Deploy Completed Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
