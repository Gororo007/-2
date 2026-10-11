import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Добро пожаловать, ${user?.fullName ?? "Пользователь"}!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Ваша роль в системе: ${user?.role.title ?? "Гость"}',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ActionCard(
                icon: Icons.menu_book,
                title: 'Каталог книг',
                subtitle: 'Поиск и фильтрация доступных изданий',
                onTap: () => context.go('/books'),
              ),
              if (user?.role == Role.reader)
                _ActionCard(
                  icon: Icons.bookmark,
                  title: 'Мои выдачи',
                  subtitle: 'Просмотр книг на руках и продление срока',
                  onTap: () => context.go('/my-loans'),
                ),
              if (auth.has(Role.librarian))
                _ActionCard(
                  icon: Icons.swap_horiz,
                  title: 'Выдача и возврат',
                  subtitle: 'Управление операциями выдачи книг читателям',
                  onTap: () => context.go('/circulation'),
                ),
              if (auth.has(Role.admin))
                _ActionCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Управление правами',
                  subtitle: 'Администрирование пользователей и ролей',
                  onTap: () => context.go('/admin/users'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    size: 36, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
