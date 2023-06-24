import 'dart:convert';
import 'dart:io';

import 'package:services/model/model.dart';
import 'package:services/sdk.dart';
import 'package:services/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final sdk = await SdkManager().provisionSdk('stable');

  final Services servicesServer = Services(sdk: sdk);
  await servicesServer.init();

  // Configure routes.
  final router = Router()
    ..get('/ok', (Request request) {
      return Response.ok('ok');
    })
    ..get('/api/version', (Request request) {
      final response = servicesServer.handleVersion();
      return Response.ok(jsonEncode(response.toJson()));
    })
    ..post('/api/format', (Request request) async {
      final json =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final response =
          await servicesServer.handleFormat(FormatRequest.fromJson(json));
      return Response.ok(jsonEncode(response.toJson()));
    });

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  print('Server listening on port ${server.port}');
}
