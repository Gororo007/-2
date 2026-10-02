import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _birthYearController = TextEditingController();

  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<AuthorRepository>();
      final author = await repo.findById(widget.id!);
      if (author != null) {
        _firstNameController.text = author.firstName;
        _lastNameController.text = author.lastName;
        _countryController.text = author.country;
        _birthYearController.text = author.birthYear.toString();
      }
    }
    setState(() => _isLoading = false);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Вы уверены, что хотите уйти? Все несохранённые данные будут потеряны.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AuthorRepository>();
    final author = Author(
      id: widget.id ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _countryController.text.trim(),
      birthYear: int.parse(_birthYearController.text.trim()),
    );

    if (widget.isEditing) {
      await repo.update(author);
    } else {
      await repo.create(author);
    }
    _isDirty = false;
    if (mounted) {
      context.read<AuthorListNotifier>().load();
      context.go('/authors');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _onWillPop();
        if (leave && context.mounted) context.go('/authors');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () async {
            if (await _onWillPop() && context.mounted) context.go('/authors');
          }),
          title: Text(widget.isEditing ? 'Редактирование автора' : 'Новый автор'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Фамилия *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'Имя *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Страна *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Год рождения *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.integer(min: 0, max: 2100)]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать автора'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
