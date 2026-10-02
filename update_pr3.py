import os
import subprocess
import sys

FILES = {
    "pubspec.yaml": """name: library_system
description: "Клиент библиотечной системы (Практические работы 2 и 3)"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
  go_router: ^14.0.0
  provider: ^6.1.2
  intl: ^0.19.0
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
""",

    "lib/core/validators.dart": """typedef Validator = String? Function(String?);

class V {
  static Validator required([String message = 'Поле обязательно для заполнения']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  static Validator integer({int? min, int? max}) {
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      final n = int.tryParse(value.trim());
      if (n == null) return 'Введите целое число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator email([String message = 'Некорректный адрес почты']) {
    final re = RegExp(r'^[\\w.+-]+@[\\w-]+\\.[\\w.-]+$');
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      return re.hasMatch(value.trim()) ? null : message;
    };
  }

  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
""",

    "lib/models/genre.dart": """class Genre {
  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const Genre({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Genre copyWith({
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
""",

    "lib/models/publisher.dart": """class Publisher {
  final int id;
  final String name;
  final String city;
  final String website;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    this.city = '',
    this.website = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? city,
    String? website,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      website: website ?? this.website,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'website': website,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        website: json['website'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
""",

    "lib/models/library_card.dart": """class LibraryCard {
  final int id;
  final String cardNumber;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LibraryCard({
    required this.id,
    required this.cardNumber,
    required this.issuedAt,
    required this.expiresAt,
  });

  LibraryCard copyWith({
    String? cardNumber,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return LibraryCard(
      id: id,
      cardNumber: cardNumber ?? this.cardNumber,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardNumber': cardNumber,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
        id: json['id'] as int? ?? 0,
        cardNumber: json['cardNumber'] as String? ?? '',
        issuedAt: json['issuedAt'] != null
            ? DateTime.tryParse(json['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String) ??
                DateTime.now().add(const Duration(days: 365))
            : DateTime.now().add(const Duration(days: 365)),
      );
}
""",

    "lib/models/reader.dart": """import 'library_card.dart';

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Reader copyWith({
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'card': card.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Reader.fromJson(Map<String, dynamic> json) => Reader(
        id: json['id'] as int? ?? 0,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        card: json['card'] != null
            ? LibraryCard.fromJson(json['card'] as Map<String, dynamic>)
            : LibraryCard(
                id: 0,
                cardNumber: 'TMP',
                issuedAt: DateTime.now(),
                expiresAt: DateTime.now(),
              ),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
""",

    "lib/models/author.dart": """class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => '$firstName $lastName';

  Author copyWith({
    String? firstName,
    String? lastName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'country': country,
        'birthYear': birthYear,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        country: json['country'] as String? ?? '',
        birthYear: json['birthYear'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
""",

    "lib/models/book.dart": """class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isbn': isbn,
        'year': year,
        'pages': pages,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'genreIds': genreIds,
        'copiesTotal': copiesTotal,
        'copiesAvailable': copiesAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        isbn: json['isbn'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        pages: json['pages'] as int? ?? 0,
        publisherId: json['publisherId'] as int? ?? 0,
        authorIds: (json['authorIds'] as List?)?.cast<int>() ?? const [],
        genreIds: (json['genreIds'] as List?)?.cast<int>() ?? const [],
        copiesTotal: json['copiesTotal'] as int? ?? 0,
        copiesAvailable: json['copiesAvailable'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
""",

    "lib/repositories/seed_data.dart": """import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/library_card.dart';
import '../models/publisher.dart';
import '../models/reader.dart';

final seedPublishers = [
  const Publisher(id: 1, name: 'Азбука', city: 'Санкт-Петербург', website: 'azbooka.ru'),
  const Publisher(id: 2, name: 'АСТ', city: 'Москва', website: 'ast.ru'),
  const Publisher(id: 3, name: 'Эксмо', city: 'Москва', website: 'eksmo.ru'),
];

final seedGenres = [
  const Genre(id: 1, name: 'Классика', description: 'Мировая классическая литература'),
  const Genre(id: 2, name: 'Роман', description: 'Художественные романы'),
  const Genre(id: 3, name: 'Антиутопия', description: 'Социально-политическая фантастика'),
  const Genre(id: 4, name: 'Мистика', description: 'Магический реализм и мистика'),
  const Genre(id: 5, name: 'Драматургия', description: 'Пьесы и драматические произведения'),
];

final seedAuthors = [
  const Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828),
  const Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821),
  const Author(id: 3, firstName: 'Джордж', lastName: 'Оруэлл', country: 'Великобритания', birthYear: 1903),
  const Author(id: 4, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия', birthYear: 1891),
  const Author(id: 5, firstName: 'Рэй', lastName: 'Брэдбери', country: 'США', birthYear: 1920),
  const Author(id: 6, firstName: 'Габриэль', lastName: 'Гарсиа Маркес', country: 'Колумбия', birthYear: 1927),
  const Author(id: 7, firstName: 'Антон', lastName: 'Чехов', country: 'Россия', birthYear: 1860),
  const Author(id: 8, firstName: 'Эрих Мария', lastName: 'Ремарк', country: 'Германия', birthYear: 1898),
];

final seedBooks = [
  const Book(id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1, 2], copiesTotal: 5, copiesAvailable: 3),
  const Book(id: 2, title: 'Преступление и наказание', isbn: '978-5-17-090630-7', year: 1866, pages: 672, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 2),
  const Book(id: 3, title: '1984', isbn: '978-5-17-080115-2', year: 1949, pages: 320, publisherId: 2, authorIds: [3], genreIds: [3], copiesTotal: 8, copiesAvailable: 6),
  const Book(id: 4, title: 'Мастер и Маргарита', isbn: '978-5-389-01686-6', year: 1967, pages: 480, publisherId: 1, authorIds: [4], genreIds: [1, 4], copiesTotal: 6, copiesAvailable: 1),
  const Book(id: 5, title: '451 градус по Фаренгейту', isbn: '978-5-17-077074-8', year: 1953, pages: 256, publisherId: 2, authorIds: [5], genreIds: [3], copiesTotal: 7, copiesAvailable: 5),
  const Book(id: 6, title: 'Сто лет одиночества', isbn: '978-5-17-087082-0', year: 1967, pages: 480, publisherId: 2, authorIds: [6], genreIds: [1, 4], copiesTotal: 3, copiesAvailable: 0),
  const Book(id: 7, title: 'Вишнёвый сад', isbn: '978-5-389-02283-6', year: 1904, pages: 96, publisherId: 1, authorIds: [7], genreIds: [5], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 8, title: 'На Западном фронте без перемен', isbn: '978-5-17-084224-7', year: 1929, pages: 288, publisherId: 2, authorIds: [8], genreIds: [1, 2], copiesTotal: 5, copiesAvailable: 2),
];

final seedReaders = [
  Reader(
    id: 1,
    fullName: 'Иван Иванов',
    email: 'ivanov@example.com',
    phone: '+7 999 111-22-33',
    card: LibraryCard(
      id: 1,
      cardNumber: 'CARD-1001',
      issuedAt: DateTime(2025, 1, 15),
      expiresAt: DateTime(2027, 1, 15),
    ),
  ),
  Reader(
    id: 2,
    fullName: 'Анна Смирнова',
    email: 'smirnova@example.com',
    phone: '+7 999 444-55-66',
    card: LibraryCard(
      id: 2,
      cardNumber: 'CARD-1002',
      issuedAt: DateTime(2025, 3, 10),
      expiresAt: DateTime(2027, 3, 10),
    ),
  ),
];
""",

    "lib/repositories/genre_repository.dart": """import '../models/genre.dart';

abstract interface class GenreRepository {
  Future<List<Genre>> findAll({bool includeDeleted = false});
  Future<Genre?> findById(int id);
  Future<Genre> create(Genre genre);
  Future<Genre> update(Genre genre);
  Future<void> softDelete(int id);
  Future<void> restore(int id);
}
""",

    "lib/repositories/publisher_repository.dart": """import '../models/publisher.dart';

abstract interface class PublisherRepository {
  Future<List<Publisher>> findAll({bool includeDeleted = false});
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> deleteWithCheck(int id);
  Future<void> restore(int id);
}
""",

    "lib/repositories/reader_repository.dart": """import '../models/reader.dart';

abstract interface class ReaderRepository {
  Future<List<Reader>> findAll({bool includeDeleted = false, String search = ''});
  Future<Reader?> findById(int id);
  Future<Reader> create(Reader reader);
  Future<Reader> update(Reader reader);
  Future<void> softDelete(int id);
  Future<void> restore(int id);
}
""",

    "lib/repositories/persistent_genre_repository.dart": """import 'dart:convert';
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
""",

    "lib/repositories/persistent_publisher_repository.dart": """import 'dart:convert';
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
""",

    "lib/repositories/persistent_reader_repository.dart": """import 'dart:convert';
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
""",

    "lib/repositories/book_repository.dart": """import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';

abstract interface class BookRepository {
  Future<PageResult<Book>> find(BookQuery query);
  Future<List<Book>> getAllRaw();
  Future<Book?> findById(int id);
  Future<Book> create(Book book);
  Future<Book> update(Book book);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
""",

    "lib/repositories/in_memory_book_repository.dart": """import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'seed_data.dart';

class PersistentBookRepository implements BookRepository {
  static const _key = 'books_v1';
  final SharedPreferences _prefs;
  List<Book> _books = [];

  PersistentBookRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _books = [...seedBooks];
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _books = list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _books = [...seedBooks];
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_books.map((b) => b.toJson()).toList()));
  }

  @override
  Future<List<Book>> getAllRaw() async => _books;

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((b) =>
          b.title.toLowerCase().contains(needle) ||
          b.isbn.toLowerCase().contains(needle)).toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    if (q.yearTo != null) rows = rows.where((b) => b.year <= q.yearTo!).toList();

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
    final index = _books.indexWhere((b) => b.id == id);
    return index == -1 ? null : _books[index];
  }

  @override
  Future<Book> create(Book book) async {
    final exists = _books.any((b) => b.isbn.trim() == book.isbn.trim() && !b.isDeleted);
    if (exists) {
      throw StateError('Книга с таким ISBN уже существует');
    }

    final id = _books.isEmpty ? 1 : (_books.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final created = Book(
      id: id,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: book.authorIds,
      genreIds: book.genreIds,
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesAvailable,
    );
    _books.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    final exists = _books.any((b) =>
        b.id != book.id &&
        b.isbn.trim() == book.isbn.trim() &&
        !b.isDeleted);
    if (exists) {
      throw StateError('Книга с таким ISBN уже существует');
    }

    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book;
    await _persist();
    return _books[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
""",

    "lib/repositories/in_memory_author_repository.dart": """import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'seed_data.dart';

class PersistentAuthorRepository implements AuthorRepository {
  static const _key = 'authors_v1';
  final SharedPreferences _prefs;
  List<Author> _authors = [];

  PersistentAuthorRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _authors = [...seedAuthors];
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _authors = list.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _authors = [...seedAuthors];
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_authors.map((a) => a.toJson()).toList()));
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((a) =>
          a.lastName.toLowerCase().contains(needle) ||
          a.firstName.toLowerCase().contains(needle) ||
          a.country.toLowerCase().contains(needle)).toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'firstName' => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    final index = _authors.indexWhere((a) => a.id == id);
    return index == -1 ? null : _authors[index];
  }

  @override
  Future<Author> create(Author author) async {
    final id = _authors.isEmpty ? 1 : (_authors.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final created = Author(
      id: id,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      birthYear: author.birthYear,
    );
    _authors.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор ${author.id} не найден');
    _authors[i] = author;
    await _persist();
    return _authors[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i != -1) {
      _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i != -1) {
      _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
""",

    "lib/widgets/app_shell.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (icon: Icons.menu_book, label: 'Книги', path: '/books'),
    (icon: Icons.person, label: 'Авторы', path: '/authors'),
    (icon: Icons.category, label: 'Жанры', path: '/genres'),
    (icon: Icons.business, label: 'Издательства', path: '/publishers'),
    (icon: Icons.badge, label: 'Читатели', path: '/readers'),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/authors')) return 1;
    if (location.startsWith('/genres')) return 2;
    if (location.startsWith('/publishers')) return 3;
    if (location.startsWith('/readers')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final size = screenSizeOf(context);

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => context.go(_destinations[idx].path),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => context.go(_destinations[idx].path),
            extended: size == ScreenSize.expanded,
            labelType: size == ScreenSize.expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
""",

    "lib/screens/book_form_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                      value: _publisherId,
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
""",

    "lib/screens/author_form_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _birthYearController = TextEditingController();

  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<AuthorRepository>();
      final author = await repo.findById(widget.id!);
      if (author != null) {
        _firstNameController.text = author.firstName;
        _lastNameController.text = author.lastName;
        _countryController.text = author.country;
        _birthYearController.text = author.birthYear.toString();
      }
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
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AuthorRepository>();
    final author = Author(
      id: widget.id ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _countryController.text.trim(),
      birthYear: int.parse(_birthYearController.text.trim()),
    );

    if (widget.isEditing) {
      await repo.update(author);
    } else {
      await repo.create(author);
    }
    _isDirty = false;
    if (mounted) {
      context.read<AuthorListNotifier>().load();
      context.go('/authors');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _birthYearController.dispose();
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
        if (leave && context.mounted) context.go('/authors');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () async {
            if (await _onWillPop() && context.mounted) context.go('/authors');
          }),
          title: Text(widget.isEditing ? 'Редактирование автора' : 'Новый автор'),
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
                  children: [
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Фамилия *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'Имя *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Страна *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Год рождения *', border: OutlineInputBorder()),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.integer(min: 0, max: 2100)]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать автора'),
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
""",

    "lib/screens/reader_form_screen.dart": """import 'package:flutter/material.dart';
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
""",

    "lib/screens/genres_screen.dart": """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/genre.dart';
import '../repositories/genre_repository.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  List<Genre> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<GenreRepository>().findAll();
    setState(() {
      _genres = list;
      _isLoading = false;
    });
  }

  Future<void> _editGenre([Genre? genre]) async {
    final nameCtrl = TextEditingController(text: genre?.name ?? '');
    final descCtrl = TextEditingController(text: genre?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(genre == null ? 'Новый жанр' : 'Редактирование жанра'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название жанра *'),
                validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (res == true) {
      final repo = context.read<GenreRepository>();
      if (genre == null) {
        await repo.create(Genre(id: 0, name: nameCtrl.text.trim(), description: descCtrl.text.trim()));
      } else {
        await repo.update(genre.copyWith(name: nameCtrl.text.trim(), description: descCtrl.text.trim()));
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        actions: [
          FilledButton.icon(
            onPressed: () => _editGenre(),
            icon: const Icon(Icons.add),
            label: const Text('Добавить жанр'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _genres.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final g = _genres[idx];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.category)),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(g.description.isNotEmpty ? g.description : 'Без описания'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editGenre(g)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await context.read<GenreRepository>().softDelete(g.id);
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
""",

    "lib/screens/publishers_screen.dart": """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';

class PublishersScreen extends StatefulWidget {
  const PublishersScreen({super.key});

  @override
  State<PublishersScreen> createState() => _PublishersScreenState();
}

class _PublishersScreenState extends State<PublishersScreen> {
  List<Publisher> _publishers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<PublisherRepository>().findAll();
    setState(() {
      _publishers = list;
      _isLoading = false;
    });
  }

  Future<void> _editPublisher([Publisher? publisher]) async {
    final nameCtrl = TextEditingController(text: publisher?.name ?? '');
    final cityCtrl = TextEditingController(text: publisher?.city ?? '');
    final webCtrl = TextEditingController(text: publisher?.website ?? '');
    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(publisher == null ? 'Новое издательство' : 'Редактирование издательства'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название *'),
                validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Город')),
              const SizedBox(height: 12),
              TextFormField(controller: webCtrl, decoration: const InputDecoration(labelText: 'Веб-сайт')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (res == true) {
      final repo = context.read<PublisherRepository>();
      if (publisher == null) {
        await repo.create(Publisher(id: 0, name: nameCtrl.text.trim(), city: cityCtrl.text.trim(), website: webCtrl.text.trim()));
      } else {
        await repo.update(publisher.copyWith(name: nameCtrl.text.trim(), city: cityCtrl.text.trim(), website: webCtrl.text.trim()));
      }
      _load();
    }
  }

  Future<void> _deletePublisher(Publisher p) async {
    try {
      await context.read<PublisherRepository>().deleteWithCheck(p.id);
      _load();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Отказ в удалении'),
            content: Text(e.toString().replaceAll('StateError: ', '')),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        actions: [
          FilledButton.icon(
            onPressed: () => _editPublisher(),
            icon: const Icon(Icons.add),
            label: const Text('Добавить издательство'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _publishers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final p = _publishers[idx];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${p.city} · ${p.website}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editPublisher(p)),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deletePublisher(p)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
""",

    "lib/screens/readers_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';

class ReadersScreen extends StatefulWidget {
  const ReadersScreen({super.key});

  @override
  State<ReadersScreen> createState() => _ReadersScreenState();
}

class _ReadersScreenState extends State<ReadersScreen> {
  List<Reader> _readers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<ReaderRepository>().findAll();
    setState(() {
      _readers = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/readers/new'),
            icon: const Icon(Icons.add),
            label: const Text('Новый читатель'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _readers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final r = _readers[idx];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.badge)),
                  title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${r.email} · ${r.phone}\\nБилет: ${r.card.cardNumber}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context.go('/readers/${r.id}/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await context.read<ReaderRepository>().softDelete(r.id);
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
""",

    "lib/screens/book_list_screen.dart": """import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/book.dart';
import '../models/book_query.dart';
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
      page: page ?? (search != null || genreId != null || resetGenre || publisherId != null || resetPublisher ? 1 : current.page),
      size: size ?? current.size,
      includeDeleted: includeDeleted ?? current.includeDeleted,
    );

    final params = <String, String>{
      if (nextQuery.search.isNotEmpty) 'search': nextQuery.search,
      if (nextQuery.genreId != null) 'genreId': nextQuery.genreId.toString(),
      if (nextQuery.publisherId != null) 'publisherId': nextQuery.publisherId.toString(),
      'sort': '${nextQuery.sortField},${nextQuery.sortAscending ? "asc" : "desc"}',
      'page': nextQuery.page.toString(),
      'size': nextQuery.size.toString(),
      if (nextQuery.includeDeleted) 'deleted': 'true',
    };

    context.replace(Uri(path: '/books', queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/books/new'),
            icon: const Icon(Icons.add),
            label: const Text('Создать книгу'),
          ),
          const SizedBox(width: 12),
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
              tooltip: 'Удалить выбранные (${notifier.selected.length})',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Подтверждение'),
                    content: Text('Удалить выбранные книги (${notifier.selected.length} шт.)?'),
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
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Жанр'),
                    value: notifier.query.genreId,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все жанры')),
                      DropdownMenuItem(value: 1, child: Text('Классика')),
                      DropdownMenuItem(value: 2, child: Text('Роман')),
                      DropdownMenuItem(value: 3, child: Text('Антиутопия')),
                    ],
                    onChanged: (val) => _applyFilters(genreId: val, resetGenre: val == null),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Издатель'),
                    value: notifier.query.publisherId,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все издатели')),
                      DropdownMenuItem(value: 1, child: Text('Азбука')),
                      DropdownMenuItem(value: 2, child: Text('АСТ')),
                    ],
                    onChanged: (val) => _applyFilters(publisherId: val, resetPublisher: val == null),
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
                const Center(child: Text('Книг по заданным критериям не найдено')),
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

  Widget _buildTable(BuildContext context, BookListNotifier notifier) {
    return EntityTable<Book>(
      items: notifier.result.items,
      idOf: (b) => b.id,
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
          label: 'Название',
          sortField: 'title',
          build: (b) => InkWell(
            onTap: () => context.go('/books/${b.id}'),
            child: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TableColumnSpec(label: 'ISBN', build: (b) => Text(b.isbn)),
        TableColumnSpec(label: 'Год', sortField: 'year', numeric: true, build: (b) => Text('${b.year}')),
        TableColumnSpec(label: 'Стр.', sortField: 'pages', numeric: true, build: (b) => Text('${b.pages}')),
        TableColumnSpec(label: 'В наличии', numeric: true, build: (b) => Text('${b.copiesAvailable} / ${b.copiesTotal}')),
      ],
      actions: (b) => [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Редактировать',
          onPressed: () => context.go('/books/${b.id}/edit'),
        ),
        if (b.isDeleted)
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.green),
            tooltip: 'Восстановить',
            onPressed: () => notifier.restore(b.id),
          )
        else
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить',
            onPressed: () => notifier.softDelete(b.id),
          ),
      ],
    );
  }

  Widget _buildCardList(BuildContext context, BookListNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final b = notifier.result.items[index];
        final isSelected = notifier.selected.contains(b.id);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => notifier.toggleSelection(b.id),
            ),
            title: Text(b.title, style: TextStyle(decoration: b.isDeleted ? TextDecoration.lineThrough : null)),
            subtitle: Text('Год: ${b.year} | ISBN: ${b.isbn}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/books/${b.id}/edit')),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => context.go('/books/${b.id}')),
              ],
            ),
          ),
        );
      },
    );
  }
}
""",

    "lib/screens/author_list_screen.dart": """import 'dart:async';
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
          FilledButton.icon(
            onPressed: () => context.go('/authors/new'),
            icon: const Icon(Icons.add),
            label: const Text('Создать автора'),
          ),
          const SizedBox(width: 12),
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
          icon: const Icon(Icons.edit),
          tooltip: 'Редактировать',
          onPressed: () => context.go('/authors/${a.id}/edit'),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/authors/${a.id}/edit')),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => context.go('/authors/${a.id}')),
              ],
            ),
          ),
        );
      },
    );
  }
}
""",

    "lib/core/router.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/author_detail_screen.dart';
import '../screens/author_form_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/genres_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/publishers_screen.dart';
import '../screens/reader_form_screen.dart';
import '../screens/readers_screen.dart';
import '../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/books',
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/books',
          name: 'books',
          builder: (context, state) => const BookListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const BookFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => BookDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => BookFormScreen(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/authors',
          name: 'authors',
          builder: (context, state) => const AuthorListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AuthorFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => AuthorDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => AuthorFormScreen(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/genres',
          name: 'genres',
          builder: (context, state) => const GenresScreen(),
        ),
        GoRoute(
          path: '/publishers',
          name: 'publishers',
          builder: (context, state) => const PublishersScreen(),
        ),
        GoRoute(
          path: '/readers',
          name: 'readers',
          builder: (context, state) => const ReadersScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ReaderFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => ReaderFormScreen(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
""",

    "lib/main.dart": """import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'repositories/persistent_reader_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  final bookRepo = PersistentBookRepository(prefs);
  final authorRepo = PersistentAuthorRepository(prefs);
  final genreRepo = PersistentGenreRepository(prefs);
  final publisherRepo = PersistentPublisherRepository(prefs, bookRepo);
  final readerRepo = PersistentReaderRepository(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>.value(value: bookRepo),
        Provider<AuthorRepository>.value(value: authorRepo),
        Provider<GenreRepository>.value(value: genreRepo),
        Provider<PublisherRepository>.value(value: publisherRepo),
        Provider<ReaderRepository>.value(value: readerRepo),
        ChangeNotifierProvider(
          create: (context) => BookListNotifier(context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthorListNotifier(context.read<AuthorRepository>()),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотечная система',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      routerConfig: appRouter,
    );
  }
}
"""
}

def main():
    print("--- Обновление проекта: Практическая работа 3 ---")
    
    for path, content in FILES.items():
        dir_name = os.path.dirname(path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  + Обновлен: {path}")

    print("\n[+] Установка зависимостей (flutter pub get)...")
    subprocess.run(["flutter", "pub", "get"], shell=True)

    print("\n Готово! Запустите проект командой:")
    print("flutter run -d chrome")

if __name__ == "__main__":
    main()