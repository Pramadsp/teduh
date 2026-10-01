# Planning: Teduh, Aplikasi Pencatat Keuangan Keluarga (Flutter + Firebase)

Dokumen ini adalah instruksi lengkap untuk AI coding agent. Baca seluruhnya sebelum menulis kode, lalu kerjakan **per fase secara berurutan**.

---

## 1. Konteks & Tujuan

Bangun aplikasi **Android** dengan **Flutter** untuk mencatat, merekap, dan menghitung pemasukan dan pengeluaran. Aplikasi dipakai oleh **dua orang (suami dan istri)** yang berbagi satu pencatatan yang sama, tersinkron di dua HP.

**Fitur wajib:**
1. Catat, ubah, hapus transaksi (pemasukan dan pengeluaran).
2. Kategori yang bisa dikelola sendiri.
3. Dashboard ringkasan: saldo, total pemasukan, total pengeluaran.
4. Laporan dengan filter **harian, mingguan, bulanan**.
5. Ekspor rekap ke **PDF** dan **Excel (.xlsx)**.
6. Data dibagi berdua dan sinkron (login + database online).
7. Bahasa antarmuka: **Bahasa Indonesia**. Mata uang: **Rupiah (IDR)**.

**Bukan tujuan saat ini:** publish ke Play Store, iOS, multi-mata-uang, lebih dari 2 pengguna, fitur sosial.

**Distribusi:** build APK release lalu bagikan lewat **Firebase App Distribution** (sideload), tanpa Play Store.

---

## 2. Aturan Kerja untuk Agent

1. Kerjakan fase demi fase. **Jangan lompat fase.** Jangan mulai fase berikutnya sebelum kriteria selesai fase saat ini terpenuhi.
2. Setelah setiap fase: jalankan `flutter analyze` (harus bersih) dan `flutter test` (harus lulus), lalu `git commit` dengan pesan jelas, misalnya `feat: fase 3 - dashboard dan filter`.
3. Jangan menambah package di luar daftar tanpa alasan dan tanpa memberi tahu user.
4. Langkah yang hanya bisa dilakukan manual oleh user (misalnya membuat proyek di Firebase Console) ditandai **[MANUAL USER]**. Berhenti, berikan instruksi singkat dan jelas, lalu tunggu konfirmasi user.
5. **Jangan pernah commit** file rahasia: `key.properties`, file `.jks`/`.keystore`, dan file sensitif lain. Pastikan masuk `.gitignore`.
6. Gunakan kode yang sederhana dan mudah dibaca. User bukan developer senior, jadi beri komentar singkat pada bagian yang tidak jelas.
7. Di akhir setiap fase, tulis ringkasan singkat: apa yang dibuat, cara menjalankannya, dan apa yang perlu dites manual oleh user.

### Keputusan yang sudah ditetapkan (tidak perlu ditanyakan lagi)
- **Nama aplikasi:** Teduh
- **Package name / application ID:** `com.nayanara.teduh` (final, jangan diubah)
- **Fitur dompet/rekening:** tidak ada di versi 1 (bisa ditambah nanti)
- **Kategori default:** sesuai bagian 5.4 (user boleh mengubahnya kapan saja lewat fitur kelola kategori)
- **Desain:** ikuti panduan di bagian 3.1

Agent hanya perlu bertanya jika menemukan hal yang benar-benar ambigu dan tidak tercakup di dokumen ini.

---

## 3. Keputusan Teknis

| Aspek | Pilihan |
|---|---|
| Framework | Flutter (stable terbaru), Dart null-safety |
| Platform | Android saja |
| State management | Riverpod (`flutter_riverpod`) |
| Navigasi | `go_router` |
| Auth | Firebase Authentication (email + password) |
| Database | Cloud Firestore (offline persistence aktif) |
| Format angka/tanggal | `intl` (locale `id_ID`) |
| Grafik | `fl_chart` |
| PDF | `pdf` + `printing` |
| Excel | `excel` |
| File & share | `path_provider`, `share_plus`, `open_filex` |
| Pengujian | `flutter_test` (unit test untuk logika filter dan perhitungan) |

**Arsitektur:** feature-first dengan pemisahan `data` / `domain` / `presentation`. Akses data lewat **interface Repository** supaya bisa diganti dari implementasi lokal (in-memory) ke Firestore tanpa mengubah UI.

---

## 3.1 Identitas & Panduan Desain

**Nama:** Teduh. **Tagline (opsional, untuk layar login):** "Urusan uang jadi lebih tenang."

