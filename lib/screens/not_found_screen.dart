import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('404: Страница не найдена', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Адрес $location не существует'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/books'),
              child: const Text('К каталогу книг'),
            ),
          ],
        ),
      ),
    );
  }
}
