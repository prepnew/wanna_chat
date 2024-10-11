import 'package:langchain/langchain.dart';

class PromptTemplates {
  // ** Configuration (of role/area of expertise etc) **

  static const String _domainKnowledge = 'the Dart programming language and the framework LangChain.dart';
  static const String _domainKnowledgeBullets = '''
- "The Dart programming language"
- "The framework LangChain.dart"
''';

  static const String _responseStylePersona = 'Erlich Bachman from the TV series "Silicon Valley"';

  // ** Welcome message **

  static const String welcomeMessage =
      'Hello **{name}**! I am a friendly AI bot, expert in $_domainKnowledge and happy to teach you everything I know - go ahead and ask me a question!';

  // ** Prompt templates **

  static const separator = '~~~~~';

  static const String rewriteQueryPromptTemplate = '''
You are an AI assistant tasked with reformulating user messages into standalone questions, when needed. 
Given any previous conversation history, reformulate the user message into a standalone question, 
if (and ONLY if) it includes references to the previous conversation. 

# Further instructions
- NEVER answer the user message, simply reformulate it if needed.
- NEVER make up information that isn't part of previous conversation history.
- If the user message is a statement or ending word, return it UNCHANGED. 
- If the user message is already a standalone query, return it UNCHANGED. 
- If the user message is NOT referring to previous history, return it UNCHANGED. 
- If the user message is NOT a question, return it UNCHANGED. 
- DO NOT include explicit references to previous discussion (e.g. "...based on our previous discussion").
- Reformulate the user message into a standalone message.
''';

  static const String queryAnalysisSystemPromptTemplate =
      'You are an AI assistant tasked with determining if a user query is related to the topics of documents stored '
      'in a RAG system / vector store. If it is related, you will rephrase the user query into a Vector Store Query, '
      'that is more specific, compact, and likely to retrieve relevant information in a vector similarity search. \n\n'
      'Additional assistant instructions:\n'
      ' - Do NOT answer the user query, just attempt to rephrase it into a Vector Store Query if needed.\n'
      ' - A Vector Store Query should ONLY be created if the user query is directly related to the Vector Store Document '
      'Topics.\n'
      ' - The Vector Store Query must be in the original language of the user query.\n'
      ' - Strip out information that is not relevant for the retrieval task from the Vector Store Query.\n\n\n'
      '## Vector Store Document Topics:\n'
      '$_domainKnowledgeBullets\n\n'
      '## Result:\n'
      'Now, determine if the user query matches the Vector Store Document Topics, and if so, what is the '
      'rephrased Vector Store Query?\n';

  static const String finalRAGAnswerSystemPromptTemplate = '''
You are an AI assistant tasked with answering questions about $_domainKnowledge, based on only on a set of provided 
documents. Be concise and stick to the subject. If you don't know the answer, just say that you don't know, don't try to 
make up an answer. You will respond in the style of $_responseStylePersona. 

Your task is to answer the question and identify and extract the exact inline quotes from the provided documents that 
directly correspond to the content used to generate the answer. The extracted quotes must be verbatim passages from 
the document snippets, ensuring a word-for-word match with the text in the provided documents. Keep the quotes as short 
as possible.

Each document consists of these fields:
- **Document Title**: The title (if any) of the original document.
- **Document Topic**: The topic or category or the original document.
- **Document Source**: The URL or file name of the original document.
- **Document Snippet**: A snippet from the source document, relevant to the current user search query.

Use the following documents to answer the question: 
{context}"
''';

  static const String fallbackAnswerSystemPromptTemplate = '''
You are an AI assistant, excellent at giving helpful advice based on the conversation history.  

When responding, do it in the style of $_responseStylePersona.
''';

  static const String questionPromptTemplate = '{question}';

  static const analyzeQueryTool = ToolSpec(
    name: 'QueryAnalysisResult',
    description: 'Determine if the user query matches any of the Vector Store Document Topics '
        "(reflected by property 'matchesVectorStoreTopics'). If this is the case, the user query "
        "should be rephrased into a standalone Vector Store Query (property 'vectorStoreQuery') for use in "
        "Vector similarity searches and retrieval",
    inputJsonSchema: {
      "type": "object",
      "properties": {
        "matchesVectorStoreTopics": {
          "description": "A value of 'true' if, and ONLY if, the user query matches any of the Vector Store "
              "Document Topics. Set this property to 'false' if user query doesn't match the topics.",
          "type": "boolean"
        },
        "vectorStoreQuery": {
          "description": "A standalone Vector Store Query, rephrased from the user query. "
              "If the user query is NOT related to the Vector Store Document Topics "
              "('matchesVectorStoreTopics' is 'false'), this property should be an empty string.",
          "type": "string"
        }
      },
      "required": ["matchesVectorStoreTopics", "vectorStoreQuery"]
    },
  );

  static const citedAnswerTool = ToolSpec(
    name: 'CitedAnswer',
    description: "Answer the user's question based only on the given documents, and provide the sources and "
        "verbatim quotes used to answer the question.",
    inputJsonSchema: {
      'type': 'object',
      'properties': {
        'answer': {
          'description': "The answer to the user's question, which is based on the given documents.",
          'type': "string"
        },
        'citations': {
          'description': "List of specific sources and quotes used to answer the question.",
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'source': {
                'description': "Source used to answers the question.",
                'type': 'string',
              },
              'quote': {
                'description': "A short verbatim quote from a document snippet used to answers the question.",
                'type': 'string',
              },
            },
            'required': ['source', 'quote'],
          }
        },
      },
      'required': ['answer', 'citations']
    },
  );
}

/// Rephrase question prompt
final rewriteQueryPrompt = ChatPromptTemplate.fromTemplates(const [
  (ChatMessageType.system, PromptTemplates.rewriteQueryPromptTemplate),
  (ChatMessageType.messagesPlaceholder, 'history'),
  (ChatMessageType.human, PromptTemplates.questionPromptTemplate),
]);

/// Query analysis question prompt
final queryAnalysisPrompt = ChatPromptTemplate.fromTemplates(const [
  (ChatMessageType.system, PromptTemplates.queryAnalysisSystemPromptTemplate),
  (ChatMessageType.human, PromptTemplates.questionPromptTemplate),
]);

/// RAG answer generation prompt
final ragAnswerGenerationChainPrompt = ChatPromptTemplate.fromTemplates(const [
  (ChatMessageType.system, PromptTemplates.finalRAGAnswerSystemPromptTemplate),
  (ChatMessageType.messagesPlaceholder, 'history'),
  (ChatMessageType.human, PromptTemplates.questionPromptTemplate),
]);

/// Direct LLM answer generation prompt
final fallbackAnswerGenerationChainPrompt = ChatPromptTemplate.fromTemplates(const [
  (ChatMessageType.system, PromptTemplates.fallbackAnswerSystemPromptTemplate),
  (ChatMessageType.messagesPlaceholder, 'history'),
  (ChatMessageType.human, PromptTemplates.questionPromptTemplate),
]);
