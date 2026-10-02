import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();

  bool _isLoading = true;
  bool _isDirty = false;
  String? _serverEmailError;
  int _cardId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<ReaderRepository>();
      final reader = await repo.findById(widget.id!);
      if (reader != null) {
        _nameController.text = reader.fullName;
        _emailController.text = reader.email;
        _phoneController.text = reader.phone;
        _cardNumberController.text = reader.card.cardNumber;
        _cardId = reader.card.id;
      }
    } else {
      _cardNumberController.text = 'CARD-${DateTime.now().millisecondsSinceEpoch % 10000}';
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
    setState(() => _serverEmailError = null);
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ReaderRepository>();
    final card = LibraryCard(
      id: _cardId,
      cardNumber: _cardNumberController.text.trim(),
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );

    final reader = Reader(
      id: widget.id ?? 0,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      card: card,
    );

    try {
      if (widget.isEditing) {
        await repo.update(reader);
      } else {
        await repo.create(reader);
      }
      _isDirty = false;
      if (mounted) context.go('/readers');
    } catch (e) {
      setState(() => _serverEmailError = e.toString().replaceAll('StateError: ', ''));
      _formKey.currentState!.validate();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
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
        if (leave && context.mounted) context.go('/readers');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () async {
            if (await _onWillPop() && context.mounted) context.go('/readers');
          }),
          title: Text(widget.isEditing ? 'Редактирование читателя' : 'Новый читатель'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'ФИО читателя *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 3, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                      onChanged: (_) {
                        _markDirty();
                        if (_serverEmailError != null) setState(() => _serverEmailError = null);
                      },
                      validator: (val) {
                        final local = V.combine([V.required(), V.email()])(val);
                        if (local != null) return local;
                        return _serverEmailError;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Телефон *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 6, max: 20)]),
                    ),
                    const SizedBox(height: 24),
                    // Связь один к одному: вложенный читательский билет
                    Text('Читательский билет (связь один к одному)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _cardNumberController,
                          decoration: const InputDecoration(labelText: 'Номер билета *', border: OutlineInputBorder()),
                          onChanged: (_) => _markDirty(),
                          validator: V.combine([V.required(), V.length(min: 4, max: 30)]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать читателя'),
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
