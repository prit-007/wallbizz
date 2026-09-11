import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum LogDomain { sync, auth, image, download, search, general }

final talker = TalkerFlutter.init(
  settings: TalkerSettings(useConsoleLogs: kDebugMode, useHistory: true),
);

void logInfo(String message, {LogDomain domain = LogDomain.general}) {
  talker.info(_tag(domain) + message);
}

void logDebug(String message, {LogDomain domain = LogDomain.general}) {
  talker.debug(_tag(domain) + message);
}

void logWarning(String message, {LogDomain domain = LogDomain.general}) {
  talker.warning(_tag(domain) + message);
}

void logError(
  String message, {
  Object? error,
  StackTrace? stackTrace,
  LogDomain domain = LogDomain.general,
}) {
  talker.handle(error ?? message, stackTrace, _tag(domain) + message);
}

String _tag(LogDomain domain) {
  switch (domain) {
    case LogDomain.sync:
      return '[Sync] ';
    case LogDomain.auth:
      return '[Auth] ';
    case LogDomain.image:
      return '[Image] ';
    case LogDomain.download:
      return '[Download] ';
    case LogDomain.search:
      return '[Search] ';
    case LogDomain.general:
      return '';
  }
}
