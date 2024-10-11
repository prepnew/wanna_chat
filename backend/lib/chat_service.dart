import 'dart:io';

import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:logging/logging.dart';
import 'package:shared_model/shared_model.dart';
import 'package:wanna_chat_server/ingestion/ingestion_pipeline.dart';
import 'package:wanna_chat_server/query/chat_models.dart';
import 'package:wanna_chat_server/query/conversation_memory.dart';
import 'package:wanna_chat_server/query/prompt_templates.dart';
import 'package:wanna_chat_server/query/query_pipeline.dart';

const _dimensions = 1024;
const _openAIEmbeddingModel = 'text-embedding-3-large';

class WannaChatService {
  WannaChatService() {
    // Initialize the LLM
    _logger.info('Initializing LLM...');
    final openAiApiKey = Platform.environment['OPENAI_API_KEY'];
    if (openAiApiKey == null) {
      stderr.writeln('You need to set your OpenAI key in the OPENAI_API_KEY environment variable.');
      exit(64);
    }
    final models = ChatModels(
      fastLLM: ChatOpenAI(
        apiKey: openAiApiKey,
        defaultOptions: const ChatOpenAIOptions(model: 'gpt-4o-mini'), // ignore: avoid_redundant_argument_values
      ),
      qualityLLM: ChatOpenAI(
        apiKey: openAiApiKey,
        defaultOptions: const ChatOpenAIOptions(model: 'gpt-4o'),
      ),
      optionsForTemp: (double? temperature) => ChatOpenAIOptions(temperature: temperature),
    );

    // Setup embedding model
    _logger.info('Setting up embedding model ($_openAIEmbeddingModel, dimensions: $_dimensions)...');
    final embeddings = OpenAIEmbeddings(
      apiKey: openAiApiKey,
      model: _openAIEmbeddingModel,
      dimensions: _dimensions, // Limiting dimensions instead of using the default (higher) value
    );

    // Initialize a vector store, like for instance Objectbox:
    _logger.info('Initializing VectorStore...');
    final vectorStore = ObjectBoxVectorStore(
      embeddings: embeddings,
      dimensions: _dimensions,
    );
    // Or perhaps Supabase:
    // final supabaseUrl = Platform.environment['SUPABASE_URL'];
    // final supabaseApiKey = Platform.environment['SUPABASE_API_KEY'];
    // if (supabaseUrl == null || supabaseApiKey == null) {
    //   stderr.writeln('You need to set your OpenAI key in the OPENAI_API_KEY environment variable.');
    //   exit(64);
    // }
    // vectorStore = Supabase(
    //   //tableName: 'documents',
    //   embeddings: embeddings,
    //   supabaseUrl: supabaseUrl,
    //   supabaseKey: supabaseApiKey,
    // );

    _ingestionPipeline = IngestionPipeline(vectorStore: vectorStore);
    _queryPipeline = QueryPipeline(models, _conversationMemory);
    _ingestionPipeline.loadData().then((store) => _queryPipeline.initialize(store));
  }

  late final Logger _logger = Logger('WannaChatService');

  late final IngestionPipeline _ingestionPipeline;
  late final QueryPipeline _queryPipeline;
  final ConversationMemory _conversationMemory = ConversationMemory();

  bool get ready => _queryPipeline.ready;

  Future<CitedAnswer> askQuestion({required String question, required String sessionId}) async {
    return await _queryPipeline.executeQuery(question: question, sessionId: sessionId);
  }

  Stream<CitedAnswer> askQuestionStreamed({required String question, required String sessionId}) {
    return _queryPipeline.executeQueryStreamed(question: question, sessionId: sessionId);
  }

  void saveHistory({required String question, required CitedAnswer result, required String sessionId}) {
    _conversationMemory.appendQuestionAnswer(sessionId: sessionId, question: question, citedAnswer: result);
  }

  void clearHistory({required String sessionId}) {
    _logger.fine('Clearing history for session $sessionId');
    _conversationMemory.clearHistory(sessionId: sessionId);
  }

  Future<List<WannaChatMessage>> getHistory({required String sessionId}) async {
    final messages = _conversationMemory.getMessageHistory(sessionId);
    if (messages.isNotEmpty) {
      _logger.fine('Returning ${messages.length} messages for session $sessionId');
      return messages.nonNulls.toList();
    } else {
      _logger.fine('No messages found for session $sessionId');
      return [WannaChatMessage.ai(message: PromptTemplates.welcomeMessage.replaceAll('{name}', sessionId))];
    }
  }
}
