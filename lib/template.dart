import 'sdk.dart';

const kMainDart = 'lib/main.dart';

class Template {
  final FlutterSdk sdk;
  final String path;

  Template({
    required this.sdk,
    required this.path,
  });

  Future<void> init() async {
    await sdk.flutter(['packages', 'get'], cwd: path);
  }
}
