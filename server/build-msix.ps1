# XR5FE Host Server - MSIX Build Script
# A fork of AR3Te
# Run this script in PowerShell as Administrator

param(
    [string]$CertificatePath = "",
    [string]$CertificatePassword = "",
    [switch]$SkipBuild,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$PackageName = "XR5FEHostServer"
$Version = "1.0.0.0"
$Publisher = "CN=XR5FE"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  XR5FE Host Server - MSIX Builder" -ForegroundColor Cyan
Write-Host "  (A fork of AR3Te)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Find Windows SDK path
function Get-WindowsSDKPath {
    $sdkPaths = @(
        "C:\Program Files (x86)\Windows Kits\10\App Certification Kit",
        "C:\Program Files (x86)\Windows Kits\10\bin\x64",
        "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64"
    )
    
    foreach ($path in $sdkPaths) {
        if (Test-Path "$path\makeappx.exe") {
            return $path
        }
    }
    return $null
}

$sdkPath = Get-WindowsSDKPath
if ($null -eq $sdkPath) {
    Write-Host "ERROR: Windows SDK not found!" -ForegroundColor Red
    Write-Host "Please install Windows 10/11 SDK from:" -ForegroundColor Yellow
    Write-Host "https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/" -ForegroundColor Yellow
    exit 1
}

$makeAppx = "$sdkPath\makeappx.exe"
$signTool = "$sdkPath\signtool.exe"

Write-Host "[OK] Found Windows SDK at: $sdkPath" -ForegroundColor Green

# Check for .NET SDK
try {
    $dotnetVersion = dotnet --version
    Write-Host "[OK] .NET SDK version: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: .NET SDK not found!" -ForegroundColor Red
    Write-Host "Please install .NET 8.0 SDK from:" -ForegroundColor Yellow
    Write-Host "https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Yellow
    exit 1
}

# Check for Node.js
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Node.js not found!" -ForegroundColor Red
    Write-Host "Please install Node.js from:" -ForegroundColor Yellow
    Write-Host "https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 1: Build C# Application
if (!$SkipBuild) {
    Write-Host "Step 1: Building C# Application..." -ForegroundColor Cyan
    
    # Restore NuGet packages
    Write-Host "  Restoring NuGet packages..." -ForegroundColor Gray
    dotnet restore Capture.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to restore NuGet packages" -ForegroundColor Red
        exit 1
    }
    
    # Publish the application
    Write-Host "  Publishing Release build..." -ForegroundColor Gray
    dotnet publish Capture.csproj -c Release -o publish --self-contained false
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to publish C# application" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] C# Application built successfully" -ForegroundColor Green
} else {
    Write-Host "Step 1: Skipping build (using existing files)" -ForegroundColor Cyan
}

# Step 2: Install Node.js dependencies
Write-Host ""
Write-Host "Step 2: Installing Node.js dependencies..." -ForegroundColor Cyan
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install npm packages" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Node.js dependencies installed" -ForegroundColor Green

# Step 3: Copy files to publish directory
Write-Host ""
Write-Host "Step 3: Preparing package contents..." -ForegroundColor Cyan

# Create publish directory if it doesn't exist
if (!(Test-Path publish)) {
    New-Item -ItemType Directory -Path publish | Out-Null
}

# Copy server files
Write-Host "  Copying server files..." -ForegroundColor Gray
Copy-Item server.js -Destination publish\ -Force
Copy-Item package.json -Destination publish\ -Force
Copy-Item package-lock.json -Destination publish\ -Force

# Copy node_modules
if (Test-Path node_modules) {
    Write-Host "  Copying node_modules..." -ForegroundColor Gray
    if (Test-Path publish\node_modules) {
        Remove-Item publish\node_modules -Recurse -Force
    }
    Copy-Item node_modules -Destination publish\ -Recurse
}

# Copy AppxManifest.xml
Write-Host "  Copying manifest..." -ForegroundColor Gray
Copy-Item AppxManifest.xml -Destination publish\ -Force

# Copy Assets folder
if (Test-Path Assets) {
    Write-Host "  Copying assets..." -ForegroundColor Gray
    if (Test-Path publish\Assets) {
        Remove-Item publish\Assets -Recurse -Force
    }
    Copy-Item Assets -Destination publish\ -Recurse
}

# Rename executable to match manifest
Write-Host "  Renaming executable..." -ForegroundColor Gray
if (Test-Path publish\Capture.exe) {
    Move-Item publish\Capture.exe publish\XR5FEHostServer.exe -Force
}

Write-Host "[OK] Package contents prepared" -ForegroundColor Green

# Step 4: Create MSIX package
Write-Host ""
Write-Host "Step 4: Creating MSIX package..." -ForegroundColor Cyan

$msixFile = "$PackageName.msix"

# Remove existing MSIX if present
if (Test-Path $msixFile) {
    Remove-Item $msixFile -Force
}

# Create MSIX
Write-Host "  Running makeappx.exe..." -ForegroundColor Gray
& $makeAppx pack /d publish /p $msixFile /v
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create MSIX package" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] MSIX package created: $msixFile" -ForegroundColor Green

# Step 5: Sign the package (optional)
if ($CertificatePath -ne "") {
    Write-Host ""
    Write-Host "Step 5: Signing package..." -ForegroundColor Cyan
    
    if (!(Test-Path $CertificatePath)) {
        Write-Host "ERROR: Certificate file not found: $CertificatePath" -ForegroundColor Red
        exit 1
    }
    
    $signArgs = @("sign", "/fd", "SHA256", "/f", $CertificatePath)
    if ($CertificatePassword -ne "") {
        $signArgs += @("/p", $CertificatePassword)
    }
    $signArgs += @($msixFile)
    
    & $signTool @signArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Failed to sign package (continuing with unsigned package)" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Package signed successfully" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "Step 5: Skipping signing (no certificate provided)" -ForegroundColor Cyan
    Write-Host "  For distribution, sign the package with a valid certificate" -ForegroundColor Gray
    Write-Host "  For testing, enable Developer Mode in Windows Settings" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BUILD COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $msixFile" -ForegroundColor White
Write-Host "Size: $([math]::Round((Get-Item $msixFile).Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host ""

if ($CertificatePath -eq "") {
    Write-Host "INSTALLATION INSTRUCTIONS:" -ForegroundColor Yellow
    Write-Host "1. Enable Developer Mode in Windows Settings" -ForegroundColor Gray
    Write-Host "2. Double-click $msixFile" -ForegroundColor Gray
    Write-Host "3. Click 'Install'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For distribution, rebuild with: " -ForegroundColor Gray
    Write-Host ".\build-msix.ps1 -CertificatePath `"path\to\cert.pfx`" -CertificatePassword `"yourpassword`"" -ForegroundColor Gray
}

Write-Host ""
