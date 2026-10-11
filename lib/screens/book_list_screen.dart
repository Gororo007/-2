import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/breakpoints.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../state/book_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final queryText = params['search'] ?? '';
    if (queryText != _searchController.text) {
      _searchController.text = queryText;
    }

    final sortRaw = params['sort'] ?? 'title,asc';
    final sortParts = sortRaw.split(',');
    final sortField = sortParts[0];
    final sortAscending = sortParts.length > 1 ? sortParts[1] != 'desc' : true;

    final query = BookQuery(
      search: queryText,
      genreId: int.tryParse(params['genreId'] ?? ''),
      publisherId: int.tryParse(params['publisherId'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: sortField,
      sortAscending: sortAscending,
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      size: int.tryParse(params['size'] ?? '10') ?? 10,
      includeDeleted: params['deleted'] == 'true',
    );

    final notifier = context.read<BookListNotifier>();
    if (notifier.status == LoadStatus.idle || notifier.query != query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.applyQuery(query);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _applyFilters(search: value);
    });
  }

  void _applyFilters({
    String? search,
    int? genreId,
    bool resetGenre = false,
    int? publisherId,
    bool resetPublisher = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final notifier = context.read<BookListNotifier>();
    final current = notifier.query;

    final nextQuery = current.copyWith(
      search: search ?? current.search,
      genreId: resetGenre ? null : (genreId ?? current.genreId),
      publisherId: resetPublisher ? null : (publisherId ?? current.publisherId),
      sortField: sortField ?? current.sortField,
      sortAscending: sortAscending ?? current.sortAscending,
      page: page ??
          (search != null ||
                  genreId != null ||
                  resetGenre ||
                  publisherId != null ||
                  resetPublisher
              ? 1
              : current.page),
      size: size ?? current.size,
      includeDeleted: includeDeleted ?? current.includeDeleted,
    );

    final params = <String, String>{
      if (nextQuery.search.isNotEmpty) 'search': nextQuery.search,
      if (nextQuery.genreId != null) 'genreId': nextQuery.genreId.toString(),
      if (nextQuery.publisherId != null)
        'publisherId': nextQuery.publisherId.toString(),
      'sort':
          '${nextQuery.sortField},${nextQuery.sortAscending ? "asc" : "desc"}',
      'page': nextQuery.page.toString(),
      'size': nextQuery.size.toString(),
      if (nextQuery.includeDeleted) 'deleted': 'true',
    };

    context.replace(Uri(path: '/books', queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          // Кнопка добавления доступна библиотекарю и админу
          if (auth.has(Role.librarian))
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Добавить книгу'),
              onPressed: () => context.go('/books/new'),
            ),
          const SizedBox(width: 8),
          // Тумблер удаленных доступен только админу
          if (auth.has(Role.admin)) ...[
            Row(
              children: [
                const Text('Удалённые'),
                Switch(
                  value: notifier.query.includeDeleted,
                  onChanged: (val) => _applyFilters(includeDeleted: val),
                ),
              ],
            ),
          ],
          if (notifier.hasSelection && auth.has(Role.librarian))
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Удалить выбранные (${notifier.selected.length})',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Подтверждение'),
                    content: Text(
                        'Удалить выбранные книги (${notifier.selected.length} шт.)?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Отмена')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Удалить')),
                    ],
                  ),
                );
                if (confirm == true) await notifier.deleteSelected();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Поиск по названию или ISBN',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters(search: '');
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.idle ||
              LoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              LoadStatus.error => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(notifier.error ?? 'Ошибка'),
                      const SizedBox(height: 8),
                      FilledButton(
                          onPressed: notifier.load,
                          child: const Text('Повторить')),
                    ],
                  ),
                ),
              LoadStatus.success when notifier.result.items.isEmpty =>
                const Center(
                    child: Text('Книг по заданным критериям не найдено')),
              LoadStatus.success => isCompact
                  ? _buildCardList(context, notifier, auth)
                  : _buildTable(context, notifier, auth),
            },
          ),
          PaginationBar(
            page: notifier.query.page,
            size: notifier.query.size,
            totalPages: notifier.result.totalPages,
            total: notifier.result.total,
            onPageChanged: (p) => _applyFilters(page: p),
            onSizeChanged: (s) => _applyFilters(size: s, page: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
      BuildContext context, BookListNotifier notifier, AuthNotifier auth) {
    return EntityTable<Book>(
      items: notifier.result.items,
      idOf: (b) => b.id,
      selected: notifier.selected,
      onToggleSelect:
          auth.has(Role.librarian) ? notifier.toggleSelection : null,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: (field) {
        final asc = field == notifier.query.sortField
            ? !notifier.query.sortAscending
            : true;
        _applyFilters(sortField: field, sortAscending: asc);
      },
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'title',
          build: (b) => InkWell(
            onTap: () => context.go('/books/${b.id}'),
            child: Text(b.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TableColumnSpec(label: 'ISBN', build: (b) => Text(b.isbn)),
        TableColumnSpec(
            label: 'Год',
            sortField: 'year',
            numeric: true,
            build: (b) => Text('${b.year}')),
        TableColumnSpec(
            label: 'В наличии',
            numeric: true,
            build: (b) => Text('${b.copiesAvailable} / ${b.copiesTotal}')),
      ],
      actions: (b) => [
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: 'Карточка книги',
          onPressed: () => context.go('/books/${b.id}'),
        ),
        // Только админ видит восстановление
        if (b.isDeleted && auth.has(Role.admin))
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.green),
            tooltip: 'Восстановить',
            onPressed: () => notifier.restore(b.id),
          ),
        // Мягкое удаление видно библиотекарю и админу
        if (!b.isDeleted && auth.has(Role.librarian))
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить',
            onPressed: () => notifier.softDelete(b.id),
          ),
        // ПУНКТ 17: Кнопка физического удаления видна админу. Если читатель подменит роль в localStorage — кнопка появится, но сервер ответит 403!
        if (auth.has(Role.admin))
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Удалить навсегда (только Админ)',
            onPressed: () async {
              try {
                await notifier.deleteSelected();
              } on ApiException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.message), backgroundColor: Colors.red));
              }
            },
          ),
      ],
    );
  }

  Widget _buildCardList(
      BuildContext context, BookListNotifier notifier, AuthNotifier auth) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final b = notifier.result.items[index];
        return Card(
          child: ListTile(
            title: Text(b.title),
            subtitle: Text('ISBN: ${b.isbn} | Год: ${b.year}'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.go('/books/${b.id}'),
            ),
          ),
        );
      },
    );
  }
}
