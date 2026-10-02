import 'package:go_router/go_router.dart';

import '../screens/author_detail_screen.dart';
import '../screens/author_form_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/genres_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/publishers_screen.dart';
import '../screens/reader_form_screen.dart';
import '../screens/readers_screen.dart';
import '../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/books',
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/books',
          name: 'books',
          builder: (context, state) => const BookListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const BookFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => BookDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => BookFormScreen(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/authors',
          name: 'authors',
          builder: (context, state) => const AuthorListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AuthorFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => AuthorDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => AuthorFormScreen(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/genres',
          name: 'genres',
          builder: (context, state) => const GenresScreen(),
        ),
        GoRoute(
          path: '/publishers',
          name: 'publishers',
          builder: (context, state) => const PublishersScreen(),
        ),
        GoRoute(
          path: '/readers',
          name: 'readers',
          builder: (context, state) => const ReadersScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ReaderFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => ReaderFormScreen(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
