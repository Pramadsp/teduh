# Planning: Teduh, Aplikasi Pencatat Keuangan Grup & Keluarga (Flutter + Firebase)

Dokumen ini adalah instruksi dan panduan perencanaan proyek **Teduh**.

---

## 1. Konteks & Tujuan

Bangun aplikasi **Android** dengan **Flutter** untuk mencatat, merekap, dan menghitung pemasukan dan pengeluaran keuangan. Aplikasi digunakan oleh **grup keluarga, pasangan, maupun tim kas (hingga 6 pengguna)** yang berbagi satu pencatatan keuangan bersama dan tersinkron real-time di seluruh HP anggota.

**Fitur utama:**
1. **Pencatatan Transaksi:** Catat, ubah, hapus transaksi (pemasukan dan pengeluaran) lengkap dengan **Nama Transaksi (`title`)** spesifik.
2. **Saldo Per-User & All-Time Real Balance:** Rincian sisa saldo masing-masing anggota grup dan akumulasi **Total Saldo Grup** riil sepanjang waktu.
3. **Role Leader/Admin & Izin Transfer:** Pembuat grup bertindak sebagai Leader/Admin yang dapat memberikan/mencabut **Izin Transfer Saldo** untuk anggota lain.
4. **Transfer Saldo Internal:** Kirim saldo antar-anggota grup dengan pencatatan *Double-Entry Settlement Log* (Saldo Pengirim berkurang, Saldo Penerima bertambah, Netto Saldo Grup utuh).
5. **Keamanan PIN 6-Digit & Biometrik:** Perlindungan PIN 6-digit rahasia saat registrasi, verifikasi buka app/resume dari background, serta otorisasi transfer saldo (didukung sidik jari/Face ID native).
6. **Inactivity Session Timeout 24 Jam:** Sesi login bertahan nyaman 24 jam dengan Instant App Lock saat aplikasi di-minimize.
7. **Laporan Keuangan & Murni Cashflow:** Laporan harian, mingguan (Senin-Minggu), dan bulanan murni dari pengeluaran kebutuhan riil (mengecualikan *Transfer Internal*), lengkap dengan Donut Chart pengeluaran.
8. **Ekspor PDF & Excel:** Ekspor rekap laporan ke PDF cetak rapi (`pdf` + `printing`) dan Excel (`excel`) dengan nominal angka Integer, terintegrasi `open_filex` & `share_plus`.
9. **Search & Filter Real-Time:** Pencarian transaksi berdasarkan judul, catatan, atau kategori.
10. **Offline Persistence:** Firestore offline persistence aktif untuk mencatat saat offline dan tersinkronisasi otomatis ketika online.

**Distribusi:** Build APK release lalu bagikan lewat **Firebase App Distribution** (sideload), tanpa Play Store.

---

## 2. Aturan Kerja Proyek

1. Kerjakan per fase secara berurutan sesuai alur kerja.
2. Setelah setiap fase: jalankan `flutter analyze` (harus bersih) dan `flutter test` (harus lulus).
3. Langkah yang hanya bisa dilakukan manual oleh user (misalnya membuat proyek di Firebase Console) ditandai **[MANUAL USER]**. Berhenti, berikan instruksi singkat dan jelas, lalu tunggu konfirmasi user.
4. **Jangan pernah commit** file rahasia: `key.properties`, file `.jks`/`.keystore`, dan file sensitif lain. Pastikan masuk `.gitignore`.
5. Kode dibuat sederhana, rapi, dan mudah dibaca.

---

## 3. Keputusan Teknis

| Aspek | Pilihan |
|---|---|
| Framework | Flutter (stable terbaru), Dart null-safety |
| Platform | Android saja |
| State management | Riverpod (`flutter_riverpod`) |
| Navigasi | `GoRouter` & `StatefulShellRoute` / `MainScreen` |
| Auth | Firebase Authentication (email + password) |
| Database | Cloud Firestore (offline persistence aktif) |
| Format angka/tanggal | `intl` (locale `id_ID`) |
| Grafik | `fl_chart` |
| PDF | `pdf` + `printing` |
| Excel | `excel` |
| File & share | `path_provider`, `share_plus`, `open_filex` |
| Keamanan Biometrik | `local_auth` & `shared_preferences` |
| Pengujian | `flutter_test` (unit test untuk logika filter, perhitungan, dan widget) |

---

## 3.1 Identitas & Panduan Desain

**Nama:** Teduh. **Tagline:** "Urusan uang jadi lebih tenang."

