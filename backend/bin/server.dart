import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:wanna_chat_server/chat_api.dart';
import 'package:wanna_chat_server/chat_service.dart';

void main(List<String> args) async {
  Logger.root.level = Level.INFO; // Level.ALL;
  Logger.root.onRecord.listen((record) {
    stderr.writeln('${record.level.name}: ${record.time}: ${record.message}');
  });

  final ip = InternetAddress.anyIPv4;

  final chatApi = ChatApi(WannaChatService());

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(
        headers: {
          ACCESS_CONTROL_ALLOW_ORIGIN: '*',
          ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, OPTIONS',
          ACCESS_CONTROL_ALLOW_HEADERS: '*',
        },
      ))
      .addHandler(chatApi.handler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  stderr.writeln('Server listening on port ${server.port}');
}
