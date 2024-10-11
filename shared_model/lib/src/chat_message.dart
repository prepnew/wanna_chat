import 'package:json_annotation/json_annotation.dart';

import 'package:shared_model/src/cited_answer.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class WannaChatMessage {
  final MessageType type;
  final String message;
  final List<Citation> citations;

  final bool _loading;
  bool get isAi => type == MessageType.ai;
  bool get isAiLoading => isAi && _loading;
  bool get isHuman => type == MessageType.human;

  WannaChatMessage({required this.type, required this.message, this.citations = const []}) : _loading = false;
  WannaChatMessage.ai({required this.message, this.citations = const []})
      : _loading = false,
        type = MessageType.ai;
  WannaChatMessage.aiLoading()
      : _loading = true,
        type = MessageType.ai,
        message = '',
        citations = [];
  WannaChatMessage.human({required this.message, this.citations = const []})
      : _loading = false,
        type = MessageType.human;
  WannaChatMessage.fromCitiedAnswer({required this.type, required CitedAnswer citedAnswer})
      : _loading = false,
        message = citedAnswer.answer ?? '',
        citations = citedAnswer.citations;

  WannaChatMessage updateMessage(WannaChatMessage updatedMessage) {
    return WannaChatMessage(type: type, message: updatedMessage.message, citations: updatedMessage.citations);
  }

  static WannaChatMessage fromJson(Map<String, dynamic> json) => _$WannaChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WannaChatMessageToJson(this);
}

enum MessageType {
  human,
  ai,
}
