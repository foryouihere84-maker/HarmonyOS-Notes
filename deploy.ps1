$ErrorActionPreference = "Stop"

$packageName = "com.example.myapplication05"
$hapPath = "C:\Users\iherefor\MyApplication05\entry\build\default\outputs\default\entry-default-unsigned.hap"
$tempDir = "data/local/tmp/" + [Guid]::NewGuid().ToString("N")

Write-Host "Starting deployment..." -ForegroundColor Green
Write-Host "Package: $packageName" -ForegroundColor Cyan
Write-Host "HAP Path: $hapPath" -ForegroundColor Cyan
Write-Host "Temp Directory: $tempDir" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Stopping application..." -ForegroundColor Yellow
hdc shell aa force-stop $packageName
Write-Host "Application stopped." -ForegroundColor Green

Write-Host "[2/6] Creating temporary directory..." -ForegroundColor Yellow
hdc shell mkdir $tempDir
Write-Host "Temporary directory created." -ForegroundColor Green

Write-Host "[3/6] Sending HAP file..." -ForegroundColor Yellow
hdc file send $hapPath $tempDir
Write-Host "HAP file sent." -ForegroundColor Green

Write-Host "[4/6] Installing application..." -ForegroundColor Yellow
hdc shell bm install -p $tempDir
Write-Host "Application installed." -ForegroundColor Green

Write-Host "[5/6] Cleaning up temporary directory..." -ForegroundColor Yellow
hdc shell rm -rf $tempDir
Write-Host "Temporary directory removed." -ForegroundColor Green

Write-Host "[6/6] Starting application..." -ForegroundColor Yellow
hdc shell aa start -a EntryAbility -b $packageName
Write-Host "Application started." -ForegroundColor Green

Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
