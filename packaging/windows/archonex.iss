; Inno Setup script for the Windows installer published on GitHub Releases.
;
; The alternative was shipping only the zip the Flutter build produces. It works,
; and it is still published beside this — but a zip is a file the recipient has to
; know what to do with, and the Flutter runner will not start if the exe is copied
; out of it away from its DLLs and `data/`, which fails in a way that looks like a
; corrupt download. An installer puts the whole bundle down in one place, adds a
; Start Menu entry and an uninstaller, and needs no administrator rights.
;
; Every path is passed in by `.github/workflows/release.yml` rather than guessed
; here: the build directory, the version and the output name all come from one
; place in the workflow, so a rename cannot leave the two disagreeing.
;   ISCC /DAppVersion=1.1.0 /DBundleDir=… /DOutputDir=… /DOutputBase=… archonex.iss

#ifndef AppVersion
  #error AppVersion must be passed in with /DAppVersion=<version>
#endif
#ifndef BundleDir
  #error BundleDir must be passed in with /DBundleDir=<flutter release bundle>
#endif
#ifndef OutputDir
  #error OutputDir must be passed in with /DOutputDir=<where the setup exe goes>
#endif
#ifndef OutputBase
  #error OutputBase must be passed in with /DOutputBase=<setup exe name, no extension>
#endif

#define AppName "Archonex Converter"
#define AppPublisher "Archonex"
#define AppUrl "https://github.com/EvgeniuGlinsky/Archonex-Converter"
#define AppExe "archonex_converter.exe"

[Setup]
; Never change this GUID. It is how Windows recognises an existing installation,
; and how a new version replaces the old one instead of sitting beside it.
AppId={{7B2E9C41-5D3A-4F18-9E60-A4C7B1F2D8E3}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases

; `lowest` keeps the whole install inside the user's profile, so no UAC prompt
; appears at all. An unsigned installer that also demands administrator rights is
; the combination people are right to refuse.
PrivilegesRequired=lowest
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir={#OutputDir}
OutputBaseFilename={#OutputBase}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes

; The bundle is a quarter of a gigabyte before compression, almost all of it
; FFmpeg. Saying so on the first page is better than a progress bar that looks
; stuck.
AppComments=Offline file converter. Media, images and PDF, converted on this machine.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The entire Flutter release bundle: the exe, the Flutter DLL, `data/` and the
; FFmpeg DLLs beside them. Splitting it up is not an option — the runner resolves
; all of it relative to the exe.
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
