import 'package:flutter_test/flutter_test.dart';
import 'package:uts_mobile/models/book.dart';

void main() {
  group('Book.fromJson', () {
    test('maps Open Library search fields', () {
      final book = Book.fromJson({
        'key': '/works/OL123W',
        'title': 'The Hobbit',
        'author_name': ['J. R. R. Tolkien'],
        'first_publish_year': 1937,
        'cover_i': 456,
        'edition_count': 75,
      });

      expect(book.key, '/works/OL123W');
      expect(book.title, 'The Hobbit');
      expect(book.authorLabel, 'J. R. R. Tolkien');
      expect(book.yearLabel, '1937');
      expect(
        book.coverUrl('M'),
        'https://covers.openlibrary.org/b/id/456-M.jpg',
      );
      expect(book.editionLabel, '75');
    });

    test('provides safe fallbacks for missing optional fields', () {
      final book = Book.fromJson({'key': '/works/OL456W'});

      expect(book.title, 'Judul tidak tersedia');
      expect(book.authorLabel, 'Penulis tidak diketahui');
      expect(book.yearLabel, 'Tahun tidak tersedia');
      expect(book.coverUrl('M'), isNull);
      expect(book.editionLabel, '-');
    });
  });
}
