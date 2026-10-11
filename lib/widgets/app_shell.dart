import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final size = screenSizeOf(context);
    final location = GoRouterState.of(context).uri.path;

    // Меню формируется динамически в зависимости от роли!
    final destinations = <({IconData icon, String label, String path})>[
      (icon: Icons.dashboard, label: 'Главная', path: '/'),
      (icon: Icons.menu_book, label: 'Книги', path: '/books'),
      (icon: Icons.person, label: 'Авторы', path: '/authors'),
      if (user?.role == Role.reader)
        (icon: Icons.bookmark, label: 'Мои выдачи', path: '/my-loans'),
      if (auth.has(Role.librarian))
        (icon: Icons.swap_horiz, label: 'Выдача/Возврат', path: '/circulation'),
      if (auth.has(Role.admin))
        (
          icon: Icons.admin_panel_settings,
          label: 'Пользователи',
          path: '/admin/users'
        ),
    ];

    int selectedIndex = destinations.indexWhere((d) => d.path == location);
    if (selectedIndex == -1) selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотечная система'),
        actions: [
          if (user != null) ...[
            Chip(
              avatar: const Icon(Icons.account_circle, size: 18),
              label: Text('${user.fullName} (${user.role.title})'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти из системы',
              onPressed: () => auth.logout(),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Row(
        children: [
          if (size != ScreenSize.compact) ...[
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) =>
                  context.go(destinations[idx].path),
              extended: size == ScreenSize.expanded,
              labelType: size == ScreenSize.expanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                      icon: Icon(d.icon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: size == ScreenSize.compact
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) =>
                  context.go(destinations[idx].path),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            )
          : null,
    );
  }
}
