import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  List<dynamic> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/reader/loans');
      if (mounted) setState(() => _loans = res.data as List);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _extend(int id) async {
    try {
      final dio = context.read<Dio>();
      await dio.post('/reader/loans/$id/extend');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Срок возврата успешно продлён до 15.11.2026')));
      _loadLoans();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка продления: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои выдачи (Читатель)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? const Center(child: Text('У вас нет активных выдач'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loans.length,
                  itemBuilder: (context, index) {
                    final item = _loans[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.book, color: Colors.indigo),
                        title: Text(item['bookTitle'] ?? 'Книга'),
                        subtitle: Text(
                            'Дата выдачи: ${item['issueDate']} | Вернуть до: ${item['dueDate']}'),
                        trailing: FilledButton.tonal(
                          onPressed: () => _extend(item['id']),
                          child: const Text('Продлить срок'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
