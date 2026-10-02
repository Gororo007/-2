import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:library_system/models/author_query.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../state/book_list_notifier.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _copiesTotalController = TextEditingController(text: '1');
  final _copiesAvailableController = TextEditingController(text: '1');

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  List<Publisher> _publishers = [];
  List<Author> _authors = [];
  List<Genre> _genres = [];

  bool _isLoading = true;
  bool _isDirty = false;
  String? _serverIsbnError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pubRepo = context.read<PublisherRepository>();
    final authorRepo = context.read<AuthorRepository>();
    final genreRepo = context.read<GenreRepository>();
    final bookRepo = context.read<BookRepository>();

    _publishers = await pubRepo.findAll();
    final authorsRes = await authorRepo.find(const AuthorQuery(size: 100));
    _authors = authorsRes.items;
    _genres = await genreRepo.findAll();

    if (widget.isEditing) {
      final book = await bookRepo.findById(widget.id!);
      if (book != null) {
        _titleController.text = book.title;
        _isbnController.text = book.isbn;
        _yearController.text = book.year.toString();
        _pagesController.text = book.pages.toString();
        _copiesTotalController.text = book.copiesTotal.toString();
        _copiesAvailableController.text = book.copiesAvailable.toString();
        _publisherId = book.publisherId;
        _authorIds = [...book.authorIds];
        _genreIds = [...book.genreIds];
      }
    } else {
      if (_publishers.isNotEmpty) _publisherId = _publishers.first.id;
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
    setState(() => _serverIsbnError = null);
    if (!_formKey.currentState!.validate()) return;

    final bookRepo = context.read<BookRepository>();
    final book = Book(
      id: widget.id ?? 0,
      title: _titleController.text.trim(),
      isbn: _isbnController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      pages: int.parse(_pagesController.text.trim()),
      publisherId: _publisherId!,
      authorIds: _authorIds,
      genreIds: _genreIds,
      copiesTotal: int.parse(_copiesTotalController.text.trim()),
      copiesAvailable: int.parse(_copiesAvailableController.text.trim()),
    );

    try {
      if (widget.isEditing) {
        await bookRepo.update(book);
      } else {
        await bookRepo.create(book);
      }
      _isDirty = false;
      if (mounted) {
        context.read<BookListNotifier>().load();
        context.go('/books');
      }
    } catch (e) {
      setState(() => _serverIsbnError = e.toString().replaceAll('StateError: ', ''));
      _formKey.currentState!.validate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _onWillPop();
        if (leave && context.mounted) context.go('/books');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () async {
            if (await _onWillPop() && context.mounted) context.go('/books');
          }),
          title: Text(widget.isEditing ? 'Редактирование книги' : 'Новая книга'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Название книги *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 200)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _isbnController,
                      decoration: const InputDecoration(labelText: 'ISBN *', border: OutlineInputBorder()),
                      onChanged: (_) {
                        _markDirty();
                        if (_serverIsbnError != null) setState(() => _serverIsbnError = null);
                      },
                      validator: (val) {
                        final local = V.combine([V.required(), V.length(min: 10, max: 20)])(val);
                        if (local != null) return local;
                        return _serverIsbnError;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Год издания *', border: OutlineInputBorder()),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([V.required(), V.integer(min: 1450, max: 2100)]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pagesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Кол-во страниц *', border: OutlineInputBorder()),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([V.required(), V.integer(min: 1, max: 10000)]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Связь многие к одному: Выпадающий список
                    DropdownButtonFormField<int>(
                      initialValue: _publisherId,
                      decoration: const InputDecoration(labelText: 'Издательство (многие к одному) *', border: OutlineInputBorder()),
                      items: _publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (val) {
                        _markDirty();
                        setState(() => _publisherId = val);
                      },
                      validator: (val) => val == null ? 'Выберите издательство' : null,
                    ),
                    const SizedBox(height: 16),
                    // Связь многие ко многим: Авторы
                    FormField<List<int>>(
                      initialValue: _authorIds,
                      validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы одного автора' : null,
                      builder: (state) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Авторы (многие ко многим) *',
                            border: const OutlineInputBorder(),
                            errorText: state.errorText,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _authors.map((a) {
                              final sel = _authorIds.contains(a.id);
                              return FilterChip(
                                label: Text(a.fullName),
                                selected: sel,
                                onSelected: (_) {
                                  _markDirty();
                                  final next = [..._authorIds];
                                  sel ? next.remove(a.id) : next.add(a.id);
                                  state.didChange(next);
                                  setState(() => _authorIds = next);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Связь многие ко многим: Жанры
                    FormField<List<int>>(
                      initialValue: _genreIds,
                      validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы один жанр' : null,
                      builder: (state) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Жанры (многие ко многим) *',
                            border: const OutlineInputBorder(),
                            errorText: state.errorText,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genres.map((g) {
                              final sel = _genreIds.contains(g.id);
                              return FilterChip(
                                label: Text(g.name),
                                selected: sel,
                                onSelected: (_) {
                                  _markDirty();
                                  final next = [..._genreIds];
                                  sel ? next.remove(g.id) : next.add(g.id);
                                  state.didChange(next);
                                  setState(() => _genreIds = next);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _copiesTotalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Всего экземпляров *', border: OutlineInputBorder()),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([V.required(), V.integer(min: 0, max: 1000)]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _copiesAvailableController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'В наличии *', border: OutlineInputBorder()),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([V.required(), V.integer(min: 0, max: 1000)]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать книгу'),
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
