import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/genre.dart';
import '../repositories/genre_repository.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  List<Genre> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<GenreRepository>().findAll();
    setState(() {
      _genres = list;
      _isLoading = false;
    });
  }

  Future<void> _editGenre([Genre? genre]) async {
    final nameCtrl = TextEditingController(text: genre?.name ?? '');
    final descCtrl = TextEditingController(text: genre?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(genre == null ? 'Новый жанр' : 'Редактирование жанра'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название жанра *'),
                validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
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
      final repo = context.read<GenreRepository>();
      if (genre == null) {
        await repo.create(Genre(id: 0, name: nameCtrl.text.trim(), description: descCtrl.text.trim()));
      } else {
        await repo.update(genre.copyWith(name: nameCtrl.text.trim(), description: descCtrl.text.trim()));
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        actions: [
          FilledButton.icon(
            onPressed: () => _editGenre(),
            icon: const Icon(Icons.add),
            label: const Text('Добавить жанр'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _genres.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final g = _genres[idx];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.category)),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(g.description.isNotEmpty ? g.description : 'Без описания'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editGenre(g)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await context.read<GenreRepository>().softDelete(g.id);
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
