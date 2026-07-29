#ifndef MyAppName
  #error MyAppName is required
#endif
#ifndef MyAppVersion
  #error MyAppVersion is required
#endif
#ifndef MyAppId
  #error MyAppId is required
#endif
#ifndef MyAppExe
  #error MyAppExe is required
#endif
#ifndef MyInstallFolder
  #error MyInstallFolder is required
#endif
#ifndef MySourceDir
  #error MySourceDir is required
#endif
#ifndef MySetupIcon
  #error MySetupIcon is required
#endif

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=SSStea
AppPublisherURL=https://github.com/SSStea/SSStea-Tesla_Authentication_System_ReBuild
AppSupportURL=https://github.com/SSStea/SSStea-Tesla_Authentication_System_ReBuild/issues
DefaultDirName={localappdata}\Programs\Authentication System\{#MyInstallFolder}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#MySetupIcon}
UninstallDisplayIcon={app}\{#MyAppExe}
OutputDir=.
OutputBaseFilename=Setup
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany=SSStea
VersionInfoDescription={#MyAppName} Installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent
