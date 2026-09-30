import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
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

    final query = AuthorQuery(
      search: queryText,
      country: params['country'],
      sortField: params['sortField'] ?? 'lastName',
      sortAscending: params['sortAscending'] != 'false',
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      size: int.tryParse(params['size'] ?? '10') ?? 10,
      includeDeleted: params['deleted'] == 'true',
    );

    final notifier = context.read<AuthorListNotifier>();
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
    String? country,
    bool resetCountry = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final notifier = context.read<AuthorListNotifier>();
    final current = notifier.query;

    final nextQuery = current.copyWith(
      search: search ?? current.search,
      country: resetCountry ? null : (country ?? current.country),
      sortField: sortField ?? current.sortField,
      sortAscending: sortAscending ?? current.sortAscending,
      page: page ?? (search != null || country != null || resetCountry ? 1 : current.page),
      size: size ?? current.size,
      includeDeleted: includeDeleted ?? current.includeDeleted,
    );

    final params = <String, String>{
      if (nextQuery.search.isNotEmpty) 'search': nextQuery.search,
      if (nextQuery.country != null && nextQuery.country!.isNotEmpty) 'country': nextQuery.country!,
      'sortField': nextQuery.sortField,
      'sortAscending': nextQuery.sortAscending.toString(),
      'page': nextQuery.page.toString(),
      'size': nextQuery.size.toString(),
      if (nextQuery.includeDeleted) 'deleted': 'true',
    };

    context.replace(Uri(path: '/authors', queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог авторов'),
        actions: [
          Row(
            children: [
              const Text('Удалённые'),
              Switch(
                value: notifier.query.includeDeleted,
                onChanged: (val) => _applyFilters(includeDeleted: val),
              ),
            ],
          ),
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Удалить выбранных (${notifier.selected.length})',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Подтверждение'),
                    content: Text('Удалить выбранных авторов (${notifier.selected.length} чел.)?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
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
                      hintText: 'Поиск по фамилии или стране',
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
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Страна'),
                    value: notifier.query.country,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все страны')),
                      DropdownMenuItem(value: 'Россия', child: Text('Россия')),
                      DropdownMenuItem(value: 'Великобритания', child: Text('Великобритания')),
                      DropdownMenuItem(value: 'США', child: Text('США')),
                      DropdownMenuItem(value: 'Германия', child: Text('Германия')),
                      DropdownMenuItem(value: 'Колумбия', child: Text('Колумбия')),
                    ],
                    onChanged: (val) => _applyFilters(country: val, resetCountry: val == null),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.idle || LoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              LoadStatus.error => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(notifier.error ?? 'Ошибка'),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: notifier.load, child: const Text('Повторить')),
                    ],
                  ),
                ),
              LoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Авторов по заданным критериям не найдено')),
              LoadStatus.success => isCompact
                  ? _buildCardList(context, notifier)
                  : _buildTable(context, notifier),
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

  Widget _buildTable(BuildContext context, AuthorListNotifier notifier) {
    return EntityTable<Author>(
      items: notifier.result.items,
      idOf: (a) => a.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: (field) {
        final asc = field == notifier.query.sortField ? !notifier.query.sortAscending : true;
        _applyFilters(sortField: field, sortAscending: asc);
      },
      columns: [
        TableColumnSpec(
          label: 'Фамилия',
          sortField: 'lastName',
          build: (a) => InkWell(
            onTap: () => context.go('/authors/${a.id}'),
            child: Text(a.lastName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TableColumnSpec(label: 'Имя', sortField: 'firstName', build: (a) => Text(a.firstName)),
        TableColumnSpec(label: 'Страна', sortField: 'country', build: (a) => Text(a.country)),
        TableColumnSpec(label: 'Год рождения', sortField: 'birthYear', numeric: true, build: (a) => Text('${a.birthYear}')),
      ],
      actions: (a) => [
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Карточка автора',
          onPressed: () => context.go('/authors/${a.id}'),
        ),
        if (a.isDeleted)
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.green),
            tooltip: 'Восстановить',
            onPressed: () => notifier.restore(a.id),
          )
        else
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить',
            onPressed: () => notifier.softDelete(a.id),
          ),
      ],
    );
  }

  Widget _buildCardList(BuildContext context, AuthorListNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final a = notifier.result.items[index];
        final isSelected = notifier.selected.contains(a.id);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => notifier.toggleSelection(a.id),
            ),
            title: Text(a.fullName, style: TextStyle(decoration: a.isDeleted ? TextDecoration.lineThrough : null)),
            subtitle: Text('${a.country} · родился в ${a.birthYear} г.'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.go('/authors/${a.id}'),
            ),
          ),
        );
      },
    );
  }
}