**Karakter desain:** tenang, lembut, dan hangat, seperti tempat berteduh. Banyak ruang kosong, sudut membulat, bayangan tipis, tanpa warna yang terlalu mencolok.

### Palet warna

| Nama | Hex | Penggunaan |
|---|---|---|
| Sage | `#6B8F71` | Warna utama (seed color), aksen, ikon aktif |
| Sage Dark | `#4A6B50` | Tombol utama (agar teks putih terbaca jelas), app bar |
| Krem | `#FAF6EE` | Latar belakang layar (mode terang) |
| Pasir | `#F1EBDD` | Kartu dan permukaan sekunder |
| Terakota | `#C8704A` | Aksen kedua, tombol tambah (FAB) |
| Tinta | `#2F3A32` | Teks utama (mode terang) |
| Pemasukan | `#4F8A5B` | Nominal dan ikon pemasukan |
| Pengeluaran | `#C0583F` | Nominal dan ikon pengeluaran |

**Mode gelap:** latar `#1E2420`, permukaan `#28302A`, warna utama `#9DBFA3`, teks `#E8EDE6`.

**Aksesibilitas:** pemasukan dan pengeluaran jangan dibedakan hanya dengan warna. Selalu sertakan tanda (`+` / `-`) dan ikon panah (naik/turun).

```dart
class AppColors {
  static const sage = Color(0xFF6B8F71);
  static const sageDark = Color(0xFF4A6B50);
  static const cream = Color(0xFFFAF6EE);
  static const sand = Color(0xFFF1EBDD);
  static const terracotta = Color(0xFFC8704A);
  static const ink = Color(0xFF2F3A32);
  static const income = Color(0xFF4F8A5B);
  static const expense = Color(0xFFC0583F);
}
// ThemeData(useMaterial3: true,
//   colorScheme: ColorScheme.fromSeed(seedColor: AppColors.sage)
//     .copyWith(surface: AppColors.cream, ...))
```

### Tipografi dan komponen
- Font: **Plus Jakarta Sans** (bobot 400, 500, 600, 700). **Bundel file font di folder `assets/fonts`** dan daftarkan di `pubspec.yaml`, jangan mengunduh saat runtime, agar tetap tampil benar saat offline.
- Radius: kartu 20, tombol dan input 14.
- Navigasi bawah: `NavigationBar` Material 3.
- Nominal besar di dashboard ditampilkan tebal (bobot 700) dengan format Rupiah.

### Ikon aplikasi
- Gaya: **adaptive icon**, latar Sage Dark (`#4A6B50`), gambar utama berupa **siluet pohon rindang** (kanopi membulat dan batang sederhana) berwarna krem (`#FAF6EE`).
- Ukuran sumber 1024x1024 px, gambar utama di dalam area aman (sekitar 66% bagian tengah) agar tidak terpotong.
- Buat sebagai SVG sederhana, ekspor ke PNG, lalu generate dengan `flutter_launcher_icons`.
- Splash screen: latar krem dengan ikon di tengah.

---

## 4. Langkah Manual yang Diperlukan dari User

Ini tidak bisa dikerjakan agent. Agent harus memberi instruksi dan menunggu konfirmasi.

- **[MANUAL USER] M1 (sebelum Fase 5):** Buat proyek di Firebase Console, tambahkan aplikasi Android dengan package name `com.nayanara.teduh`, aktifkan **Authentication > Email/Password**, buat **Cloud Firestore** (mode production), lalu jalankan FlutterFire CLI (`flutterfire configure`) atau unduh `google-services.json`.
- **[MANUAL USER] M2 (Fase 5):** Salin Firestore Security Rules dari bagian 6 ke Firebase Console > Firestore > Rules, lalu Publish.
- **[MANUAL USER] M3 (Fase 8):** Aktifkan **App Distribution** di Firebase Console dan tambahkan email istri sebagai tester.
- **[MANUAL USER] M4 (setelah kedua akun terdaftar):** Pertimbangkan menonaktifkan pendaftaran baru atau pastikan tidak ada akun lain, karena aplikasi ini privat.

---

## 5. Struktur Proyek & Model Data

### 5.1 Struktur folder (feature-first)

