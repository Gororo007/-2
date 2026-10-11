class Book {
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

  factory Book.fromJson(Map<String, dynamic> json) {
    int parsePubId() {
      if (json['publisherId'] != null) {
        return (json['publisherId'] as num).toInt();
      }
      if (json['publisher'] is Map && json['publisher']['id'] != null) {
        return (json['publisher']['id'] as num).toInt();
      }
      return 1;
    }

    List<int> parseAuthorIds() {
      if (json['authorIds'] is List) {
        return (json['authorIds'] as List)
            .map((e) => (e as num).toInt())
            .toList();
      }
      if (json['authors'] is List) {
        return (json['authors'] as List)
            .map(
                (e) => e is Map ? (e['id'] as num).toInt() : (e as num).toInt())
            .toList();
      }
      return const [];
    }

    List<int> parseGenreIds() {
      if (json['genreIds'] is List) {
        return (json['genreIds'] as List)
            .map((e) => (e as num).toInt())
            .toList();
      }
      if (json['genres'] is List) {
        return (json['genres'] as List)
            .map(
                (e) => e is Map ? (e['id'] as num).toInt() : (e as num).toInt())
            .toList();
      }
      return const [];
    }

    return Book(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      publisherId: parsePubId(),
      authorIds: parseAuthorIds(),
      genreIds: parseGenreIds(),
      copiesTotal: (json['copiesTotal'] as num?)?.toInt() ?? 0,
      copiesAvailable: (json['copiesAvailable'] as num?)?.toInt() ?? 0,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
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
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      };

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
}
