import 'dart:io';

import 'package:services/model/model.dart';
import 'package:services/sdk.dart';
import 'package:services/services.dart';
import 'package:test/test.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    print('Usage: dart tool/update_sdk.dart [CHANNEL]');
    exitCode = 1;
    return;
  }

  final channel = args.single;
  final sdkManager = SdkManager();

  final sdk = await sdkManager.provisionSdk(channel);
  late final Services services;

  group('ServicesServer', () {
    setUpAll(() async {
      services = Services(sdk: sdk);
      await services.init();
    });

    tearDownAll(() async {
      await services.dispose();
    });

    test('version', () async {
      final response = services.handleVersion();
      expect(response.dartVersion, isNotEmpty);
      expect(response.flutterVersion, isNotEmpty);
    });

    group('format', () {
      test('basic', () async {
        final request = FormatRequest('void main(){}');
        final response = await services.handleFormat(request);
        expect(response.source, 'void main() {}\n');
      });

      test('no changes', () async {
        final request = FormatRequest('void main() {}\n');
        final response = await services.handleFormat(request);
        expect(response.source, 'void main() {}\n');
      });

      test('updates selection', () async {
        final request = FormatRequest(
          "void main() { print('hello'); }",
          selectionOffset: 15,
        );
        final response = await services.handleFormat(request);
        expect(response.source, "void main() {\n  print('hello');\n}\n");
        expect(response.selectionOffset, 17);
      });

      test('parse error', () async {
        final request = FormatRequest('void main() {\n');
        final response = services.handleFormat(request);

        expectLater(response, throwsA(const TypeMatcher<ErrorResponse>()));
      });
    });
  });
}
