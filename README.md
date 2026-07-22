# PT AR MULTI KARYA BOROBUDUR - Internal Control Application

Aplikasi Web Internal Control (Offline-First) untuk pengelolaan inventaris, purchasing, invoice penjualan, dan rekap laba rugi. Aplikasi ini menggunakan teknologi berbasis client-side murni dengan IndexedDB untuk persistensi data relasional yang andal langsung di peramban (browser) pengguna tanpa perlu server terpisah.

---

## 🚀 Fitur Utama

1. **Keamanan & Autentikasi Pengguna**:
   * Hashing password dengan algoritma **SHA-256** (Web Crypto API).
   * **Role-Based Access Control (RBAC)** untuk 3 tipe akun demo bawaan:
     * **Admin** (`admin` / `admin`): Akses penuh ke seluruh modul.
     * **Staff Gudang** (`staff` / `staff`): Mengelola barang dan menerima bukti pembelian.
     * **Finance** (`finance` / `finance`): Mengelola harga, invoice penjualan, dan rekap laba rugi.

2. **Manajemen Inventaris & Supplier**:
   * CRUD Supplier & Master Barang terintegrasi.
   * **Ekspor & Impor Excel (via SheetJS)** untuk masukan data barang secara masal.

3. **Purchase Order (PO) & Bukti Penerimaan**:
   * Pembuatan PO dengan opsi jenis **Barang / Jasa**, deskripsi, dan referensi pelanggan.
   * Penarikan harga standar otomatis dari Price List terbaru.
   * Pencatatan Bukti Pembelian dengan **unggahan berkas fisik (Base64)** dan penambahan stok otomatis secara transaksional (atomic transaction).

4. **Katalog Harga (Price List) & Pengingat Update**:
   * Riwayat harga tersimpan lengkap (tidak menimpa data lama).
   * Notifikasi banner di Dashboard & Price List jika ada barang yang harga jual/beli standardnya belum diperbarui lebih dari 7 hari.

5. **Invoice Penjualan (Sales Invoice)**:
   * Pengurangan stok transaksional saat invoice disimpan.
   * Validasi/pengecekan ketersediaan stok sebelum invoice dibuat untuk mencegah stok minus.
   * Kalkulasi **Pajak PT sebesar 2%** dari nominal subtotal dikurangi diskon secara otomatis.
   * Cetak Faktur (Print-friendly) berstandar industri dengan format terbilang nominal otomatis.

6. **Rekap Laba Rugi Perusahaan**:
   * Filter neraca keuangan berdasarkan range tanggal yang dinamis.
   * Perhitungan total penjualan, harga pokok penjualan (HPP), potongan diskon, pajak PT, dan laba bersih.
   * Ekspor laporan laba rugi terfilter ke format Microsoft Excel.

7. **Audit Trail & Pemeliharaan Database**:
   * Log riwayat aktivitas secara real-time pada setiap perubahan database.
   * Fitur **Ekspor Backup JSON** dan **Restore Database** untuk mengamankan data secara lokal.

---

## 🛠️ Tech Stack & Dependensi

* **User Interface & Logika**: React.js (via CDN Babel-standalone & UMD build)
* **CSS & Tema**: TailwindCSS (UI Modern & Glassmorphism)
* **Database lokal**: IndexedDB (API Native Browser)
* **Pengolah Excel**: SheetJS / XLSX Library (via CDN)
* **Ikonografi**: Lucide Icons (via CDN)

---

## 📦 Cara Menjalankan Aplikasi

Aplikasi ini bersifat **portabel (single-file)** dan dapat dijalankan langsung di peramban modern tanpa konfigurasi server backend (Node.js/Python).

### Langkah Menjalankan:
1. Unduh atau clone repositori ini ke folder lokal Anda.
2. Buka berkas [**`index.html`**](file:///c:/aplikasi/PT%20AR%20MLTI%20KARYA%20BOROBUDUR/index.html) menggunakan peramban web pilihan Anda (Google Chrome, Microsoft Edge, Firefox, Safari).
3. Selamat! Aplikasi langsung siap digunakan.

---

## 🔑 Akun Uji Coba Default

| Username | Password | Role |
|---|---|---|
| `admin` | `admin` | Administrator |
| `staff` | `staff` | Staff Gudang |
| `finance` | `finance` | Keuangan |

---

## 💾 Struktur Penyimpanan IndexedDB

Database lokal diberi nama `PT_AR_MultiKarya_DB` dengan 9 Object Store sebagai berikut:
1. `users`: Menyimpan kredensial pengguna terenkripsi SHA-256.
2. `suppliers`: Menyimpan data profil pemasok barang.
3. `barang`: Menyimpan data katalog inventaris dan stok real-time.
4. `price_lists`: Riwayat harga beli dan harga jual standard barang.
5. `po`: Data transaksi Purchase Order (PO).
6. `bukti_pembelian`: Catatan tanda terima PO yang menambah stok barang.
7. `invoice_jual`: Invoice penjualan yang mengurangi stok barang.
8. `customers`: Informasi pelanggan.
9. `logs`: Log audit aktivitas sistem (Audit Trail).
10. `settings`: Profil perusahaan dan detail bank penerima transfer.
