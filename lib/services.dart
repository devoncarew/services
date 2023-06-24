import 'dart:io';

import 'package:services/model/model.dart';
import 'package:services/sdk.dart';
import 'package:services/template.dart';

// import 'package:shelf/shelf.dart';

import 'analysis_server.dart';

// todo: analyze

// todo: build

class Services {
  final FlutterSdk sdk;
  late final AnalysisServerWrapper analyzer;

  Services({required this.sdk});

  Future<void> init() async {
    final templateDir = Directory('template');
    final template = Template(sdk: sdk, path: templateDir.absolute.path);
    await template.init();

    analyzer = AnalysisServerWrapper(sdk, template);
    await analyzer.init();
  }

  Future<void> dispose() async {
    await analyzer.shutdown();
  }

  VersionResponse handleVersion() {
    return VersionResponse(
      dartVersion: sdk.dartVersion,
      flutterVersion: sdk.flutterVersion,
    );
  }

  Future<FormatResponse> handleFormat(FormatRequest request) async {
    return await analyzer.format(request);
  }
}
