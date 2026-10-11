import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../screens/admin_users_screen.dart';
import '../screens/author_detail_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/circulation_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_loans_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/register_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_shell.dart';

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    redirect: (context, state) {
      if (!auth.isRestored) return null;

      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (loggedIn && isPublic) {
        return '/';
      }

      if (target.startsWith('/admin') && !auth.has(Role.admin)) {
        return '/forbidden';
      }
      if (target.startsWith('/circulation') && !auth.has(Role.librarian)) {
        return '/forbidden';
      }
      if (target.startsWith('/my-loans') && auth.user?.role != Role.reader) {
        return '/forbidden';
      }
      if (target == '/books/new' && !auth.has(Role.librarian)) {
        return '/forbidden';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
          GoRoute(
            path: '/books',
            builder: (c, s) => const BookListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const BookFormScreen()),
              GoRoute(
                path: ':id',
                builder: (c, s) => BookDetailScreen(
                    id: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
              ),
            ],
          ),
          GoRoute(
            path: '/authors',
            builder: (c, s) => const AuthorListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (c, s) => AuthorDetailScreen(
                    id: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
              ),
            ],
          ),
          GoRoute(path: '/my-loans', builder: (c, s) => const MyLoansScreen()),
          GoRoute(
              path: '/circulation',
              builder: (c, s) => const CirculationScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (c, s) => const AdminUsersScreen()),
        ],
      ),
    ],
  );
}
