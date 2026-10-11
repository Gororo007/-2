import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _pagesController = TextEditingController(text: '300');

  int _publisherId = 1;
  int _genreId = 1;
  int _authorId = 1;

  Map<String, String> _serverErrors = {};
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (widget.id != null) {
        final book = await context.read<BookRepository>().findById(widget.id!);
        if (book != null) {
          _titleController.text = book.title;
          _isbnController.text = book.isbn;
          _yearController.text = book.year.toString();
          _pagesController.text = book.pages.toString();
          _publisherId = book.publisherId;
          if (book.genreIds.isNotEmpty) _genreId = book.genreIds.first;
          if (book.authorIds.isNotEmpty) _authorId = book.authorIds.first;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final book = Book(
        id: widget.id ?? 0,
        title: _titleController.text.trim(),
        isbn: _isbnController.text.trim(),
        year: int.tryParse(_yearController.text) ?? 2024,
        pages: int.tryParse(_pagesController.text) ?? 100,
        publisherId: _publisherId,
        authorIds: [_authorId],
        genreIds: [_genreId],
        copiesTotal: 5,
        copiesAvailable: 5,
      );

      final repo = context.read<BookRepository>();
      if (widget.id == null) {
        await repo.create(book);
      } else {
        await repo.update(book);
      }

      if (mounted) context.go('/books');
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Новая книга' : 'Редактирование книги'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      errorText: _serverErrors['title'],
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Укажите название'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      labelText: 'ISBN',
                      errorText: _serverErrors['isbn'],
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Укажите ISBN' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearController,
                          decoration:
                              const InputDecoration(labelText: 'Год издания'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _pagesController,
                          decoration:
                              const InputDecoration(labelText: 'Страниц'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _publisherId,
                    decoration:
                        const InputDecoration(labelText: 'Издательство'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Азбука')),
                      DropdownMenuItem(value: 2, child: Text('АСТ')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _publisherId = v);
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
