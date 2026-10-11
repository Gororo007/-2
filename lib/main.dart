import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/inactivity_watcher.dart';
import 'core/router.dart';
import 'repositories/api_auth_repository.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'state/auth_notifier.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        // Auth API & Notifier
        Provider<AuthRepository>(
          create: (_) => ApiAuthRepository(buildDio()),
        ),
        ChangeNotifierProvider<AuthNotifier>(
          create: (context) => AuthNotifier(
            context.read<SharedPreferences>(),
            context.read<AuthRepository>(),
          )..restore(),
        ),
        // HTTP-клиент с интерсептором токенов
        ProxyProvider<AuthNotifier, Dio>(
          update: (_, auth, __) => buildDio(authNotifier: auth),
        ),
        // Репозитории поверх API
        ProxyProvider<Dio, BookRepository>(
          update: (_, dio, __) => ApiBookRepository(dio),
        ),
        ProxyProvider<Dio, AuthorRepository>(
          update: (_, dio, __) => ApiAuthorRepository(dio),
        ),
        // Состояние экранов
        ChangeNotifierProxyProvider<BookRepository, BookListNotifier>(
          create: (context) => BookListNotifier(context.read<BookRepository>()),
          update: (_, repo, prev) => prev ?? BookListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<AuthorRepository, AuthorListNotifier>(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>()),
          update: (_, repo, prev) => prev ?? AuthorListNotifier(repo),
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
    final auth = context.watch<AuthNotifier>();
    final router = buildRouter(auth);

    return InactivityWatcher(
      timeout: const Duration(minutes: 3),
      warningThreshold: const Duration(seconds: 30),
      onTimeout: () => auth.logout(),
      child: MaterialApp.router(
        title: 'Библиотечная система',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        routerConfig: router,
      ),
    );
  }
}
