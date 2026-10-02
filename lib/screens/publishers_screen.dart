import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';

class PublishersScreen extends StatefulWidget {
  const PublishersScreen({super.key});

  @override
  State<PublishersScreen> createState() => _PublishersScreenState();
}

class _PublishersScreenState extends State<PublishersScreen> {
  List<Publisher> _publishers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<PublisherRepository>().findAll();
    setState(() {
      _publishers = list;
      _isLoading = false;
    });
  }

  Future<void> _editPublisher([Publisher? publisher]) async {
    final nameCtrl = TextEditingController(text: publisher?.name ?? '');
    final cityCtrl = TextEditingController(text: publisher?.city ?? '');
    final webCtrl = TextEditingController(text: publisher?.website ?? '');
    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(publisher == null ? 'Новое издательство' : 'Редактирование издательства'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название *'),
                validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Город')),
              const SizedBox(height: 12),
              TextFormField(controller: webCtrl, decoration: const InputDecoration(labelText: 'Веб-сайт')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (res == true) {
      final repo = context.read<PublisherRepository>();
      if (publisher == null) {
        await repo.create(Publisher(id: 0, name: nameCtrl.text.trim(), city: cityCtrl.text.trim(), website: webCtrl.text.trim()));
      } else {
        await repo.update(publisher.copyWith(name: nameCtrl.text.trim(), city: cityCtrl.text.trim(), website: webCtrl.text.trim()));
      }
      _load();
    }
  }

  Future<void> _deletePublisher(Publisher p) async {
    try {
      await context.read<PublisherRepository>().deleteWithCheck(p.id);
      _load();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Отказ в удалении'),
            content: Text(e.toString().replaceAll('StateError: ', '')),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        actions: [
          FilledButton.icon(
            onPressed: () => _editPublisher(),
            icon: const Icon(Icons.add),
            label: const Text('Добавить издательство'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _publishers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final p = _publishers[idx];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${p.city} · ${p.website}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editPublisher(p)),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deletePublisher(p)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
