import 'package:collection/collection.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:logging/logging.dart';
import 'package:wanna_chat_server/ingestion/web_crawl_loader.dart';

enum IngestionType {
  textFile,
  webDocument,
  webCrawl,
  webCrawlIgnoreFragments,
}

class IngestionPipeline {
  // List of documents/web sites to ingest
  static const List<(IngestionType, String, String)> _documents = [
    // (IngestionType.textFile, './data/DartLangSpecDraft.txt', 'Dart'),, // TODO: Optionally download https://spec.dart.dev/DartLangSpecDraft.pdf and convert to text file
    (IngestionType.webCrawlIgnoreFragments, 'https://dart.dev/language', 'Dart'),
    (IngestionType.webDocument, 'https://dart.dev/null-safety', 'Dart'),
    (IngestionType.webDocument, 'https://dart.dev/resources/dart-cheatsheet', 'Dart'),
    (IngestionType.webCrawlIgnoreFragments, 'https://dart.dev/effective-dart', 'Dart'),
    (IngestionType.webCrawlIgnoreFragments, 'https://dart.dev/libraries', 'Dart'),
    (IngestionType.webCrawlIgnoreFragments, 'https://dart.dev/tutorials', 'Dart'),
    (IngestionType.webCrawl, 'https://langchaindart.dev/#/', 'LangChain.dart'),
  ];

  static final Logger _logger = Logger('IngestionPipeline');

  IngestionPipeline({required this.vectorStore});

  final VectorStore vectorStore;

  // Setup document retrieval chain

  Future<List<Document>> _loadAndSplitDocument({
    required HeadlessBrowser browser,
    required IngestionType type,
    required String path,
    required String topic,
    required TextSplitter splitter,
  }) async {
    _logger.fine('Loading and splitting $type "$path" ...');
    final pages = switch (type) {
      IngestionType.webCrawlIgnoreFragments =>
        await WebCrawlLoader(rootUrl: path, browser: browser, ignoreFragments: true).load(),
      IngestionType.webCrawl => await WebCrawlLoader(rootUrl: path, browser: browser).load(),
      IngestionType.webDocument => await WebBaseLoader([path]).load(),
      IngestionType.textFile => await TextLoader(path).load(),
    };
    final chunks = splitter.splitDocuments(pages);
    _logger.fine('No. of splits for $path: ${chunks.length}');
    return chunks
        .mapIndexed(
          (i, d) => d.copyWith(
            metadata: {
              ...d.metadata,
              'topic': topic,
            },
          ),
        )
        .toList(growable: false);
  }

  Future<VectorStore> loadData() async {
    final HeadlessBrowser browser = await HeadlessBrowser.instance();

    final results = await vectorStore.similaritySearch(query: 'any');

    if (results.isNotEmpty) {
      _logger.info('Data already loaded - skipping ingest');
    } else {
      _logger.info('Loading and splitting documents (${_documents.length})...');
      const textSplitter = RecursiveCharacterTextSplitter(chunkSize: 1536, chunkOverlap: 128);
      for (final docInfo in _documents) {
        final List<Document> splits = await _loadAndSplitDocument(
            browser: browser, type: docInfo.$1, path: docInfo.$2, topic: docInfo.$3, splitter: textSplitter);
        await vectorStore.addDocuments(documents: splits);
        _logger.info('Added ${splits.length} splits');
      }
      _logger.info('Done loading and splitting documents');

      browser.dispose();
    }

    return vectorStore;
  }
}
