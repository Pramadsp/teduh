# Teduh

Aplikasi pencatat keuangan grup & keluarga berbasis **Flutter** + **Firebase**.

> "Urusan uang jadi lebih tenang."

Teduh membantu grup keluarga, pasangan, maupun tim kas (hingga **6 pengguna**) mencatat, merekap, dan menghitung pemasukan & pengeluaran secara bersama, tersinkron real-time di seluruh HP anggota.

---

## ✨ Fitur Utama

- **Pencatatan Transaksi** — Catat pemasukan & pengeluaran lengkap dengan nama transaksi, kategori, tanggal, dan catatan.
- **Grup Transaksi (Split Struk Belanja)** — Kelompokkan beberapa item pengeluaran dalam satu tempat belanja (misal: *Indomaret*).
- **Saldo Per-User & All-Time Balance** — Rincian saldo masing-masing anggota dan total saldo grup riil.
- **Role Leader/Admin & Izin Transfer** — Pembuat grup menjadi admin dan dapat mengatur izin transfer saldo anggota.
- **Transfer Saldo Internal** — Kirim saldo antar-anggota dengan pencatatan *double-entry* (netto saldo grup tetap).
- **Keamanan PIN 6-Digit & Biometrik** — Perlindungan PIN, sidik jari / Face ID untuk membuka aplikasi dan otorisasi transfer.
- **Laporan & Ekspor** — Laporan harian/mingguan/bulanan, grafik donut, serta ekspor rekap ke **PDF** dan **Excel (.xlsx)**.
- **Pencarian & Filter Real-Time** — Cari transaksi berdasarkan nama, catatan, atau kategori.
- **Offline Persistence** — Catat saat offline, tersinkron otomatis saat online.

---

## 🛠️ Teknologi

| Aspek | Pilihan |
|---|---|
| Framework | Flutter (Dart null-safety) |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigasi | GoRouter / MainScreen (PageView) |
| Auth | Firebase Authentication (email + password) |
| Database | Cloud Firestore (offline persistence) |
| Grafik | `fl_chart` |
| PDF | `pdf` + `printing` |
| Excel | `excel` |
| File & Share | `path_provider`, `share_plus`, `open_filex` |
| Biometrik | `local_auth` |

---

## 🚀 Menjalankan Aplikasi

```bash
# Install dependencies
flutter pub get

# Jalankan di perangkat/emulator
flutter run
```

Persyaratan:
- Flutter SDK (stable terbaru)
- `google-services.json` pada `android/app/` (dari Firebase Console proyek `teduh-7411e`)

---

## 🔨 Build Release (APK)

```bash
flutter build apk --release
```

File hasil build: `build/app/outputs/flutter-apk/app-release.apk`

> **Penting:** Simpan keystore & password di tempat aman. Keystore yang berbeda akan membuat update gagal dan memaksa uninstall.

---

## 🔐 Firestore Security Rules

Aturan keamanan (security rules) tersedia di dokumen `docs/planning-aplikasi-keuangan-flutter.md`. Terapkan di **Firebase Console > Firestore > Rules** sebelum digunakan secara produksi.

---

## 📖 Dokumentasi

- `docs/handoff.md` — Catatan handoff & progress terakhir.
- `docs/planning-aplikasi-keuangan-flutter.md` — Panduan perencanaan & arsitektur.
- `docs/release/` — Catatan rilis tiap versi.
