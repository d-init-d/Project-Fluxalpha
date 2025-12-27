; Flux Alpha Installer Script for Inno Setup
; See https://jrsoftware.org/isinfo.php for documentation

#define MyAppName "Flux Alpha"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "dmn05"
#define MyAppURL "https://github.com/dmn05/flux_alpha"
#define MyAppExeName "flux_alpha.exe"

[Setup]
; App identity
AppId={{B5C9A1E2-3F4D-4A5B-9C8D-7E6F5A4B3C2D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation paths
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Output
OutputDir=build\installer
OutputBaseFilename=FluxAlpha_Setup_{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes

; Requirements
MinVersion=10.0
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest

; UI
WizardStyle=modern
SetupIconFile=assets\icon\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; License (optional, create if needed)
; LicenseFile=LICENSE.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "vietnamese"; MessagesFile: "compiler:Languages\Vietnamese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable and data
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Registry]
; File associations for .epub
Root: HKCR; Subkey: ".epub"; ValueType: string; ValueName: ""; ValueData: "FluxAlpha.EpubFile"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "FluxAlpha.EpubFile"; ValueType: string; ValueName: ""; ValueData: "EPUB Book"; Flags: uninsdeletekey
Root: HKCR; Subkey: "FluxAlpha.EpubFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCR; Subkey: "FluxAlpha.EpubFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

; File associations for .pdf
Root: HKCR; Subkey: ".pdf\OpenWithProgids"; ValueType: string; ValueName: "FluxAlpha.PdfFile"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCR; Subkey: "FluxAlpha.PdfFile"; ValueType: string; ValueName: ""; ValueData: "PDF Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "FluxAlpha.PdfFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCR; Subkey: "FluxAlpha.PdfFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Custom installation logic can go here
function InitializeSetup(): Boolean;
begin
  Result := True;
end;
