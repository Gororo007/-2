import 'package:dio/dio.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'seed_data.dart';

class PersistentBookRepository implements BookRepository {
  final List<Book> _db = [...seedBooks];

  @override
  List<Book> getAllRaw() => List.unmodifiable(_db);

  @override
  Future<PageResult<Book>> find(BookQuery q, {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var rows = _db.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(needle) ||
              b.isbn.toLowerCase().contains(needle))
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    final index = _db.indexWhere((b) => b.id == id);
    return index == -1 ? null : _db[index];
  }

  @override
  Future<Book> create(Book book) async {
    final created = book.copyWith();
    _db.add(created);
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _db.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _db[i] = book;
    return _db[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _db.indexWhere((b) => b.id == id);
    if (i != -1) _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _db.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _db.indexWhere((b) => b.id == id);
    if (i != -1) _db[i] = _db[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _db.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
