import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';

class AuthorDetailScreen extends StatelessWidget {
  const AuthorDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<AuthorRepository>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/authors')),
        title: const Text('Карточка автора'),
      ),
      body: FutureBuilder<Author?>(
        future: repo.findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final author = snapshot.data;
          if (author == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Автор не найден', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/authors'),
                    child: const Text('К списку авторов'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(author.fullName, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Страна: ${author.country}', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Год рождения: ${author.birthYear}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
