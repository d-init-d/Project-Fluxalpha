# Windows Installer Build Guide

## Prerequisites
- Flutter SDK installed
- Visual Studio 2022 (with Desktop Development with C++)
- MSIX Packaging Tool (optional for advanced customization)

## Method 1: MSIX Installer (Recommended)

### Step 1: Add MSIX Package
```bash
flutter pub add msix --dev
```

### Step 2: Configure pubspec.yaml
Add this configuration to `pubspec.yaml`:

```yaml
msix_config:
  display_name: Flux Alpha
  publisher_display_name: dmn05
  identity_name: com.dmn05.fluxalpha
  msix_version: 1.0.0.0
  logo_path: assets/icon/app_icon.png
  capabilities: 'internetClient,documentsLibrary,videosLibrary,picturesLibrary'
  
  # Optional: Custom colors
  # background_color: '#1A1A1A'
  # accent_color: '#FFD700'
```

### Step 3: Build Release
```bash
# Build Windows release
flutter build windows --release

# Create MSIX installer
flutter pub run msix:create
```

The `.msix` file will be created in `build\windows\x64\runner\Release\`

### Step 4: Install
Double-click the `.msix` file to install. Windows may show a warning if not code-signed.

## Method 2: Inno Setup (Traditional .exe installer)

### Step 1: Install Inno Setup
Download from: https://jrsoftware.org/isdl.php

### Step 2: Create Installer Script
See `installer_script.iss` in the root folder.

### Step 3: Build
1. Build release: `flutter build windows --release`
2. Open `installer_script.iss` in Inno Setup Compiler
3. Click "Compile" to generate `FluxAlpha_Setup.exe`

## Code Signing (Optional but Recommended)

### Why Code Sign?
- Removes "Unknown Publisher" warnings
- Increases user trust
- Required for Microsoft Store

### How to Sign
1. Get a Code Signing Certificate (DigiCert, GlobalSign, etc.)
2. Sign the MSIX:
```bash
signtool sign /f certificate.pfx /p password /fd SHA256 /tr http://timestamp.digicert.com FluxAlpha.msix
```

## Auto-Update Setup (Future Enhancement)

### Using Sparkle or similar
1. Host update manifest on web server
2. Add update checker service
3. Prompt user to download new version

Example manifest:
```json
{
  "version": "1.1.0",
  "releaseDate": "2024-12-27",
  "downloadUrl": "https://example.com/FluxAlpha_1.1.0.msix",
  "changelog": "Bug fixes and improvements"
}
```

## File Associations

To register `.epub` and `.pdf` file associations:

### Add to pubspec.yaml (msix_config):
```yaml
file_extension: '.epub,.pdf'
protocol_activation: fluxalpha
```

### Or add to Windows Registry (Inno Setup):
```iss
[Registry]
Root: HKCR; Subkey: ".epub"; ValueType: string; ValueName: ""; ValueData: "FluxAlpha.EpubFile"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "FluxAlpha.EpubFile"; ValueType: string; ValueName: ""; ValueData: "EPUB Book"; Flags: uninsdeletekey
Root: HKCR; Subkey: "FluxAlpha.EpubFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\flux_alpha.exe,0"
Root: HKCR; Subkey: "FluxAlpha.EpubFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\flux_alpha.exe"" ""%1"""
```

## Testing Checklist

Before distribution:
- [ ] Test installer on clean Windows 10 machine
- [ ] Test installer on Windows 11
- [ ] Verify file associations work
- [ ] Check app starts without errors
- [ ] Test uninstaller removes all files
- [ ] Verify settings persist after restart
- [ ] Check library path settings work

## Distribution

### Option 1: Direct Download
Host the `.msix` or `.exe` on your website.

### Option 2: Microsoft Store
1. Create Microsoft Partner Center account
2. Prepare store listing (screenshots, description)
3. Upload signed `.msix`
4. Submit for review

### Option 3: GitHub Releases
```bash
gh release create v1.0.0 FluxAlpha.msix --title "Flux Alpha v1.0.0" --notes "Initial release"
```

## Troubleshooting

### "This app can't run on your PC"
- Your build architecture doesn't match the PC (x64 vs ARM)
- Solution: Build for correct architecture

### "Windows protected your PC"
- App is not code-signed
- Solution: Click "More info" → "Run anyway", or get code signing certificate

### App crashes on startup
- Missing Visual C++ Redistributables
- Solution: Include redistributables in installer or use `msix` which bundles them

## Build Commands Summary

```bash
# Development
flutter run -d windows

# Release build only
flutter build windows --release

# MSIX installer
flutter pub run msix:create

# With custom name
flutter pub run msix:create --build-name 1.0.1 --build-number 2
```

## Version Bumping

Update version in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # 1.0.1 = version, 2 = build number
```

Then rebuild installer.
