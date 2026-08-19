# XR5FE Host Server - Quick Start Guide
*A fork of AR3Te*

## What is this?
This package contains the desktop server component for the XR5FE Android app (a fork of AR3Te). It captures your Windows screen and streams it to your Android device over WiFi.

## Components Included
- **Capture.exe** - Screen capture application using Windows Desktop Duplication API
- **server.js** - Node.js WebSocket server for communication with Android app
- **build-msix.ps1** - PowerShell script to create MSIX installer package

## Quick Build (Windows Only)

### 1. Prerequisites
Install these before building:
- Windows 10/11 SDK: https://developer.microsoft.com/windows/downloads/windows-sdk/
- .NET 8.0 SDK: https://dotnet.microsoft.com/download/dotnet/8.0
- Node.js: https://nodejs.org/

### 2. Build the MSIX Installer
Open PowerShell **as Administrator** and run:
```powershell
cd path\to\server
.\build-msix.ps1
```

### 3. Install
After building, you'll get `XR5FEHostServer.msix`:
1. Enable **Developer Mode** in Windows Settings → System → For developers
2. Double-click `XR5FEHostServer.msix`
3. Click **Install**

### 4. Run
- Launch "XR5FE Host Server" from Start Menu
- The server will start automatically
- Connect from your Android app using the displayed IP address

## Manual Installation (Without MSIX)

If you prefer not to use MSIX:

```powershell
# Build and run manually
dotnet publish Capture.csproj -c Release -o publish
npm install
node server.js
```

## Usage

1. **Start the server** on your Windows PC
2. **Open the Android app** on your device
3. **Connect** - The app should auto-discover the server on the same network
4. **Stream** - Your PC screen will appear on your Android device

## Network Requirements
- Both devices must be on the same WiFi network
- Firewall may prompt - allow access for the server
- Ports used: 45678 (UDP discovery), 45679-45681 (WebSocket)

## Troubleshooting

### Server not found by Android app
- Check both devices are on same network
- Disable firewall temporarily to test
- Manually enter PC IP address in Android app

### Black screen or no video
- Ensure GPU drivers are up to date
- Try running as Administrator
- Check Windows Event Viewer for errors

### Build fails
- Run PowerShell as Administrator
- Install all prerequisites listed above
- Check error messages for missing dependencies

## Support
For issues or questions, check the project documentation or contact support.
