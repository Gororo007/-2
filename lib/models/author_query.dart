class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          country == other.country &&
          sortField == other.sortField &&
          sortAscending == other.sortAscending &&
          page == other.page &&
          size == other.size &&
          includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        country,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}