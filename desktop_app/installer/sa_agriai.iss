#define MyAppName "SA AgriAI"
#define MyAppVersion "0.1.0"
#define MyAppExeName "sa_agriai_desktop.exe"

[Setup]
AppId={{D9C8E548-0E61-4B90-9C5A-5A9BF7AC0F12}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=SA AgriAI
DefaultDirName={localappdata}\Programs\SA AgriAI
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=SA-AgriAI-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch SA AgriAI"; Flags: postinstall nowait skipifsilent
