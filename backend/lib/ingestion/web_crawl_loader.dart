import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:langchain/langchain.dart';
import 'package:logging/logging.dart';
import 'package:puppeteer/puppeteer.dart';

class HeadlessBrowser {
  HeadlessBrowser._(Browser browser) : _browser = browser;

  static Future<HeadlessBrowser> instance() async {
    return HeadlessBrowser._(await puppeteer.launch());
  }

  void dispose() {
    _browser.close();
  }

  final Browser _browser;

  Future<String> loadContent(String url) async {
    final page = await _browser.newPage();
    await page.goto(url, wait: Until.networkAlmostIdle);
    return await page.content ?? '';
  }
}

/// Modified version of the WebBaseLoader from langchain_core.
class WebCrawlLoader extends BaseDocumentLoader {
  WebCrawlLoader({
    required this.rootUrl,
    required this.browser,
    this.ignoreFragments = false,
  }) : _parsedPages = {} {
    _rootUri = Uri.parse(rootUrl);
    _baseUri = Uri(scheme: _rootUri.scheme, host: _rootUri.host, port: _rootUri.port, userInfo: _rootUri.userInfo);
  }

  final Logger _logger = Logger('DeepWebLoader');

  final String rootUrl;
  late final Uri _rootUri;
  late final Uri _baseUri;

  final bool ignoreFragments;

  final HeadlessBrowser browser;

  final Set<Uri> _parsedPages;

  @override
  Stream<Document> lazyLoad() async* {
    Set<Uri> remainingLinks = {Uri.parse(rootUrl)};
    while (remainingLinks.isNotEmpty) {
      final Set<Uri> updatedRemainingLinks = {};
      for (final uri in remainingLinks) {
        final docAndLinks = await _scrape(uri);
        if (docAndLinks != null) {
          yield docAndLinks.$1;
          updatedRemainingLinks.addAll(docAndLinks.$2);
        }
      }

      remainingLinks = updatedRemainingLinks.difference(_parsedPages);
      _logger.info('Remaining pages: ${remainingLinks.length}');
    }
    _logger.info('Done loading ${_parsedPages.length} pages');
  }

  Future<(Document, Iterable<Uri>)?> _scrape(Uri uri) async {
    _logger.info('Scraping: $uri');
    final html = await _fetchUrl(uri.toString());
    _parsedPages.add(uri);

    final soup = BeautifulSoup(html);
    final body = soup.body!;
    body.findAll('style').forEach((element) => element.extract());
    body.findAll('script').forEach((element) => element.extract());

    final links = body.findAll('a').map((e) => Uri.tryParse(e.extract()['href'] ?? '')).nonNulls;
    var sameDomainLinks = links.where((e) => e.hasAuthority).where((e) => e.host == uri.host).toSet();
    final domainRelativeLinks = links
        .where((e) => !e.hasAuthority)
        .map((e) =>
            e.replace(scheme: _baseUri.scheme, host: _baseUri.host, port: _baseUri.port, userInfo: _baseUri.userInfo))
        .toSet();
    sameDomainLinks.addAll(domainRelativeLinks);
    if (!_rootUri.hasEmptyPath && _rootUri.path != '/') {
      sameDomainLinks = sameDomainLinks.where((e) => e.path.startsWith(_rootUri.path)).toSet();
    }
    if (ignoreFragments) {
      sameDomainLinks = sameDomainLinks.map((e) => e.hasFragment ? e.replace(fragment: '') : e).toSet();
    }

    final content = body.getText(strip: true);
    return (
      Document(
        pageContent: content,
        metadata: _buildMetadata(uri.toString(), soup),
      ),
      sameDomainLinks
    );
  }

  Future<String> _fetchUrl(String url) async {
    return await browser.loadContent(url);
  }

  Map<String, dynamic> _buildMetadata(
    String url,
    BeautifulSoup soup,
  ) {
    final title = soup.title;
    final description = soup.find(
      'meta',
      attrs: {'name': 'description'},
    )?.getAttrValue('content');
    final language = soup.find('html')?.getAttrValue('lang');
    return {
      'source': url,
      if (title != null) 'title': title.text,
      if (description != null) 'description': description.trim(),
      if (language != null) 'language': language,
    };
  }
}
