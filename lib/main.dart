import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'repositories/persistent_reader_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  final bookRepo = PersistentBookRepository(prefs);
  final authorRepo = PersistentAuthorRepository(prefs);
  final genreRepo = PersistentGenreRepository(prefs);
  final publisherRepo = PersistentPublisherRepository(prefs, bookRepo);
  final readerRepo = PersistentReaderRepository(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>.value(value: bookRepo),
        Provider<AuthorRepository>.value(value: authorRepo),
        Provider<GenreRepository>.value(value: genreRepo),
        Provider<PublisherRepository>.value(value: publisherRepo),
        Provider<ReaderRepository>.value(value: readerRepo),
        ChangeNotifierProvider(
          create: (context) => BookListNotifier(context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthorListNotifier(context.read<AuthorRepository>()),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотечная система',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      routerConfig: appRouter,
    );
  }
}
