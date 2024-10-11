import 'package:langchain/langchain.dart';
import 'package:shared_model/shared_model.dart';

class ConversationMemory {
  final Map<String, List<WannaChatMessage>> _messageHistories = {};

  List<WannaChatMessage> getMessageHistory(String sessionId) {
    return _messageHistories[sessionId] ?? [];
  }

  List<ChatMessage> getChatMessageHistory(String sessionId) {
    return getMessageHistory(sessionId)
        .map((e) => e.isAi ? ChatMessage.ai(e.message) : ChatMessage.human(ChatMessageContent.text(e.message)))
        .toList();
  }

  void appendQuestionAnswer({required String sessionId, required String question, required CitedAnswer citedAnswer}) {
    _messageHistories.putIfAbsent(sessionId, () => <WannaChatMessage>[]);
    _messageHistories[sessionId]?.add(WannaChatMessage.human(message: question));
    _messageHistories[sessionId]
        ?.add(WannaChatMessage.fromCitiedAnswer(type: MessageType.ai, citedAnswer: citedAnswer));
  }

  void clearHistory({required String sessionId}) {
    _messageHistories.remove(sessionId);
  }
}
