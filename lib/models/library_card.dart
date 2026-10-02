class LibraryCard {
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
