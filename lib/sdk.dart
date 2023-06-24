// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

const _channels = ['stable', 'beta', 'master'];

class FlutterSdk {
  // Which channel is this SDK?
  final String channel;

  /// The path to the Flutter SDK.
  final String path;

  final String flutterVersion;

  /// The path to the vendored Dart SDK.
  final String dartSdkPath;

  /// The current version of the Dart SDK.
  final String dartVersion;

  factory FlutterSdk.createFromExisting(String path, String channel) {
    final dartSdkPath = p.join(path, 'bin', 'cache', 'dart-sdk');

    return FlutterSdk._(
      path: path,
      dartSdkPath: dartSdkPath,
      dartVersion: _readVersionFile(dartSdkPath),
      flutterVersion: _readVersionFile(path),
      channel: channel,
    );
  }

  FlutterSdk._({
    required this.path,
    required this.dartSdkPath,
    required this.dartVersion,
    required this.flutterVersion,
    required this.channel,
  });

  /// The path to the 'flutter' tool (binary).
  String get flutterToolPath => p.join(path, 'bin', 'flutter');

  Future<void> dart(List<String> args, {required String cwd}) async {
    await execLog(
      p.join(dartSdkPath, 'bin', 'dart'),
      args,
      cwd,
      throwOnError: true,
    );
  }

  Future<void> flutter(List<String> args, {required String cwd}) async {
    await execLog(
      p.join(path, 'bin', 'flutter'),
      args,
      cwd,
      throwOnError: true,
    );
  }

  @override
  String toString() => 'Dart $dartVersion, Flutter $flutterVersion';

  static String get _sdkDir => p.join(Directory.current.path, 'sdk');
}

class SdkManager {
  Future<FlutterSdk> provisionSdk(String channel) async {
    if (!_channels.contains(channel)) {
      throw StateError('Unknown channel name: $channel');
    }

    final sdkPath = p.join(FlutterSdk._sdkDir, channel);
    Directory(sdkPath).parent.createSync();

    if (Directory(sdkPath).existsSync()) {
      // flutter upgrade
      await _flutter(sdkPath, ['upgrade']);
    } else {
      // git clone https://github.com/flutter/flutter.git -b stable stable
      await _cloneInto(FlutterSdk._sdkDir, channel);
    }

    // flutter precache --web
    await _flutter(sdkPath, ['precache', '--web']);

    return FlutterSdk.createFromExisting(sdkPath, channel);
  }

  Future<void> _cloneInto(String parentPath, String channel) async {
    await execLog(
      'git',
      [
        'clone',
        'https://github.com/flutter/flutter.git',
        '-b',
        channel,
        channel,
      ],
      parentPath,
      throwOnError: true,
    );
  }

  Future<void> _flutter(String sdkPath, List<String> args) async {
    await execLog(
      p.join(sdkPath, 'bin', 'flutter'),
      args,
      sdkPath,
      throwOnError: true,
    );
  }
}

String _readVersionFile(String filePath) =>
    _readFile(p.join(filePath, 'version'));

String _readFile(String filePath) => File(filePath).readAsStringSync().trim();
