# Package Laterbox Windows Release & Inno Setup Installer
param (
    [switch]$BuildFlutter = $false,
    [switch]$SkipFlutterBuild = $false
)

$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $PSScriptRoot
Set-Location $RepoDir

$ReleaseDir = Join-Path $RepoDir "build\windows\x64\runner\Release"
$ExeFile = Join-Path $ReleaseDir "laterbox.exe"

# Step 1: Check Windows build
$ShouldBuild = $BuildFlutter -or (-not (Test-Path $ExeFile) -and -not $SkipFlutterBuild)
if ($ShouldBuild) {
    Write-Host "Building Flutter Windows release..." -ForegroundColor Cyan
    & "flutter" build windows --release
} else {
    Write-Host "Found existing Windows build at $ReleaseDir" -ForegroundColor Green
}

if (-not (Test-Path $ExeFile)) {
    Write-Error "Could not find $ExeFile. Please run with -BuildFlutter."
    exit 1
}

# Step 2: Locate Inno Setup Compiler
$ISCCCandidates = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
)

$ISCC = $null
foreach ($path in $ISCCCandidates) {
    if (Test-Path $path) {
        $ISCC = $path
        break
    }
}

if (-not $ISCC) {
    Write-Error "Inno Setup 6 (ISCC.exe) not found. Please install Inno Setup 6."
    exit 1
}

# Step 3: Compile Inno Setup Installer
$DistDir = Join-Path $RepoDir "dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

$IssFile = Join-Path $RepoDir "scripts\laterbox.iss"
Write-Host "Compiling Windows installer with $ISCC..." -ForegroundColor Cyan
& "$ISCC" "$IssFile"

$InstallerPath = Join-Path $DistDir "laterbox-windows-setup.exe"
if (Test-Path $InstallerPath) {
    $InstallerSize = (Get-Item $InstallerPath).Length / 1MB
    Write-Host ("Installer ready: {0} ({1:N2} MB)" -f $InstallerPath, $InstallerSize) -ForegroundColor Green
}

# Step 4: Create portable zip
$ZipPath = Join-Path $DistDir "laterbox-windows-x64.zip"
Write-Host "Creating portable zip bundle: $ZipPath..." -ForegroundColor Cyan
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}
Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal
$ZipSize = (Get-Item $ZipPath).Length / 1MB
Write-Host ("Portable zip ready: {0} ({1:N2} MB)" -f $ZipPath, $ZipSize) -ForegroundColor Green

# Step 5: Sync to web download directories
$DestDirs = @(
    (Join-Path $RepoDir "web\downloads"),
    (Join-Path $RepoDir "build\web\downloads")
)

foreach ($dest in $DestDirs) {
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }
    if (Test-Path $InstallerPath) {
        Copy-Item $InstallerPath -Destination (Join-Path $dest "laterbox-windows-setup.exe") -Force
    }
    if (Test-Path $ZipPath) {
        Copy-Item $ZipPath -Destination (Join-Path $dest "laterbox-windows-x64.zip") -Force
    }
    Write-Host "Synced download artifacts to $dest" -ForegroundColor DarkCyan
}

Write-Host "All packaging tasks completed successfully!" -ForegroundColor Green
