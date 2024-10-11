# Wanna Chat - A Flutter / Dart chat app, using LangChain.dart

![Wanna chat](/frontend/assets/banner.png)

This is a small demo project that implements LLM-based chat functionality, augmented with real data (also known 
as [RAG](https://blogs.nvidia.com/blog/what-is-retrieval-augmented-generation/)), to give more factually correct answers. The default implementation uses data about the Dart language 
and the [LangChain.dart](https://langchaindart.com) framework, in the form scraped web pages.

This projects consists of two parts: a `Dart` based chat backend and a frontend app written in `Flutter` & `Dart`. 

## Backend server (Dart "LLM app")
A simple **LLM app** that implements **RAG** functionality, using the framework **[LangChain.dart](https://langchaindart.com)**.

The backend provides a simple REST api, exposing three endpoints:
* GET /chat/{sessionId} - Gets the chat history
* POST /chat/{sessionId} - Ask a questions
* DELETE /chat/{sessionId} - Clears the conversation

To keep the backend as simple and lightweight as possible it was build using **[Shelf](https://pub.dev/packages/shelf)**. 
More complex real-world applications might consider using something like [Dart Frog](https://dartfrog.vgv.dev) or [ServerPod](https://serverpod.dev).

### Vector store
The server uses [ObjectBox](https://objectbox.io) as vector store, with an option to use [Supabase](https://supabase.io).

### Ingestion
For scraping and loading web pages and crawling entire websites, the server uses the [puppeteer](https://pub.dev/packages/puppeteer) 
package, complemented with the [beautiful_soup](https://pub.dev/packages/beautiful_soup_dart) package for parsing the 
HTML.

### Running the backend server

* Set the `OPENAI_API_KEY` environment variable.
* Run the server locally using ```dart_frog dev```

See [backend/README.md](backend/README.md) for more details.

## Frontend (Flutter app)

A simple Flutter app implementing a basic chat interface, with history. The [ResultNotifier](https://pub.dev/packages/result_notifier) package is used for 
state management and more.

## Data

The ingestion pipeline is setup by default to load web documents from the [Dart](https://dart.dev) and 
[LandChain.dart](http://langchaindart.dev) websites.
