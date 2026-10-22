import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';

class OpenLibraryService {
  OpenLibraryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _fields =
      'key,title,author_name,first_publish_year,cover_i,edition_count';

  Future<List<Book>> search(String query, {String? subjectKey}) async {
    final trimmedQuery = query.trim();
    final String apiQuery;
    if (subjectKey == null) {
      apiQuery = trimmedQuery;
    } else if (trimmedQuery.isEmpty) {
      apiQuery = 'subject_key:$subjectKey';
    } else {
      apiQuery = '($trimmedQuery) AND subject_key:$subjectKey';
    }
    final uri = Uri.https('openlibrary.org', '/search.json', {
      'q': apiQuery,
      'fields': _fields,
      'limit': '20',
    });

    final response = await _client.get(
      uri,
      headers: const {'User-Agent': 'BacaBukuFlutter/1.0'},
    );
    if (response.statusCode != 200) {
      throw Exception('Permintaan katalog gagal (${response.statusCode}).');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> || decoded['docs'] is! List) {
      throw const FormatException('Format respons katalog tidak sesuai.');
    }

    return (decoded['docs'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Book.fromJson)
        .toList(growable: false);
  }

  Future<String?> getWorkDescription(String workKey) async {
    if (workKey.isEmpty) return null;
    final path = workKey.startsWith('/works/')
        ? '$workKey.json'
        : '/works/$workKey.json';
    final response = await _client.get(
      Uri.https('openlibrary.org', path),
      headers: const {'User-Agent': 'BacaBukuFlutter/1.0'},
    );
    if (response.statusCode != 200) {
      throw Exception('Ringkasan buku gagal dimuat (${response.statusCode}).');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format detail karya tidak sesuai.');
    }
    final description = decoded['description'];
    final value = switch (description) {
      final String text => text,
      final Map<String, dynamic> object => object['value'] as String?,
      _ => null,
    };
    final trimmedValue = value?.trim();
    return trimmedValue == null || trimmedValue.isEmpty ? null : trimmedValue;
  }
}
