import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<BookRepository>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/books')),
        title: const Text('Карточка книги'),
      ),
      body: FutureBuilder<Book?>(
        future: repo.findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snapshot.data;
          if (book == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Книга не найдена', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/books'),
                    child: const Text('К каталогу'),
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
                  Text(book.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('ISBN: ${book.isbn}', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Год издания: ${book.year}'),
                          const SizedBox(height: 8),
                          Text('Количество страниц: ${book.pages}'),
                          const SizedBox(height: 8),
                          Text('В наличии: ${book.copiesAvailable} из ${book.copiesTotal}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
