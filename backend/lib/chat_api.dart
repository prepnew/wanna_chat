import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shared_model/shared_model.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wanna_chat_server/chat_service.dart';

class ChatApi {
  ChatApi(this.service) {
    _router.get('/chat/<sessionId>', _restoreHistory);
    _router.post('/chat/<sessionId>', _question);
    _router.delete('/chat/<sessionId>', _clearHistory);
  }

  final Logger _logger = Logger('WannaChatAPI');
  final _router = Router();

  final WannaChatService service;

  Handler get handler => _router.call;

  // -- API handlers --

  /// API handler for restoring chat history
  Future<Response> _restoreHistory(Request request, String sessionId) async {
    final history = await service.getHistory(sessionId: sessionId);
    return Response.ok(
      jsonEncode({
        'history': history,
      }),
      headers: {'Content-type': 'application/json'},
    );
  }

  /// API handler for asking a question
  Future<Response> _question(Request request, String sessionId) async {
    if (!service.ready) {
      return Response(HttpStatus.serviceUnavailable);
    }

    final body = await request.readAsString();
    final payload = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : <String, dynamic>{};
    // TODO: Add support for cancelling the previous question

    _logger.fine('($sessionId) Received question: "$payload"');

    if (payload.isNotEmpty) {
      final streamed = payload['stream'] as bool? ?? false;
      final question = WannaChatMessage.fromJson(payload);
      if (streamed) {
        // TODO: Implement streaming
        return Response(
          400,
          headers: {'Content-type': 'application/text'},
          body: 'Bad request: Streaming not implemented yet',
        );
      } else {
        final response = await service.askQuestion(
          question: question.message,
          sessionId: sessionId,
        );
        service.saveHistory(question: question.message, result: response, sessionId: sessionId);

        return Response.ok(
          jsonEncode({
            'answer': WannaChatMessage.ai(message: response.answer ?? '', citations: response.citations),
          }),
          headers: {'Content-type': 'application/json'},
        );
      }
    }
    return Response(
      400,
      headers: {'Content-type': 'application/text'},
      body: 'Bad request: Missing "question" and "session_id" in request body',
    );
  }

  /// API handler for clearing chat history
  Future<Response> _clearHistory(Request request, WannaChatService service, String sessionId) async {
    service.clearHistory(sessionId: sessionId);
    return Response.ok('{}');
  }
}