```
lib/
  main.dart
  app.dart                      // MaterialApp.router, tema, locale
  core/
    constants/                  // kategori default, konstanta
    utils/                      // format rupiah, helper tanggal & rentang
    theme/
    router/
  features/
    auth/
      data/ domain/ presentation/
    household/                  // grup keluarga & kode undangan
    transactions/
      data/                     // transaction_repository (interface + impl)
      domain/                   // model Transaction
      presentation/             // list, form tambah/ubah
    categories/
    dashboard/
    reports/                    // filter, ringkasan, grafik
    export/                     // pdf_exporter, excel_exporter
    settings/
test/
```

### 5.2 Model data

**Transaction**
- `id: String`
- `type: income | expense`
- `amount: int` → **rupiah dalam integer**, tanpa desimal. Selalu positif; arah ditentukan oleh `type`.
- `categoryId: String`, `categoryName: String` (disalin agar laporan tetap benar jika kategori diubah nama)
- `note: String` (opsional)
- `date: DateTime` (tanggal transaksi, disimpan sebagai Firestore Timestamp)
- `createdBy: String` (uid), `createdByName: String`
- `createdAt`, `updatedAt`

**Category**
- `id`, `name`, `type: income | expense`, `iconKey` (opsional), `isDefault: bool`

**Household**
- `id`, `name`, `memberIds: List<String>` (maks 2), `inviteCode: String`, `createdAt`

**UserProfile**
- `uid`, `displayName`, `email`, `householdId`

### 5.3 Skema Firestore

```
users/{uid}                         -> UserProfile
invites/{inviteCode}                -> { householdId }
households/{householdId}            -> Household
households/{householdId}/categories/{categoryId}
households/{householdId}/transactions/{transactionId}
```

Semua data keuangan berada di bawah `households/{householdId}` sehingga kedua anggota membaca dan menulis data yang sama.

### 5.4 Kategori default

- **Pengeluaran:** Makan & Minum, Belanja Rumah Tangga, Transportasi, Tagihan & Utilitas, Kesehatan, Pendidikan, Hiburan, Sedekah & Donasi, Lainnya
- **Pemasukan:** Gaji, Bonus, Usaha, Lainnya

---

