import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reader.dart';
import 'reader_repository.dart';
import 'seed_data.dart';

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;
  List<Reader> _readers = [];

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _readers = [...seedReaders];
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _readers = list.map((e) => Reader.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _readers = [...seedReaders];
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_readers.map((r) => r.toJson()).toList()));
  }

  @override
  Future<List<Reader>> findAll({bool includeDeleted = false, String search = ''}) async {
    var rows = _readers.where((r) => includeDeleted || !r.isDeleted).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows
          .where((r) =>
              r.fullName.toLowerCase().contains(q) ||
              r.email.toLowerCase().contains(q) ||
              r.card.cardNumber.toLowerCase().contains(q))
          .toList();
    }
    return rows;
  }

  @override
  Future<Reader?> findById(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    return i == -1 ? null : _readers[i];
  }

  @override
  Future<Reader> create(Reader reader) async {
    // Проверка уникальности email
    final exists = _readers.any((r) => r.email.toLowerCase() == reader.email.toLowerCase() && !r.isDeleted);
    if (exists) {
      throw StateError('Читатель с такой почтой уже существует');
    }

    final id = _readers.isEmpty ? 1 : (_readers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final card = reader.card.copyWith();
    final created = Reader(
      id: id,
      fullName: reader.fullName,
      email: reader.email,
      phone: reader.phone,
      card: card,
    );
    _readers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final exists = _readers.any((r) =>
        r.id != reader.id &&
        r.email.toLowerCase() == reader.email.toLowerCase() &&
        !r.isDeleted);
    if (exists) {
      throw StateError('Читатель с такой почтой уже существует');
    }

    final i = _readers.indexWhere((r) => r.id == reader.id);
    if (i == -1) throw StateError('Читатель ${reader.id} не найден');
    _readers[i] = reader;
    await _persist();
    return _readers[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i != -1) {
      _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i != -1) {
      _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }
}
