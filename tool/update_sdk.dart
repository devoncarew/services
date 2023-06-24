// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:services/sdk.dart';

// This tool is used to manually update the `sdk/` Flutter SDKs.

void main(List<String> args) async {
  if (args.length != 1) {
    print('Usage: dart tool/update_sdk.dart [CHANNEL]');
    exitCode = 1;
    return;
  }

  final channel = args.single;
  final sdkManager = SdkManager();
  print('Flutter channel $channel');
  print('---');

  final flutterSdk = await sdkManager.provisionSdk(channel);
  print('\nSDK setup complete: $flutterSdk');
}
