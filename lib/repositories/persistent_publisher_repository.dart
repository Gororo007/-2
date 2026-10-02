import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/publisher.dart';
import 'book_repository.dart';
import 'publisher_repository.dart';
import 'seed_data.dart';

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v1';
  final SharedPreferences _prefs;
  final BookRepository _bookRepo;
  List<Publisher> _publishers = [];

  PersistentPublisherRepository(this._prefs, this._bookRepo) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _publishers = [...seedPublishers];
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _publishers = list.map((e) => Publisher.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _publishers = [...seedPublishers];
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_publishers.map((p) => p.toJson()).toList()));
  }

  @override
  Future<List<Publisher>> findAll({bool includeDeleted = false}) async {
    return _publishers.where((p) => includeDeleted || !p.isDeleted).toList();
  }

  @override
  Future<Publisher?> findById(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    return i == -1 ? null : _publishers[i];
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final id = _publishers.isEmpty ? 1 : (_publishers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final created = Publisher(
      id: id,
      name: publisher.name,
      city: publisher.city,
      website: publisher.website,
    );
    _publishers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final i = _publishers.indexWhere((p) => p.id == publisher.id);
    if (i == -1) throw StateError('Издательство ${publisher.id} не найдено');
    _publishers[i] = publisher;
    await _persist();
    return _publishers[i];
  }

  @override
  Future<void> deleteWithCheck(int id) async {
    final books = await _bookRepo.getAllRaw();
    final count = books.where((b) => b.publisherId == id && !b.isDeleted).length;
    if (count > 0) {
      throw StateError('Невозможно удалить издательство: к нему привязано книг ($count шт.)');
    }
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i != -1) {
      _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> restore(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i != -1) {
      _publishers[i] = _publishers[i].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }
}
