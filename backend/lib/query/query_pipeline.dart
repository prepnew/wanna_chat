import 'package:collection/collection.dart';
import 'package:langchain/langchain.dart';
import 'package:logging/logging.dart';
import 'package:shared_model/shared_model.dart';
import 'package:wanna_chat_server/extensions/runnable_extensions.dart';
import 'package:wanna_chat_server/query/chat_models.dart';
import 'package:wanna_chat_server/query/conversation_memory.dart';
import 'package:wanna_chat_server/query/prompt_templates.dart';

typedef InputDict = Map<String, dynamic>;

typedef _QueryAnalysisChain = Runnable<InputDict, RunnableOptions, QueryAnalysisResult>;

final Logger _logger = Logger('QueryPipeline');

class QueryPipeline {
  QueryPipeline(this.chatModels, this.conversationMemory);

  final ChatModels chatModels;
  final ConversationMemory conversationMemory;

  bool _initialized = false;

  bool get ready => _initialized;

  late final Runnable<String, VectorStoreRetrieverOptions, List<Document>>? _documentRetrievalChain;
  late final RunnableSequence<InputDict, CitedAnswer> _queryChain;

  // --- API ---

  Future<void> initialize(VectorStore vectorStore) async {
    if (_initialized) {
      _logger.warning('Query pipeline already initialized');
      return;
    }
    _initialized = true;

    /// Setup document retrieval chain
    _documentRetrievalChain = vectorStore.asRetriever();
    _queryChain = _finalAnswerChain();
    _logger.fine('Query chain initialized.');
  }

  Future<CitedAnswer> executeQuery({required String question, required String sessionId}) {
    _logger.info('executeQuery($sessionId): $question');
    return _queryChain.invoke({
      'question': question,
      'sessionId': sessionId,
    });
  }

  Stream<CitedAnswer> executeQueryStreamed({required String question, required String sessionId}) {
    _logger.info('executeQueryStreamed($sessionId): $question');
    return _queryChain.stream({
      'question': question,
      'sessionId': sessionId,
    });
  }

  // --- Chain setup ---

  /// Final answer chain
  RunnableSequence<InputDict, CitedAnswer> _finalAnswerChain() {
    final documentRetrievalChain = _documentRetrievalChain;
    if (documentRetrievalChain == null) {
      _logger.warning('Query pipeline NOT ready');
      throw Exception('Query pipeline NOT ready');
    }

    final history = Runnable.fromFunction(invoke: (InputDict input, RunnableOptions? options) async {
      return conversationMemory.getChatMessageHistory(input['sessionId'].toString());
    });

    final Runnable<InputDict, RunnableOptions, CitedAnswer> ragOrFallbackRouter =
        Runnable.fromRouter((InputDict input, _) {
      final retrievalQuery = input.queryAnalysisResult;
      return retrievalQuery.matchesVectorStoreTopics ? _ragCitedAnswerChain() : _fallbackChain();
    });

    final Runnable<StringMap, RunnableOptions, String> rewriteWhenNeededRouter =
        Runnable.fromRouter((StringMap input, _) {
      return input.history.isNotEmpty
          ? _rewriteQueryChain()
          : Runnable.fromFunction(invoke: (i, _) => input['question'].toString());
    });

    return RunnableEx.assign({'history': history})
        .pipe(RunnableEx.assign({'question': rewriteWhenNeededRouter})) // Reformulate to standalone question
        .pipe(RunnableEx.assign({'queryAnalysisResult': _queryAnalysisChain()})) // Analyze the question
        .pipe(ragOrFallbackRouter);
  }

  /// Rewrite query chain
  Runnable<InputDict, RunnableOptions, String> _rewriteQueryChain() {
    final model = chatModels.fastLLMWithTemp(temperature: 0.1);
    final onlyUserMessages =
        RunnableEx.assignFunc('history', (input) => input.history.whereType<HumanChatMessage>().toList());
    return onlyUserMessages
        .pipe(rewriteQueryPrompt)
        .pipe(model)
        .pipe(const StringOutputParser())
        .pipe(_logOutput('RewriteQueryChain'));
  }