## 6. Firestore Security Rules (untuk disalin user di langkah M2)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() {
      return request.auth != null;
    }

    function isMember(hid) {
      return signedIn() &&
        request.auth.uid in get(/databases/$(database)/documents/households/$(hid)).data.memberIds;
    }

    match /users/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    // Kode undangan: boleh dibaca per dokumen (get), tidak boleh di-list
    match /invites/{code} {
      allow get: if signedIn();
      allow create: if signedIn();
      allow list, update, delete: if false;
    }

    match /households/{hid} {
      allow create: if signedIn() && request.auth.uid in request.resource.data.memberIds;
      allow read: if isMember(hid);
      // anggota boleh ubah; orang baru boleh bergabung (maks 2 anggota)
      allow update: if isMember(hid) || (
        signedIn() &&
        request.auth.uid in request.resource.data.memberIds &&
        request.resource.data.memberIds.size() <= 2 &&
        request.resource.data.memberIds.hasAll(resource.data.memberIds)
      );
      allow delete: if false;

      match /{document=**} {
        allow read, write: if isMember(hid);
      }
    }
  }
}
```

Agent: tinjau rules ini, uji lewat Firebase Emulator atau Rules Playground bila memungkinkan, dan beri tahu user bila ada celah yang ditemukan.

---

## 7. Fase Pengerjaan

### Fase 0: Setup Proyek
**Tugas:**
1. Jalankan `flutter doctor`, pastikan toolchain Android siap. Jika ada masalah, jelaskan solusinya ke user.
2. Buat proyek dengan application ID **`com.nayanara.teduh`**: `flutter create --org com.nayanara --project-name teduh --platforms android teduh`. Setelah dibuat, verifikasi bahwa `applicationId` dan `namespace` di `android/app/build.gradle(.kts)` persis `com.nayanara.teduh`, dan atur label aplikasi (`android:label` di `AndroidManifest.xml`) menjadi `Teduh`.
3. Tambahkan dependency (bagian 3) di `pubspec.yaml`.
4. Atur `analysis_options.yaml` (gunakan `flutter_lints`).
5. `git init`, buat `.gitignore` yang menyertakan `key.properties`, `*.jks`, `*.keystore`, `google-services.json` (opsional, putuskan bersama user), dan folder build.
6. Buat struktur folder bagian 5.1.

**Selesai bila:** aplikasi kosong berjalan di emulator/HP, `flutter analyze` bersih, commit pertama selesai.

### Fase 1: Fondasi UI & Utilitas
**Tugas:**
1. Terapkan tema sesuai panduan desain di bagian 3.1 (Material 3, palet sage, krem, dan terakota, mendukung mode terang dan gelap).
2. Inisialisasi locale: `initializeDateFormatting('id_ID')`.
3. Helper `formatRupiah(int)` → contoh `Rp 1.250.000`, dan helper format tanggal Indonesia.
4. Navigasi bawah (bottom navigation) dengan 4 tab: **Beranda, Transaksi, Laporan, Pengaturan** (go_router, ShellRoute).
5. Buat model `Transaction` dan `Category` (+ `fromMap`/`toMap`).
6. Buat **interface** `TransactionRepository` dan `CategoryRepository` + implementasi **in-memory** untuk pengembangan awal.
7. Seed kategori default.

**Selesai bila:** keempat tab bisa dibuka, format Rupiah benar, model dan repository in-memory tersedia dengan unit test dasar.

### Fase 2: CRUD Transaksi
**Tugas:**
1. Layar **Daftar Transaksi**: dikelompokkan per tanggal, tampilkan kategori, catatan, nominal (hijau untuk pemasukan, merah untuk pengeluaran), dan siapa yang mencatat.
2. Layar/bottom sheet **Tambah/Ubah Transaksi**: toggle jenis, input nominal (format ribuan otomatis, hanya angka), pilih kategori (sesuai jenis), date picker, catatan opsional.
3. Validasi: nominal wajib > 0, kategori wajib dipilih, tanggal wajib.
4. **Hapus** transaksi dengan dialog konfirmasi dan opsi Undo (snackbar).
5. Tombol tambah cepat (FAB).

**Selesai bila:** bisa tambah, ubah, hapus transaksi, daftar langsung ter-update (Riverpod), validasi bekerja.

### Fase 3: Dashboard, Filter, dan Laporan
**Tugas:**
1. Fungsi rentang waktu di `core/utils`:
   - **Harian:** 00:00 sampai 23:59:59 pada tanggal terpilih.
   - **Mingguan:** **Senin sampai Minggu** pada minggu dari tanggal terpilih.
   - **Bulanan:** tanggal 1 sampai akhir bulan.
   - Gunakan waktu lokal perangkat (WIB); jangan memakai UTC untuk batas hari.
2. Fungsi perhitungan: total pemasukan, total pengeluaran, saldo (pemasukan − pengeluaran), total per kategori.
3. **Dashboard (Beranda):** kartu saldo bulan berjalan, total pemasukan dan pengeluaran, 5 transaksi terakhir.
4. **Layar Laporan:**
   - Segmented control: **Harian | Mingguan | Bulanan**.
   - Navigasi periode (panah sebelumnya/berikutnya + pilih tanggal/bulan).
   - Ringkasan angka (pemasukan, pengeluaran, saldo).
   - Grafik **pengeluaran per kategori** (pie/donut `fl_chart`) dan daftar rincian per kategori.
   - Daftar transaksi pada periode tersebut.
5. **Unit test wajib** untuk fungsi rentang waktu (termasuk pergantian bulan, pergantian tahun, minggu yang melintasi bulan) dan perhitungan total.

**Selesai bila:** filter harian/mingguan/bulanan menampilkan data yang benar, semua unit test lulus.

### Fase 4: Manajemen Kategori
**Tugas:**
1. Layar kelola kategori (di Pengaturan): lihat, tambah, ubah nama, hapus.
2. Kategori yang sudah dipakai transaksi **tidak boleh dihapus** (beri pesan jelas), atau tawarkan memindahkan transaksi ke kategori lain.
3. Mengubah nama kategori tidak merusak laporan lama (karena `categoryName` disalin di transaksi; putuskan dan jelaskan perilakunya ke user).

**Selesai bila:** kategori bisa dikelola dan form transaksi memakai daftar kategori terbaru.

### Fase 5: Firebase, Login, Household, dan Sinkronisasi
**[MANUAL USER] M1** harus selesai lebih dulu. Agent berhenti dan minta konfirmasi.

**Tugas:**
1. Inisialisasi Firebase di `main.dart` (`firebase_options.dart` hasil `flutterfire configure`).
2. **Auth:** layar Daftar dan Masuk (email + password), keluar (logout), validasi dasar, pesan error dalam Bahasa Indonesia. Pantau status login (auth state) di router (redirect ke login bila belum masuk).
3. **Household (alur dua orang):**
   - Pengguna pertama mendaftar, lalu memilih **"Buat grup keluarga"**. Sistem membuat dokumen `households/{id}` dan kode undangan 6 karakter, lalu menyimpan `invites/{kode}`.
   - Pengguna kedua mendaftar, memilih **"Gabung dengan kode"**, memasukkan kode, lalu sistem menambahkan uid ke `memberIds` (gunakan `FieldValue.arrayUnion`) dan menyimpan `householdId` di profilnya.
   - Tampilkan kode undangan di Pengaturan agar bisa dibagikan.
4. Implementasikan `FirestoreTransactionRepository` dan `FirestoreCategoryRepository` (path di bagian 5.3), pakai **stream** (`snapshots()`) agar UI update real-time.
5. Aktifkan **offline persistence** Firestore, pastikan data yang dicatat saat offline tersinkron saat online lagi.
6. Saat grup dibuat, **seed kategori default** ke Firestore.
7. Ganti provider repository dari in-memory ke Firestore.
8. **[MANUAL USER] M2:** minta user menerapkan Security Rules (bagian 6).
9. Query laporan: gunakan `where('date', isGreaterThanOrEqualTo: awal)` dan `isLessThanOrEqualTo: akhir`, `orderBy('date', descending: true)`. Jika Firestore meminta indeks, beri tahu user link pembuatan indeks.

**Selesai bila:** dua akun berbeda di dua HP (atau emulator) bisa tergabung dalam satu grup, transaksi yang dicatat satu orang muncul di HP yang lain secara otomatis, aplikasi tetap bisa mencatat saat offline.

### Fase 6: Ekspor PDF dan Excel
**Tugas:**
1. Di Layar Laporan, tombol **Ekspor** dengan pilihan **PDF** atau **Excel**. Ekspor mengikuti **filter dan periode yang sedang aktif**.
2. **PDF** berisi:
   - Judul: nama aplikasi/grup, jenis periode, rentang tanggal.
   - Ringkasan: total pemasukan, total pengeluaran, saldo.
   - Tabel rincian per kategori.
   - Tabel daftar transaksi: Tanggal, Kategori, Catatan, Pencatat, Pemasukan, Pengeluaran.
   - Nomor halaman, tabel yang panjang otomatis berlanjut ke halaman berikutnya.
3. **Excel (.xlsx)** berisi:
   - Sheet **Ringkasan** (total dan per kategori).
   - Sheet **Transaksi** (kolom sama dengan PDF, nominal sebagai **angka**, bukan teks, agar bisa dijumlah).
   - Header dicetak tebal, lebar kolom wajar.
4. Nama file: `laporan_<harian|mingguan|bulanan>_<periode>.pdf` / `.xlsx`.
5. Simpan di direktori sementara/dokumen aplikasi lalu buka dengan `open_filex` atau bagikan dengan `share_plus` (user bisa kirim ke WhatsApp, Drive, dan sebagainya).
6. Tangani kasus laporan kosong (tampilkan pesan, jangan crash).
7. Unit test untuk logika penyusunan data ekspor (bukan rendering).

**Selesai bila:** file PDF dan Excel berhasil dibuat, terbuka normal di aplikasi PDF/Excel/Sheets, dan isinya sesuai filter.

### Fase 7: Penyempurnaan
**Tugas:**
1. Empty state yang ramah (belum ada transaksi, laporan kosong).
2. Loading dan error state di semua layar yang memakai data online.
3. Pencarian atau filter sederhana di daftar transaksi (berdasarkan kategori atau kata kunci catatan).
4. Pastikan nominal besar tidak overflow di layar kecil.
5. Buat ikon aplikasi sesuai panduan di bagian 3.1 (`flutter_launcher_icons`) dan pastikan nama yang tampil di HP adalah **Teduh**.
6. Review kinerja: hindari rebuild berlebihan, batasi jumlah dokumen yang dibaca (query per periode, jangan baca seluruh koleksi).
7. Tambahkan fitur **ekspor semua data** (backup) sebagai Excel dari Pengaturan (opsional, tanya user).

**Selesai bila:** tidak ada layar yang kosong tanpa penjelasan, tidak ada crash pada skenario normal.

### Fase 8: Build Release & Distribusi
**Tugas:**
1. Buat **keystore** sendiri (`keytool -genkey ...`) dan konfigurasi `android/key.properties` + `build.gradle` untuk signing release. **Jangan commit** file ini. Ingatkan user untuk **menyimpan keystore dan password di tempat aman**, karena kunci yang berbeda membuat update gagal dan memaksa uninstall.
2. Atur versi di `pubspec.yaml` (`version: 1.0.0+1`). Naikkan angka setelah `+` (build number) setiap rilis baru.
3. Build: `flutter build apk --release`.
4. Pastikan SHA-1/SHA-256 tidak diperlukan (karena memakai email/password, bukan Google Sign-In). Jika kelak memakai Google Sign-In, daftarkan sertifikat di Firebase.
5. **[MANUAL USER] M3:** aktifkan App Distribution dan tambahkan tester.
6. Unggah APK ke **Firebase App Distribution** (lewat console, atau Firebase CLI: `firebase appdistribution:distribute ... --app <APP_ID> --testers "<email>"`). Sertakan release notes.
7. Tulis `README.md` singkat: cara menjalankan, cara build, cara rilis ulang, dan peringatan soal keystore.

**Selesai bila:** istri user berhasil menerima undangan, memasang aplikasi, login, dan data tersinkron dengan HP user.

### Fase 9: Pengujian Akhir
Jalankan seluruh daftar pada bagian 8 di **perangkat nyata**, dan laporkan hasilnya ke user.

---

## 8. Daftar Pengujian Manual (Checklist)

**Transaksi**
- [ ] Tambah pemasukan dan pengeluaran, nominal tampil dengan format Rupiah benar
- [ ] Ubah dan hapus transaksi, Undo hapus bekerja
- [ ] Transaksi tanggal lampau muncul di periode yang benar

**Filter & laporan**
- [ ] Harian, mingguan (Senin sampai Minggu), dan bulanan menampilkan angka benar
- [ ] Transaksi pada tanggal 1, tanggal terakhir bulan, dan pukul 23:59 masuk periode yang benar
- [ ] Pergantian bulan dan tahun benar
- [ ] Saldo = total pemasukan − total pengeluaran

**Sinkronisasi (dua HP)**
- [ ] Transaksi di HP A muncul di HP B tanpa refresh manual
- [ ] Catat saat offline, tersinkron ketika online lagi
- [ ] Akun ketiga **tidak bisa** bergabung ke grup yang sudah terisi 2 orang
- [ ] Akun di luar grup tidak bisa membaca data grup

**Ekspor**
- [ ] PDF terbuka normal, angka dan total sesuai layar
- [ ] Excel terbuka di Excel/Google Sheets, kolom nominal bisa dijumlahkan
- [ ] Ekspor dengan data banyak (100+ transaksi) berlanjut ke halaman berikutnya dengan rapi
- [ ] Ekspor saat data kosong tidak crash

**Distribusi**
- [ ] Update versi baru bisa menimpa versi lama tanpa uninstall (keystore sama)

---

## 9. Catatan Teknis Penting

- **Uang = integer.** Jangan pakai `double` untuk nominal.
- **Package name** `com.nayanara.teduh` sudah final. Jangan diubah setelah didaftarkan di Firebase, karena akan merusak konfigurasi dan menyulitkan update aplikasi.
- **Tanggal:** simpan sebagai Timestamp, hitung batas periode dengan waktu lokal (WIB). Satu fungsi pusat untuk rentang waktu, dipakai di semua layar, dan wajib dites.
- **Minggu dimulai hari Senin.**
- **Jangan hardcode** string Firebase atau rahasia di kode yang di-commit tanpa sepengetahuan user.
- **Biaya:** Firebase paket gratis (Spark) lebih dari cukup untuk dua pengguna. Jangan menambah layanan berbayar tanpa persetujuan user.
- **Privasi:** data keuangan sensitif. Jangan menambahkan analytics atau SDK pihak ketiga yang mengirim data keluar.
- **Ketergantungan versi:** cek versi terbaru tiap package di pub.dev saat setup dan gunakan versi yang kompatibel satu sama lain, terutama paket Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`).

---

## 10. Ide Pengembangan Nanti (di luar versi 1)

Anggaran bulanan per kategori dan peringatan, transaksi berulang (tagihan bulanan), dompet/rekening, lampiran foto struk, kunci aplikasi (PIN/biometrik), widget layar utama, ekspor otomatis tiap akhir bulan.

---

## 11. Definisi Selesai (Definition of Done) Versi 1

Aplikasi dianggap selesai jika: suami dan istri bisa login di HP masing-masing, mencatat dan melihat transaksi bersama secara real-time, melihat laporan harian/mingguan/bulanan dengan angka yang benar, mengekspor rekap ke PDF dan Excel, dan menerima update aplikasi lewat Firebase App Distribution.
