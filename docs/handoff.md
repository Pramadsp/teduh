# Catatan Handoff - Proyek Teduh

**Tanggal Handoff:** 2 Oktober 2026  
**Progress Terakhir:** Fase 0 s.d. Fase 6 Selesai (`v0.6.0`)  
**Repository:** `https://github.com/Pramadsp/teduh.git` (Branch `main`)  
**Versi Terakhir:** `0.6.0+7`

---

## 📌 Status Terakhir Proyek
1. **Fase 0 (Setup Proyek):** Selesai (`v0.1.0`) - FVM Flutter 3.35.0, Package `com.nayanara.teduh`, Git & Secret protection.
2. **Fase 1 (UI & Navigasi):** Selesai (`v0.1.0`) - Material 3 Sage Theme, IDR Formatter, ShellRoute Bottom Navigation.
3. **Fase 2 (CRUD Transaksi):** Selesai (`v0.2.0`) - Form modal tambah/ubah, nominal IDR otomatis, hapus & undo.
4. **Fase 3 (Dashboard & Laporan):** Selesai (`v0.3.0`) - Filter WIB (Harian, Mingguan, Bulanan), kalkulator saldo, Donut Chart `fl_chart`.
5. **Fase 4 (Manajemen Kategori):** Selesai (`v0.4.0`) - Tab Kelola Kategori di Pengaturan, dialog tambah/edit, proteksi hapus kategori terpakai.
6. **Fase 5 (Firebase & Household):** Selesai (`v0.5.0`) - Firebase Auth (Email/Pass), Household 2 orang dengan kode 6 karakter, Firestore Real-Time Stream (`snapshots()`) & Offline Persistence.
7. **Perombakan UI Palette & Perbaikan Form (`v0.5.1` & `v0.6.0`):** Theme ProfileScreen (Krem, Pasir, Sage Dark, Terakota, Tinta) diterapkan seragam di semua layar. Peningkatan kontras tab unselected, DatePicker theme, serta penambahan field wajib **Nama Transaksi (`title`)**.
8. **Fase 6 (Ekspor PDF & Excel):** Selesai (`v0.6.0`) - Generator PDF (`pdf` + `printing`) dengan ringkasan & tabel multi-halaman rapi, Generator Excel (`excel`) dengan nominal bertipe Integer, terintegrasi dengan `open_filex` & `share_plus`.

---

## 🔜 Rencana Selanjutnya (Fase 7 - Penyempurnaan & Asset Polishing):
- Custom Adaptive Icon aplikasi Teduh (`flutter_launcher_icons`).
- Search Bar / Filter transaksi berdasarkan nama/catatan/kategori di `TransactionListScreen`.
- Empty & Loading State polishing di seluruh layar.
- Pencegahan overflow pada nominal angka besar.

---

## ⚠️ Catatan Peringatan / PR untuk Sesi Selanjutnya:
1. **Cloud Firestore API Disabled Error:**
   Log mendeteksi error `PERMISSION_DENIED: Cloud Firestore API has not been used in project teduh-7411e before or it is disabled`.
   - **Solusi:** Di Firebase Console / Google Cloud Console proyek `teduh-7411e`, pastikan Firestore Database sudah dibuat dalam mode production dan API Firestore sudah teraktifkan.
2. **Notifier Mounted Guard:**
   Saat logout / pergantian household, pastikan `TransactionsNotifier` dan `CategoriesNotifier` memeriksa properti `mounted` sebelum memanggil `state = ...` agar tidak melempar `Bad state: Tried to use TransactionsNotifier after dispose was called`.

---

## 🔜 Rencana Selanjutnya (Fase 6 - Ekspor PDF & Excel):
- Tombol **Ekspor** di Layar Laporan (pilihan format PDF atau Excel .xlsx).
- Ekspor mengikuti filter & periode yang sedang aktif.
- Generator PDF dengan ringkasan & tabel transaksi ber-halaman otomatis.
- Generator Excel dengan sheet Ringkasan & Transaksi (nominal integer agar bisa dijumlah).
- Integrasi `share_plus` & `open_filex`.
