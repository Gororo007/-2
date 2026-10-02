import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';
import 'genre_repository.dart';
import 'seed_data.dart';

class PersistentGenreRepository implements GenreRepository {
  static const _key = 'genres_v1';
  final SharedPreferences _prefs;
  List<Genre> _genres = [];

  PersistentGenreRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _genres = [...seedGenres];
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _genres = list.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _genres = [...seedGenres];
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_genres.map((g) => g.toJson()).toList()));
  }

  @override
  Future<List<Genre>> findAll({bool includeDeleted = false}) async {
    return _genres.where((g) => includeDeleted || !g.isDeleted).toList();
  }

  @override
  Future<Genre?> findById(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    return i == -1 ? null : _genres[i];
  }

  @override
  Future<Genre> create(Genre genre) async {
    final id = _genres.isEmpty ? 1 : (_genres.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final created = Genre(id: id, name: genre.name, description: genre.description);
    _genres.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final i = _genres.indexWhere((g) => g.id == genre.id);
    if (i == -1) throw StateError('Жанр ${genre.id} не найден');
    _genres[i] = genre;
    await _persist();
    return _genres[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i != -1) {
      _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> restore(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i != -1) {
      _genres[i] = _genres[i].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }
}
