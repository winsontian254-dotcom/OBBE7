# XR5FE Host Server - MSIX Packaging Build Instructions
*A fork of AR3Te*

## Prerequisites

Before running the build script, ensure you have the following installed on your Windows machine:

### Required Software
1. **Windows 10/11 SDK** (version 10.0.17763.0 or higher)
   - Download from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
   
2. **.NET 8.0 SDK**
   - Download from: https://dotnet.microsoft.com/download/dotnet/8.0
   
3. **Node.js** (v16 or higher)
   - Download from: https://nodejs.org/

4. **Visual Studio Build Tools** or **Visual Studio 2022**
   - With C++ desktop development workload

### Optional (for signing)
- Code signing certificate (.pfx file)
- If you don't have one, the package will be created unsigned (for testing only)

## Build Steps

### 1. Open PowerShell as Administrator
Right-click PowerShell and select "Run as Administrator"

### 2. Navigate to the server directory
```powershell
cd path\to\workspace\server
```

### 3. Run the build script
```powershell
.\build-msix.ps1
```

### 4. Install dependencies (if not already done)
The script will automatically:
- Restore NuGet packages for the C# project
- Install npm packages for Node.js
- Build the Capture.exe application
- Create the MSIX package

## Output

After successful build, you'll find:
- `XR5FEHostServer.msix` - The installer package
- `publish\` - Directory with all built files

## Installation

### For Testing (Unsigned Package)
1. Enable Developer Mode in Windows Settings
2. Double-click the `.msix` file
3. Click "Install"

### For Distribution (Signed Package)
If you have a code signing certificate:
```powershell
.\build-msix.ps1 -CertificatePath "path\to\certificate.pfx" -CertificatePassword "yourpassword"
```

Then distribute the signed `.msix` file to users.

## Troubleshooting

### Error: "makeappx not found"
- Ensure Windows SDK is installed
- Run: `winget install Microsoft.WindowsSDK`

### Error: "dotnet not found"
- Install .NET 8.0 SDK
- Restart PowerShell after installation

### Error: "npm not found"
- Install Node.js from nodejs.org
- Restart PowerShell after installation

### Error: Certificate issues
- For testing, use self-signed cert:
```powershell
New-SelfSignedCertificate -Type Custom -Subject "CN=XR5FE" -KeyUsage DigitalSignature -FriendlyName "XR5FE Test Cert" -CertStoreLocation "Cert:\CurrentUser\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
```

## Manual Build (Alternative)

If the script fails, you can build manually:

```powershell
# Build C# app
dotnet publish Capture.csproj -c Release -o publish

# Install Node.js dependencies
npm install

# Copy Node.js files to publish
Copy-Item server.js, package.json, package-lock.json publish\
Copy-Item node_modules publish\ -Recurse

# Create MSIX
& "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\makeappx.exe" pack /d publish /p XR5FEHostServer.msix
```

## Uninstall

To remove the installed application:
```powershell
Get-AppxPackage XR5FEHostServer | Remove-AppxPackage
```
