# Rules & Guideline Proyek Teduh

Dokumen ini berisi aturan kerja wajib (project guidelines) yang harus selalu dibaca dan dipatuhi pada setiap sesi percakapan/pengembangan di repository **Teduh**.

---

## 📌 1. Aturan Review Kode (Ponytail & Mothership)
- Setiap selesai melakukan perubahan kode (menulis, mengedit, atau meretaut/refactor file source), WAJIB melakukan code review dengan **`ponytail-review`** dan MCP Mothership (jika Mothership aktif).
- Terapkan temuan yang mengeliminasi kompleksitas berlebihan tanpa mengubah perilaku bisnis.
- Pengecualian: Output UI/UX dari `@designer` (karena layout & interaksi adalah intent desain asli).

## 💰 2. Konsultasi Keuangan / Financial (Wajib & Harus)
- Jika sedang membahas, mengembangkan, merencanakan, atau butuh konsultasi terkait alur/flow keuangan (pencatatan uang masuk/keluar, saldo, laporan, fee, settlement, dll.) — WAJIB berkonsultasi dengan **Mothership MCP** untuk mendapatkan arahan financial sebelum melanjutkan/menyimpulkan.

## 🔢 3. Metode Versioning (Semantic Versioning Standard)
Setiap rilis/update ke Git wajib menerapkan skema penomoran versi berikut di `pubspec.yaml` & dokumen release notes:
- **Perbaikan Bug / UI Patch:** Tambahkan 1 pada digit terakhir (Patch). Contoh: `v0.6.0` ➔ `v0.6.1`.
- **Penyelesaian Fase / Fitur Baru:** Tambahkan 1 pada digit kedua (Minor). Contoh: `v0.6.0` ➔ `v0.7.0`.
- **Seluruh Fase Selesai / Major Rilis:** Tambahkan 1 pada digit depan (Major). Contoh: `v0.7.0` ➔ `v1.0.0`.

## 🔍 4. Double Check & Crosscheck Fungsionalitas
- Selalu melakukan *double check* dan regression test pada seluruh fitur/fungsi setelah melakukan perubahan kode.
- Pastikan perubahan atau penambahan fitur baru **TIDAK MENYENGGOL** atau merusak fitur existing yang sudah berjalan.

## 🤝 5. Konfirmasi Proaktif & Git Commit Rules
- **Konfirmasi Rencana:** Selalu konfirmasi rencana perubahan dan dampaknya (*Impact*) kepada user sebelum mengeksekusi.
- **Konfirmasi Commit:** WAJIB minta izin/konfirmasi ke user sebelum melakukan `git commit` & `git push`.
- **Pesan Commit:** Format pesan commit cukup **Title + Deskripsi Pekerjaan yang jelas**. **DILARANG** menambahkan footer/trailer identitas apa pun (seperti `Co-authored-by:`, `Signed-off-by:`, nama AI agent, atau atribusi tool).

## 📖 6. Alur Awal Sesi Baru
- Setiap memulai sesi baru, SEBELUM mengerjakan apa pun, baca folder `docs/` (terutama `docs/handoff.md` dan `docs/planning-aplikasi-keuangan-flutter.md`) untuk memahami progress terakhir dan konvensi proyek.
