import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CirculationScreen extends StatefulWidget {
  const CirculationScreen({super.key});

  @override
  State<CirculationScreen> createState() => _CirculationScreenState();
}

class _CirculationScreenState extends State<CirculationScreen> {
  List<dynamic> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/librarian/loans');
      if (mounted) setState(() => _loans = res.data as List);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выдача и возврат книг (Библиотекарь)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final l = _loans[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                    title: Text(l['bookTitle'] ?? 'Книга'),
                    subtitle: Text(
                        'Читатель ID: ${l['userId']} | Срок: ${l['dueDate']}'),
                    trailing: const Chip(label: Text('На руках')),
                  ),
                );
              },
            ),
    );
  }
}
