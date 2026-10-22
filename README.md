# BacaBuku

Aplikasi katalog buku Flutter untuk mencari dan menjelajahi informasi buku dari [Open Library](https://openlibrary.org/).

## Fitur

- Mencari buku berdasarkan judul atau nama penulis.
- Memfilter hasil lewat kategori Open Library seperti fantasi, misteri, romansa, fiksi ilmiah, sejarah, biografi, dan buku anak.
- Melihat hasil pencarian dalam kartu dengan sampul, penulis, dan tahun terbit pertama.
- Membuka halaman detail untuk melihat overview (jika tersedia), tahun terbit, dan jumlah edisi.
- Membuka rekaman buku di situs Open Library.
- Menyimpan nama panggilan dan pilihan tema terang/gelap secara lokal dengan SharedPreferences.
- Menampilkan keadaan loading, hasil kosong, dan pesan error beserta aksi coba lagi.

## Teknologi dan package

- Flutter dan Dart.
- [`http`](https://pub.dev/packages/http) untuk permintaan HTTP ke Search API.
- [`url_launcher`](https://pub.dev/packages/url_launcher) untuk membuka rekaman buku di browser.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) untuk menyimpan nama panggilan dan tema pilihan.
- Open Library Search API dan Covers API.
- Open Library Work API untuk mengambil ringkasan pada halaman detail.

## Menjalankan aplikasi

1. Pasang Flutter SDK dan siapkan emulator atau perangkat Android.
2. Clone repositori ini dan buka folder project.
3. Jalankan `flutter pub get`.
4. Jalankan `flutter run`.

Aplikasi memerlukan koneksi internet. Android menggunakan izin `INTERNET` untuk mengambil data dan sampul dari Open Library.
Filter kategori memakai query `subject_key` yang didukung Open Library Search API. Nama panggilan dan pilihan tema hanya disimpan di perangkat, tanpa akun.

## Sumber data

- [Open Library API](https://openlibrary.org/developers/api)
- [Search API](https://openlibrary.org/dev/docs/api/search)
- [Covers API](https://openlibrary.org/dev/docs/api/covers)
