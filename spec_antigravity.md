# Spesifikasi Aplikasi Internal Control - PT AR Multi Karya
> Dokumen ini digunakan sebagai prompt/spec untuk AI coding agent (Antigravity) dalam membangun aplikasi secara end-to-end. Seluruh modul harus saling terhubung melalui relasi data (foreign key) sehingga tidak ada modul yang berdiri sendiri.

## 1. Ringkasan Aplikasi
Aplikasi web internal control untuk mengelola supplier, barang, price list, customer, purchase order (PO), bukti pembelian, invoice penjualan, dan rekap laba rugi dengan pajak PT 2%. Semua modul terintegrasi dalam satu alur data (data flow) dari pembelian sampai penjualan dan laporan keuangan.

## 2. Tech Stack yang Disarankan
- Frontend: React.js / Next.js (atau Streamlit untuk versi cepat/prototipe)
- Backend: Node.js (Express) / Python (FastAPI)
- Database: PostgreSQL / MySQL (relasional, wajib mendukung foreign key)
- Autentikasi: JWT / session-based login dengan password hashing (bcrypt/SHA-256)
- File storage: local storage atau cloud (untuk upload bukti pembelian & import Excel)
- Library Excel: openpyxl / xlsx (import & export)

## 3. Alur Data & Keterhubungan Antar Modul (WAJIB DIIKUTI)
Setiap modul TIDAK boleh berdiri sendiri. Berikut alur relasi data end-to-end:

1. **Supplier** menjadi sumber untuk **Data Barang** (setiap barang punya `supplier_id`).
2. **Data Barang** menjadi sumber untuk **Price List** (setiap price list punya `barang_id`, riwayat harga per barang).
3. **Supplier + Barang** menjadi dasar pembuatan **PO Barang/Jasa** (PO mereferensikan `supplier_id` dan bisa multiple `barang_id` melalui tabel detail PO).
4. **PO** yang statusnya "Selesai" menjadi dasar pembuatan **Bukti Pembelian/Invoice Pembelian** (bukti pembelian mereferensikan `po_id` dan `supplier_id`), dan otomatis menambah **stok barang**.
5. **Customer** menjadi dasar pembuatan **PO Penjualan** (opsional, jika PO juga dipakai untuk penjualan) dan **Invoice Penjualan**.
6. **Data Barang + Price List** menjadi sumber harga jual di **Pembuatan Invoice** (harga jual otomatis ditarik dari price list terbaru, HPP ditarik dari harga beli terbaru), dan otomatis mengurangi **stok barang**.
7. **Invoice Penjualan** dihitung dengan **Pajak PT 2%** dari subtotal, menghasilkan total invoice.
8. **Rekap Laba Rugi** mengambil data dari **Invoice Penjualan** (total penjualan, HPP, pajak) dikurangi **Bukti Pembelian** (total pembelian) untuk menghasilkan laba kotor dan laba bersih, dapat difilter berdasarkan rentang tanggal.
9. **Dashboard** menampilkan agregat real-time dari SEMUA modul di atas (jumlah supplier, barang, customer, PO aktif, total penjualan, total pembelian, estimasi laba).

Diagram alur singkat:
```
Supplier -> Barang -> Price List
                |
                v
Supplier + Barang -> PO -> Bukti Pembelian -> (update stok +) 
                                |
Customer -> Invoice Penjualan <-- Price List (harga jual & HPP)
                |
                v
        (update stok -) -> Pajak 2% -> Total Invoice
                |
                v
        Rekap Laba Rugi (filter tanggal) <- Bukti Pembelian (total pembelian)
                |
                v
            Dashboard (agregat semua modul)
```

## 4. Skema Database (Relasional, WAJIB Foreign Key)

### Tabel `users`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| username | VARCHAR UNIQUE | |
| password | VARCHAR | hashed |
| role | VARCHAR | admin/staff/finance |

### Tabel `supplier`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| nama | VARCHAR | |
| kontak | VARCHAR | |
| alamat | TEXT | |
| email | VARCHAR | |
| npwp | VARCHAR | |

### Tabel `barang`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| kode | VARCHAR UNIQUE | |
| nama | VARCHAR | |
| kategori | VARCHAR | |
| satuan | VARCHAR | |
| stok | DECIMAL | update otomatis dari PO & Invoice |
| supplier_id | INTEGER FK -> supplier.id | |

### Tabel `price_list`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| barang_id | INTEGER FK -> barang.id | |
| harga_beli | DECIMAL | |
| harga_jual | DECIMAL | |
| tanggal_update | DATE | trigger update mingguan |

### Tabel `customer`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| nama | VARCHAR | |
| kontak | VARCHAR | |
| alamat | TEXT | |
| email | VARCHAR | |
| npwp | VARCHAR | |

### Tabel `po` (Purchase Order Barang/Jasa)
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| no_po | VARCHAR UNIQUE | |
| tanggal | DATE | |
| jenis | VARCHAR | Barang/Jasa |
| supplier_id | INTEGER FK -> supplier.id | |
| customer_id | INTEGER FK -> customer.id NULLABLE | |
| barang_id | INTEGER FK -> barang.id | |
| deskripsi | TEXT | |
| qty | DECIMAL | |
| harga | DECIMAL | ditarik dari price_list |
| total | DECIMAL | qty x harga |
| status | VARCHAR | Draft/Diproses/Selesai/Batal |