  /// Query analysis chain
  _QueryAnalysisChain _queryAnalysisChain() {
    final model = chatModels.qualityLLMWithTemp(
      temperature: 0.1,
      tools: const [PromptTemplates.analyzeQueryTool],
      toolChoice: ChatToolChoice.forced(name: 'QueryAnalysisResult'),
    );
    final chain = queryAnalysisPrompt | model | ToolsOutputParser();

    return chain.pipe(Runnable.fromFunction(invoke: (Object input, RunnableOptions? options) {
      final call = (input as List<ParsedToolCall>).first;
      return QueryAnalysisResult.fromJson(call.arguments);
    })).pipe(_logOutput('QueryAnalysisChain'));
  }

  /// RAG and CitedAnswer parsing chain
  RunnableSequence<InputDict, CitedAnswer> _ragCitedAnswerChain() {
    final docsForQuery =
        Runnable.mapInput((InputDict input) => input.queryAnalysisResult.vectorStoreQuery) | _documentRetrievalChain!;

    final retrieverChain = Runnable.fromMap<InputDict>({
      'history': Runnable.getItemFromMap('history'),
      'question': Runnable.getItemFromMap('question'),
      'docs': docsForQuery,
    }); //.pipe(_logOutput('Doc retrieval'));

    final model = chatModels.qualityLLMWithTemp(
      temperature: 0.1,
      tools: const [PromptTemplates.citedAnswerTool],
      toolChoice: ChatToolChoice.forced(name: 'CitedAnswer'),
    );

    final ragChain = RunnableEx.assignFunc('context', (input) => _convertDocsToString(input.docs)) |
        ragAnswerGenerationChainPrompt |
        model |
        ToolsOutputParser();
    //| _logOutput('CitedAnswer tool');

    return retrieverChain.pipe(ragChain).pipe(Runnable.fromFunction(invoke: (Object input, RunnableOptions? options) {
      final callArgs = (input as List<ParsedToolCall>).first.arguments;
      return CitedAnswer.fromJson(callArgs);
    }));
  }

  String _convertDocsToString(List<Document> documents) {
    final docsStrings = documents.mapIndexed((i, document) {
      return '**Document Title**: ${document.metadata['title']}\n'
          '**Document Topic**: ${document.metadata['topic']}\n'
          '**Document Source**: ${document.metadata['source']}\n'
          '**Document Snippet**: \n${document.pageContent}\n';
    });

    final docs = docsStrings.join('\n${PromptTemplates.separator}\n');
    //_logger.fine('Using documents: $docs');
    return docs;
  }

  /// Fallback chain (for when question is on other topics)
  RunnableSequence<InputDict, CitedAnswer> _fallbackChain() {
    return (Runnable.fromMap<InputDict>({
              'history': Runnable.getItemFromMap('history'),
              'question': Runnable.getItemFromMap('question'),
            }) |
            fallbackAnswerGenerationChainPrompt |
            chatModels.fastLLMWithTemp(temperature: 0.3))
        .pipe(const StringOutputParser())
        .pipe(Runnable.fromFunction(invoke: (String input, RunnableOptions? options) {
      return CitedAnswer(answer: input, citations: []);
    }));
  }

  /// Logs the output of a step
  Runnable<T, RunnableOptions, T> _logOutput<T extends Object>(String stepName) {
    return Runnable.mapInput((input) {
      _logger.info('Result from step "$stepName": $input');
      return input;
    });
  }
}

/// Convenience extension with typed getters.
extension on Map<String, dynamic> {
  QueryAnalysisResult get queryAnalysisResult => this['queryAnalysisResult'] as QueryAnalysisResult;

  List<Document> get docs => (this['docs'] ?? <Document>[]) as List<Document>;

  List<ChatMessage> get history => this['history'] as List<ChatMessage>;
}
