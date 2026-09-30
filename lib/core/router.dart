import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/author_detail_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/not_found_screen.dart';
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
              path: ':id',
              name: 'book_detail',
              builder: (context, state) => BookDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
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
              path: ':id',
              name: 'author_detail',
              builder: (context, state) => AuthorDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
