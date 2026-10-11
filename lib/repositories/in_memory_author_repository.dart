import 'package:dio/dio.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'seed_data.dart';

class PersistentAuthorRepository implements AuthorRepository {
  final List<Author> _db = [...seedAuthors];

  @override
  Future<PageResult<Author>> find(AuthorQuery q,
      {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var rows = _db.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(needle) ||
              a.firstName.toLowerCase().contains(needle) ||
              a.country.toLowerCase().contains(needle))
          .toList();
    }

    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    final i = _db.indexWhere((a) => a.id == id);
    return i == -1 ? null : _db[i];
  }

  @override
  Future<Author> create(Author a) async {
    _db.add(a);
    return a;
  }

  @override
  Future<Author> update(Author a) async {
    final i = _db.indexWhere((x) => x.id == a.id);
    if (i != -1) {
      _db[i] = a;
    }
    return a;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _db.indexWhere((a) => a.id == id);
    if (i != -1) {
      _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _db.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _db.indexWhere((a) => a.id == id);
    if (i != -1) {
      _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _db.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
