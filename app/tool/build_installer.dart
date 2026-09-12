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

const _publisher = "Wallbizz";
const _homeUrl = 'https://github.com/prit-007/wallbizz';
const _appId = '{{a3b1c4d5-e6f7-4890-ab12-cd34ef56ab78}}';

const _releaseDir = 'build/windows/x64/runner/Release';
const _exeName = 'wallbizz.exe';
const _iconPath = 'windows/runner/resources/app_icon.ico';
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
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
WizardStyle=modern
OutputDir=$outputDir
OutputBaseFilename=wallbizz_setup_$version
SetupIconFile=$icon
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\\$_exeName
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$exePath"; DestDir: "{app}"; Flags: ignoreversion
Source: "$releaseDir\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\\Wallbizz"; Filename: "{app}\\$_exeName"
Name: "{autodesktop}\\Wallbizz"; Filename: "{app}\\$_exeName"; Tasks: desktopicon

[Run]
Filename: "{app}\\$_exeName"; Description: "{cm:LaunchProgram,Wallbizz}"; Flags: nowait postinstall skipifsilent
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
