import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';

class ReadersScreen extends StatefulWidget {
  const ReadersScreen({super.key});

  @override
  State<ReadersScreen> createState() => _ReadersScreenState();
}

class _ReadersScreenState extends State<ReadersScreen> {
  List<Reader> _readers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<ReaderRepository>().findAll();
    setState(() {
      _readers = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/readers/new'),
            icon: const Icon(Icons.add),
            label: const Text('Новый читатель'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _readers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final r = _readers[idx];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.badge)),
                  title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${r.email} · ${r.phone}\nБилет: ${r.card.cardNumber}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context.go('/readers/${r.id}/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await context.read<ReaderRepository>().softDelete(r.id);
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
