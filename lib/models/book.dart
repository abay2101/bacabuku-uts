class Book {
  const Book({
    required this.key,
    required this.title,
    required this.authorNames,
    required this.firstPublishYear,
    required this.coverId,
    required this.editionCount,
  });

  final String key;
  final String title;
  final List<String> authorNames;
  final int? firstPublishYear;
  final int? coverId;
  final int? editionCount;

  String get authorLabel =>
      authorNames.isEmpty ? 'Penulis tidak diketahui' : authorNames.join(', ');
  String get yearLabel =>
      firstPublishYear?.toString() ?? 'Tahun tidak tersedia';
  String get editionLabel => editionCount?.toString() ?? '-';

  String? coverUrl(String size) => coverId == null
      ? null
      : 'https://covers.openlibrary.org/b/id/$coverId-$size.jpg';

  factory Book.fromJson(Map<String, dynamic> json) {
    final authors = json['author_name'];
    return Book(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Judul tidak tersedia',
      authorNames: authors is List
          ? authors.whereType<String>().toList(growable: false)
          : const <String>[],
      firstPublishYear: _asInt(json['first_publish_year']),
      coverId: _asInt(json['cover_i']),
      editionCount: _asInt(json['edition_count']),
    );
  }

  Map<String, Object?> toDatabaseMap() => {
    'key': key,
    'title': title,
    'author_names': authorNames.join('|'),
    'first_publish_year': firstPublishYear,
    'cover_id': coverId,
    'edition_count': editionCount,
  };

  factory Book.fromDatabaseMap(Map<String, Object?> row) => Book(
    key: row['key'] as String,
    title: row['title'] as String,
    authorNames: (row['author_names'] as String)
        .split('|')
        .where((name) => name.isNotEmpty)
        .toList(growable: false),
    firstPublishYear: row['first_publish_year'] as int?,
    coverId: row['cover_id'] as int?,
    editionCount: row['edition_count'] as int?,
  );

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