### Tabel `bukti_pembelian`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| no_invoice_beli | VARCHAR | |
| po_id | INTEGER FK -> po.id | |
| supplier_id | INTEGER FK -> supplier.id | |
| tanggal | DATE | |
| total | DECIMAL | |
| file_bukti | VARCHAR | path upload |

### Tabel `invoice_jual`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| no_invoice | VARCHAR UNIQUE | |
| customer_id | INTEGER FK -> customer.id | |
| barang_id | INTEGER FK -> barang.id | |
| tanggal | DATE | |
| deskripsi | TEXT | |
| qty | DECIMAL | |
| harga_jual | DECIMAL | ditarik dari price_list |
| subtotal | DECIMAL | qty x harga_jual |
| pajak_persen | DECIMAL | default 2 |
| pajak_nominal | DECIMAL | subtotal x pajak_persen/100 |
| total | DECIMAL | subtotal + pajak_nominal |
| hpp | DECIMAL | qty x harga_beli (dari price_list) |

## 5. Modul & Fungsional Detail

### 5.1 Login
- Autentikasi username & password (hashed).
- Session/token disimpan untuk validasi akses ke semua menu lain.

### 5.2 Dashboard
- Tampilkan card metrik: total supplier, total barang, total customer, total PO aktif, total penjualan, total pembelian, estimasi laba.
- Data ditarik real-time dari tabel supplier, barang, customer, po, invoice_jual, bukti_pembelian.

### 5.3 Data Supplier
- CRUD (Create, Read, Update, Delete).
- Field pencarian/filter berdasarkan nama.
- Relasi ke: barang, po, bukti_pembelian.

### 5.4 Data Barang
- Input satu per satu (form manual) DAN import massal via file Excel (kolom: kode, nama, kategori, satuan, stok, supplier).
- Filter berdasarkan kategori dan pencarian nama/kode.
- Export data barang ke Excel.
- Stok otomatis bertambah saat Bukti Pembelian dibuat, berkurang saat Invoice Penjualan dibuat.
- Relasi ke: supplier, price_list, po, invoice_jual.

### 5.5 Price List
- Update harga beli & harga jual per barang, dengan riwayat tersimpan (tidak overwrite, tapi tambah baris baru per update).
- Sistem reminder/scheduler untuk update setiap 1 minggu sekali (cron job atau notifikasi in-app).
- Harga terbaru (`ORDER BY tanggal_update DESC LIMIT 1`) dipakai otomatis sebagai default harga di PO dan Invoice Penjualan.

### 5.6 Data Customer
- CRUD sederhana (nama, kontak, alamat, email, NPWP).
- Relasi ke: po (opsional), invoice_jual.

### 5.7 PO Barang/Jasa
- Input PO dengan jenis Barang atau Jasa.
- Pilih supplier dan barang (harga otomatis dari price_list terbaru).
- Status PO: Draft, Diproses, Selesai, Batal.
- PO status "Selesai" memicu pembuatan Bukti Pembelian secara manual/otomatis.

### 5.8 Bukti Pembelian (Invoice Pembelian)
- Referensi ke PO yang sudah selesai.
- Upload file bukti (PDF/gambar).
- Saat disimpan, stok barang terkait otomatis bertambah sesuai qty PO.

### 5.9 Pembuatan Invoice (Penjualan)
- Pilih customer dan barang (harga jual & HPP otomatis dari price_list terbaru).
- Hitung otomatis: subtotal = qty x harga_jual, pajak = subtotal x 2%, total = subtotal + pajak.
- Saat disimpan, stok barang terkait otomatis berkurang sesuai qty.

### 5.10 Rekap Laba Rugi
- Filter berdasarkan rentang tanggal (dari-sampai).
- Hitung: Total Penjualan (subtotal invoice_jual), Total HPP, Laba Kotor (Penjualan - HPP), Pajak PT 2%, Laba Bersih (Laba Kotor - Pajak), Total Pembelian (dari bukti_pembelian).
- Export hasil rekap ke Excel.

## 6. Aturan Pajak
- Pajak PT diterapkan otomatis sebesar 2% dari subtotal setiap invoice penjualan.
- Formula: `Total Invoice = Subtotal + (Subtotal x 2%)`.
- Laba Bersih = (Subtotal - HPP) - Pajak PT.

## 7. Non-Functional Requirements
- Semua tabel harus menggunakan foreign key constraint agar integritas data antar modul terjaga (tidak boleh ada data barang tanpa supplier valid, invoice tanpa customer valid, dsb).
- Gunakan transaction/atomic operation saat update stok bersamaan dengan insert PO/Invoice agar data tidak inkonsisten.
- Sediakan validasi input di setiap form (misal qty & harga tidak boleh negatif).
- Sediakan role-based access control (admin, staff gudang, finance) sebagai pengembangan lanjutan.
- Aplikasi harus responsive dan dapat diakses multi-user secara bersamaan (gunakan database server, bukan file lokal, untuk versi produksi).

## 8. Output yang Diharapkan dari Antigravity
1. Struktur folder proyek lengkap (backend, frontend/UI, database migration script).
2. Skema database dengan foreign key sesuai bagian 4.
3. Implementasi seluruh 9 modul di bagian 5, saling terhubung sesuai alur di bagian 3.
4. Kalkulasi pajak PT 2% otomatis di modul invoice sesuai bagian 6.
5. Dokumentasi cara instalasi dan menjalankan aplikasi (README.md).