### Palet Warna
| Nama | Hex | Penggunaan |
|---|---|---|
| Sage | `#6B8F71` | Warna utama, aksen, ikon aktif |
| Sage Dark | `#4A6B50` | Tombol utama, header, app bar |
| Krem | `#FAF6EE` | Latar belakang layar (mode terang) |
| Pasir | `#F1EBDD` | Kartu dan permukaan input field |
| Terakota | `#C8704A` | Aksen kedua, tombol transfer/FAB |
| Tinta | `#2F3A32` | Teks utama |
| Pemasukan | `#4F8A5B` | Nominal & ikon pemasukan |
| Pengeluaran | `#C0583F` | Nominal & ikon pengeluaran |

---

## 4. Struktur Proyek & Model Data

### 4.1 Model Data

**Transaction**
- `id`, `title`, `type: income | expense`, `amount: int` (integer Rupiah), `categoryId`, `categoryName`, `note: String?`, `date: DateTime`, `createdBy: String`, `createdByName: String`, `createdAt`, `updatedAt`

**Category**
- `id`, `name`, `type: income | expense`, `iconKey`, `isDefault: bool`

**Household (Grup)**
- `id`, `name`, `memberIds: List<String>` (maks 6), `inviteCode: String`, `creatorUid: String?` (Leader/Admin), `transferPrivileges: List<String>`, `createdAt`

**UserProfile**
- `uid`, `displayName`, `email`, `householdId`, `pin: String?`

### 4.2 Skema Firestore

```
users/{uid}                                         -> UserProfile
invites/{inviteCode}                                -> { householdId }
households/{householdId}                            -> Household
households/{householdId}/categories/{categoryId}
households/{householdId}/transactions/{transactionId}
```

---

## 5. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() {
      return request.auth != null;
    }

    match /users/{uid} {
      allow read: if signedIn();
      allow write: if signedIn() && request.auth.uid == uid;
    }

    match /invites/{code} {
      allow get, create: if signedIn();
      allow list, update, delete: if false;
    }

    match /households/{hid} {
      allow create: if signedIn() && request.auth.uid in request.resource.data.memberIds;
      allow get: if signedIn();
      allow list: if signedIn() && request.auth.uid in resource.data.memberIds;

      allow update: if signedIn() && (
        request.auth.uid in resource.data.memberIds || (
          request.resource.data.memberIds.size() <= 6 &&
          request.resource.data.memberIds.hasAll(resource.data.memberIds)
        )
      );

      allow delete: if false;

      match /{document=**} {
        allow read, write: if signedIn() && 
          request.auth.uid in get(/databases/$(database)/documents/households/$(hid)).data.memberIds;
      }
    }
  }
}
```

---

## 6. Daftar Pengujian Manual (Checklist QA)

**Transaksi & Pencatatan**
- [ ] Tambah pemasukan dan pengeluaran dengan Nama Transaksi (`title`), nominal Rupiah tampil benar.
- [ ] Restriksi transaksi: Anggota lain tidak dapat mengedit/menghapus transaksi pasangan.

**Grup & Transfer Saldo**
- [ ] Pembuat grup otomatis menjadi Leader/Admin.
- [ ] Leader dapat mengaktifkan/mencabut Izin Transfer Saldo anggota lain melalui Profil.
- [ ] Otorisasi Transfer Saldo berjalan atomic (Saldo Pengirim berkurang, Saldo Penerima bertambah, Total Saldo Grup utuh).
- [ ] Kuota anggota grup didukung hingga maksimal 6 pengguna.

**Keamanan & Sesi**
- [ ] PIN 6-Digit diwajibkan saat pendaftaran awal.
- [ ] Verifikasi PIN 6-Digit atau Sidik Jari / Face ID terpicu saat buka app / resume dari background.
- [ ] Sesi login bertahan hingga 24 jam.

**Laporan & Ekspor**
- [ ] Saldo Tersedia di Laporan dihitung secara All-Time Real Balance.
- [ ] Kategori "Transfer Internal" dikecualikan dari perhitungan arus kas & Grafik Donut Laporan.
- [ ] Ekspor PDF dan Excel terbuka normal dan nominal angka bertipe Integer.

---

## 7. Definisi Selesai (Definition of Done)

Aplikasi dianggap selesai jika: seluruh anggota grup (hingga 6 pengguna) dapat login di HP masing-masing, mencatat dan melihat transaksi bersama secara real-time, mengelola saldo per-user & transfer saldo internal, melihat laporan murni tanpa distorsi transfer internal, mengekspor rekap ke PDF & Excel, serta mengamankan dompet dengan PIN 6-Digit & Biometrik.
