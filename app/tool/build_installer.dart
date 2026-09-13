import 'dart:io';

/// Builds a Windows installer for Wallbizz using the Inno Setup compiler.
///
/// Pipeline (run on Windows):
///   flutter build windows --release
///   dart run tool/build_installer.dart
///
/// Flags:
///   --dry-run  Generate the .iss without requiring a Windows release build or
///              the Inno Setup compiler. Use this to validate the script on any host.
///   --iscc     Absolute path to ISCC.exe when it is not resolvable from PATH.

const _publisher = "Developer's Paradise";
const _homeUrl = 'https://github.com/prit-007/wallbizz';
const _appId = '{{a3b1c4d5-e6f7-4890-ab12-cd34ef56ab78}}';

const _releaseDir = 'build/windows/x64/runner/Release';
const _exeName = 'wallbizz.exe';
const _iconPath = 'windows/runner/resources/app_icon.ico';
const _licensePath = 'LICENSE';
const _outputDir = 'build/installers';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final isccOverride = _flagValue(args, '--iscc');

  final version = _appVersion();
  final exe = File('$_releaseDir/$_exeName');
  if (!dryRun && !exe.existsSync()) {
    stderr.writeln('Error: $_releaseDir/$_exeName not found.');
    stderr.writeln('Run `flutter build windows --release` first.');
    exit(1);
  }

  final outputDir = Directory(_outputDir)..createSync(recursive: true);
  final issFile = File('${outputDir.path}/wallbizz_setup_$version.iss');
  issFile.writeAsStringSync(_buildIss(version, exe));
  stdout.writeln('Wrote ${issFile.path}');

  final iscc = isccOverride ?? _findIscc();
  if (iscc == null) {
    stdout.writeln(
      'iscc not found on PATH. Install Inno Setup from '
      'https://jrsoftware.org/isdl.php and re-run, or pass --iscc <path>.',
    );
    if (dryRun) return;
    exit(1);
  }

  stdout.writeln('Compiling installer with $iscc ...');
  final result = Process.runSync(iscc, [issFile.path]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);
  stdout.writeln('Installer: ${outputDir.path}/wallbizz_setup_$version.exe');
}

String _appVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('Could not parse version from pubspec.yaml.');
    exit(1);
  }
  return match.group(1)!;
}

String _buildIss(String version, File exe) {
  final releaseDir = exe.parent.absolute.path;
  final exePath = exe.absolute.path;
  final icon = File(_iconPath).absolute.path;
  final outputDir = Directory(_outputDir).absolute.path;

  final hasLicense = File(_licensePath).existsSync();
  final licenseSection = hasLicense
      ? 'LicenseFile=${File(_licensePath).absolute.path}'
      : '';

  return '''
[Setup]
AppId=$_appId
AppName=Wallbizz
AppVersion=$version
AppVerName=Wallbizz $version
AppPublisher=$_publisher
AppPublisherURL=$_homeUrl
AppSupportURL=$_homeUrl
AppUpdatesURL=$_homeUrl
DefaultDirName={localappdata}\\Wallbizz
DefaultGroupName=Wallbizz
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
WizardStyle=modern
WizardSizePercent=110
OutputDir=$outputDir
OutputBaseFilename=wallbizz_setup_$version
SetupIconFile=$icon
UninstallDisplayIcon={app}\\$_exeName
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
DisableProgramGroupPage=yes
$licenseSection
VersionInfoVersion=$version
VersionInfoCompany=$_publisher
VersionInfoDescription=Wallbizz - Premium Curated Wallpapers
VersionInfoCopyright=Copyright (c) $_publisher
VersionInfoProductName=Wallbizz
VersionInfoProductVersion=$version
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\\BrazilianPortuguese.isl"
Name: "czech"; MessagesFile: "compiler:Languages\\Czech.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\\Dutch.isl"
Name: "french"; MessagesFile: "compiler:Languages\\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\\German.isl"
Name: "italian"; MessagesFile: "compiler:Languages\\Italian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\\Polish.isl"
Name: "russian"; MessagesFile: "compiler:Languages\\Russian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1
Name: "associatefiles"; Description: "Associate wallpaper image files with Wallbizz"; GroupDescription: "File Associations:"; Flags: unchecked

[Files]
Source: "$exePath"; DestDir: "{app}"; Flags: ignoreversion
Source: "$releaseDir\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\\Wallbizz"; Filename: "{app}\\$_exeName"; Comment: "Launch Wallbizz"
Name: "{group}\\Wallbizz Website"; Filename: "$_homeUrl"
Name: "{group}\\{cm:UninstallProgram,Wallbizz}"; Filename: "{uninstallexe}"
Name: "{autoprograms}\\Wallbizz"; Filename: "{app}\\$_exeName"
Name: "{autodesktop}\\Wallbizz"; Filename: "{app}\\$_exeName"; Tasks: desktopicon
Name: "{userappdata}\\Microsoft\\Internet Explorer\\Quick Launch\\Wallbizz"; Filename: "{app}\\$_exeName"; Tasks: quicklaunchicon

[Registry]
Root: HKA; Subkey: "Software\\Classes\\.jpg\\OpenWithProgids";  ValueType: string; ValueName: "Wallbizz.Image"; Flags: uninsdeletevalue; Tasks: associatefiles
Root: HKA; Subkey: "Software\\Classes\\.jpeg\\OpenWithProgids"; ValueType: string; ValueName: "Wallbizz.Image"; Flags: uninsdeletevalue; Tasks: associatefiles
Root: HKA; Subkey: "Software\\Classes\\.png\\OpenWithProgids";  ValueType: string; ValueName: "Wallbizz.Image"; Flags: uninsdeletevalue; Tasks: associatefiles
Root: HKA; Subkey: "Software\\Classes\\.webp\\OpenWithProgids"; ValueType: string; ValueName: "Wallbizz.Image"; Flags: uninsdeletevalue; Tasks: associatefiles
Root: HKA; Subkey: "Software\\Classes\\Wallbizz.Image";         ValueType: string; ValueName: "";                    Flags: uninsdeletekey; Tasks: associatefiles
Root: HKA; Subkey: "Software\\Classes\\Wallbizz.Image\\DefaultIcon"; ValueType: string; ValueName: "{app}\\$_exeName,0"; Tasks: associatefiles
Root: HKA; Subkey: "Software\\Classes\\Wallbizz.Image\\shell\\open\\command"; ValueType: string; ValueName: "\\"{app}\\$_exeName\\" \\"%1\\""; Tasks: associatefiles

[Run]
Filename: "{app}\\$_exeName"; Description: "{cm:LaunchProgram,Wallbizz}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
''';
}

String? _findIscc() {
  final pathEnv = Platform.environment['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  for (final dir in pathEnv.split(separator)) {
    if (dir.isEmpty) continue;
    final candidate = File('$dir${Platform.pathSeparator}iscc.exe');
    if (candidate.existsSync()) return candidate.path;
  }
  const fallback = r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe';
  return File(fallback).existsSync() ? fallback : null;
}

String? _flagValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
