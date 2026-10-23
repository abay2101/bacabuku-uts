import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/book.dart';
import 'screens/settings_screen.dart';
import 'services/open_library_service.dart';
import 'services/favorite_books_service.dart';
import 'services/preferences_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BacaBukuApp());
}

class BacaBukuApp extends StatefulWidget {
  const BacaBukuApp({super.key});

  @override
  State<BacaBukuApp> createState() => _BacaBukuAppState();
}

class _BacaBukuAppState extends State<BacaBukuApp> {
  final _preferences = PreferencesService();
  String _userName = '';
  ThemeMode _themeMode = ThemeMode.light;
  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userName = await _preferences.getUserName();
      final isDarkMode = await _preferences.getDarkMode();
      if (!mounted) return;
      setState(() {
        _userName = userName;
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      });
    } catch (error) {
      debugPrint('Gagal memuat preferensi: $error');
    } finally {
      if (mounted) setState(() => _preferencesLoaded = true);
    }
  }

  Future<void> _saveName(String name) async {
    await _preferences.saveUserName(name);
    if (mounted) setState(() => _userName = name.trim());
  }

  Future<void> _changeTheme(bool isDark) async {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    try {
      await _preferences.saveDarkMode(isDark);
    } catch (error) {
      debugPrint('Gagal menyimpan tema: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BacaBuku',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: !_preferencesLoaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : SearchScreen(
              userName: _userName,
              isDarkMode: _themeMode == ThemeMode.dark,
              onSaveName: _saveName,
              onThemeChanged: _changeTheme,
            ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151B17) : const Color(0xFFF7F5EF);
    const green = Color(0xFF567C68);
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      cardColor: isDark ? const Color(0xFF222A24) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF252D27) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF29352D)
            : const Color(0xFFEDEFE9),
        selectedColor: green,
        secondarySelectedColor: green,
        side: BorderSide.none,
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(foregroundColor: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: green),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onSaveName,
    required this.onThemeChanged,
  });

  final String userName;
  final bool isDarkMode;
  final Future<void> Function(String) onSaveName;
  final Future<void> Function(bool) onThemeChanged;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _service = OpenLibraryService();
  late Future<List<Book>> _booksFuture;
  String _query = 'fiction';
  String? _subjectKey;
  String _categoryLabel = 'Semua';

  static const _categories = <({String label, String? subjectKey})>[
    (label: 'Semua', subjectKey: null),
    (label: 'Fantasi', subjectKey: 'fantasy'),
    (label: 'Misteri', subjectKey: 'mystery'),
    (label: 'Romansa', subjectKey: 'romance'),
    (label: 'Fiksi ilmiah', subjectKey: 'science_fiction'),
    (label: 'Sejarah', subjectKey: 'history'),
    (label: 'Biografi', subjectKey: 'biography'),
    (label: 'Anak', subjectKey: 'juvenile_fiction'),
  ];

  @override
  void initState() {
    super.initState();
    _booksFuture = _service.search(_query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search([String? value]) {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _query = query;
      _booksFuture = _service.search(query, subjectKey: _subjectKey);
    });
  }

  void _selectCategory(({String label, String? subjectKey}) category) {
    final typedQuery = _controller.text.trim();
    final query = category.subjectKey == null && typedQuery.isEmpty
        ? 'fiction'
        : typedQuery;
    setState(() {
      _subjectKey = category.subjectKey;
      _categoryLabel = category.label;
      _query = query;
      _booksFuture = _service.search(_query, subjectKey: _subjectKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildSearch()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
              sliver: SliverToBoxAdapter(child: _buildSectionTitle()),
            ),
            FutureBuilder<List<Book>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StatusPanel(
                      icon: Icons.wifi_off_rounded,
                      title: 'Buku belum bisa dimuat',
                      message: 'Periksa koneksi internet, lalu coba lagi.',
                      actionLabel: 'Coba lagi',
                      onAction: () => setState(() {
                        _booksFuture = _service.search(
                          _query,
                          subjectKey: _subjectKey,
                        );
                      }),
                    ),
                  );
                }
                final books = snapshot.data ?? const <Book>[];
                if (books.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StatusPanel(
                      icon: Icons.menu_book_rounded,
                      title: 'Belum ada hasil',
                      message:
                          'Coba kata kunci judul atau nama penulis yang lain.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverGrid.builder(
                    itemCount: books.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 17,
                          childAspectRatio: .66,
                        ),
                    itemBuilder: (context, index) => BookCard(
                      book: books[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookDetailScreen(book: books[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF29352D)
              : const Color(0xFFE2E9E0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF567C68)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BacaBuku',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.userName.trim().isEmpty
                  ? 'Temukan bacaan berikutnya'
                  : 'Selamat datang, ${widget.userName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Buku tersimpan',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FavoriteBooksScreen()),
        ),
        icon: const Icon(Icons.bookmark_outline_rounded),
      ),
      IconButton(
        tooltip: 'Pengaturan',
        onPressed: _openSettings,
        icon: const Icon(Icons.tune_rounded),
      ),
    ],
  );

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          userName: widget.userName,
          isDarkMode: widget.isDarkMode,
          onSaveName: widget.onSaveName,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  Widget _buildSearch() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Ada cerita apa hari ini?',
        style: TextStyle(
          fontSize: 27,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Cari buku berdasarkan judul atau penulis.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 19),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            height: 52,
            width: 54,
            child: FilledButton(
              onPressed: _search,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final selected = category.label == _categoryLabel;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.label),
                selected: selected,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onSelected: (_) => _selectCategory(category),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );

  Widget _buildSectionTitle() => Row(
    children: [
      const Expanded(
        child: Text(
          'Hasil penelusuran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      if (_categoryLabel != 'Semua')
        Text(
          _categoryLabel,
          style: const TextStyle(
            color: Color(0xFF63816C),
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: AspectRatio(
                      aspectRatio: .72,
                      child: BookCover(book: book, size: 'M'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.authorLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 14,
                    color: Color(0xFF63816C),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    book.yearLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF63816C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final Future<String?> _descriptionFuture;
  final _favoriteBooks = FavoriteBooksService();
  bool _isFavorite = false;
  bool _favoriteLoaded = false;

  Book get book => widget.book;

  @override
  void initState() {
    super.initState();
    _descriptionFuture = OpenLibraryService().getWorkDescription(book.key);
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final isFavorite = await _favoriteBooks.contains(book.key);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
      _favoriteLoaded = true;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _favoriteBooks.remove(book.key);
    } else {
      await _favoriteBooks.save(book);
    }
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFavorite ? 'Buku disimpan.' : 'Buku dihapus dari tersimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail buku',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Hapus dari tersimpan' : 'Simpan buku',
            onPressed: _favoriteLoaded ? _toggleFavorite : null,
            icon: Icon(_isFavorite ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 190,
                height: 265,
                child: BookCover(book: book, size: 'L'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.authorLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF6D786F)),
          ),
          const SizedBox(height: 22),
          const Text(
            'Tentang buku',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            'Data katalog dapat berbeda antar edisi. Periksa kembali untuk memastikan informasinya.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _InfoTile(
                label: 'Terbit pertama',
                value: book.yearLabel,
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                label: 'Jumlah edisi',
                value: book.editionLabel,
                icon: Icons.library_books_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Overview',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _buildOverview(context),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: book.key.isEmpty
                ? null
                : () => _openOpenLibrary(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Buka di Open Library'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Sumber data: Open Library',
              style: TextStyle(color: Color(0xFF7D857F), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context) => FutureBuilder<String?>(
    future: _descriptionFuture,
    builder: (context, snapshot) {
      final textStyle = TextStyle(
        fontSize: 14,
        height: 1.55,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(),
        );
      }
      if (snapshot.hasError) {
        return Text(
          'Overview belum dapat dimuat. Silakan buka Open Library untuk informasi lebih lanjut.',
          style: textStyle,
        );
      }
      final description = snapshot.data;
      if (description == null || description.isEmpty) {
        return Text(
          'Ringkasan belum tersedia untuk buku ini.',
          style: textStyle,
        );
      }
      return Text(description, style: textStyle);
    },
  );

  Future<void> _openOpenLibrary(BuildContext context) async {
    final bookPath = book.key.startsWith('/') ? book.key : '/works/${book.key}';
    final uri = Uri.https('openlibrary.org', bookPath);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan Open Library tidak dapat dibuka.'),
        ),
      );
    }
  }
}

class FavoriteBooksScreen extends StatefulWidget {
  const FavoriteBooksScreen({super.key});

  @override
  State<FavoriteBooksScreen> createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  final _service = FavoriteBooksService();
  late Future<List<Book>> _books;

  @override
  void initState() {
    super.initState();
    _books = _service.getAll();
  }

  void _reload() => setState(() => _books = _service.getAll());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buku tersimpan')),
    body: FutureBuilder<List<Book>>(
      future: _books,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Buku tersimpan belum dapat dimuat.'));
        }
        final books = snapshot.data ?? const <Book>[];
        if (books.isEmpty) {
          return const Center(child: Text('Belum ada buku tersimpan.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              child: ListTile(
                leading: SizedBox(width: 42, child: BookCover(book: book, size: 'S')),
                title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(book.authorLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
                ).then((_) => _reload()),
                trailing: IconButton(
                  tooltip: 'Hapus dari tersimpan',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    await _service.remove(book.key);
                    _reload();
                  },
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF29352D)
            : const Color(0xFFE9EDE6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF55745F), size: 20),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, required this.size});

  final Book book;
  final String size;

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl(size);
    if (coverUrl == null) return const _CoverPlaceholder();
    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _CoverPlaceholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _CoverPlaceholder(showSpinner: true),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({this.showSpinner = false});

  final bool showSpinner;

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF29352D)
        : const Color(0xFFE3E9E1),
    alignment: Alignment.center,
    child: showSpinner
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(
            Icons.menu_book_rounded,
            size: 42,
            color: Color(0xFF78907E),
          ),
  );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 45, color: const Color(0xFF78907E)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
