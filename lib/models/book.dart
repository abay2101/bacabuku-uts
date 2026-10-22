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

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
