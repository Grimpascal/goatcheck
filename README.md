# 🐐 Goatcheck

Goatcheck adalah aplikasi berbasis Flutter yang dirancang untuk memantau kesehatan dan aktivitas kambing secara real-time menggunakan teknologi IoT dan integrasi Firebase. Aplikasi ini membantu peternak melacak kondisi fisik hewan ternak secara real-time dan memberikan peringatan otomatis jika mendeteksi anomali pada parameter kesehatan kambing (seperti suhu tubuh yang terlalu tinggi).

---

## 🌟 Fitur Utama
- **Autentikasi Pengguna**: Login, registrasi, reset password, dan pembaruan profil peternak.
- **Monitoring IoT Real-Time**: Integrasi langsung dengan Cloud Firestore untuk memantau status koneksi, suhu, aktivitas, dan posisi gyro kambing.
- **Background Service**: Layanan latar belakang yang tetap berjalan untuk memantau suhu kambing secara terus-menerus.
- **Notifikasi Peringatan**: Mengirimkan notifikasi lokal secara instan apabila suhu tubuh kambing terdeteksi tinggi ($\ge 35.0^\circ\text{C}$).
- **Dashboard Ringkasan**: Menampilkan metrik agregat dari seluruh hewan ternak, termasuk jumlah hewan, rata-rata suhu, dan rata-rata tingkat aktivitas kelompok.

---

## 🛠️ Arsitektur & Teknologi
- **Frontend**: Flutter (Dart)
- **Database**: Cloud Firestore (Real-time database)
- **Autentikasi**: Firebase Auth
- **Layanan Latar Belakang**: `flutter_background_service`
- **Notifikasi**: `flutter_local_notifications`

---

## 📊 Penjelasan Detail Penghitungan Parameter Agregat

Dashboard Goatcheck menampilkan ringkasan parameter utama kelompok kambing. Berikut adalah penjelasan mekanisme penghitungan **Rata-rata Suhu** dan **Rata-rata Aktivitas**:

### 1. Rata-rata Suhu (Average Temperature)
Penghitungan rata-rata suhu kelompok kambing dilakukan melalui tahap-tahap berikut:
- **Pengumpulan Data**: Aplikasi mengambil data suhu dari koleksi `perangkat_iot` di Firestore untuk setiap kambing.
- **Pembersihan & Parsing**: Mengingat data IoT dapat dikirim dalam bentuk teks (string), nilai suhu diproses terlebih dahulu menggunakan fungsi `parseMetricValue` di `KambingController`. Fungsi ini:
  - Mengabaikan string kosong atau bernilai `"-"`.
  - Mengganti tanda koma (`,`) menjadi titik (`.`) untuk standarisasi format desimal.
  - Menggunakan ekspresi reguler (Regex) `[+-]?\d+(?:\.\d+)?` untuk mengekstrak angka pertama yang ditemukan.
- **Kalkulasi**: Semua nilai suhu yang berhasil diparsing dijumlahkan, kemudian dibagi dengan total perangkat yang memiliki data suhu valid.
  $$\text{Rata-rata Suhu} = \frac{\sum \text{Suhu Valid}}{\text{Jumlah Perangkat dengan Suhu Valid}}$$
- **Tampilan**: Hasil pembagian diformat menjadi 1 angka di belakang koma (contoh: `37.5°C`).

---

### 2. Rata-rata Aktivitas (Average Activity)
Aktivitas kambing yang diterima dari perangkat IoT diklasifikasikan dan dihitung rata-ratanya secara tertimbang (weighted average).

#### A. Klasifikasi Aktivitas
Data aktivitas dari IoT (baik berupa teks maupun angka) diklasifikasikan ke dalam 4 kategori utama melalui fungsi `classifyActivity` di `KambingController`:

| Kategori | Kata Kunci Pencarian (Case Insensitive) | Nilai Sensor (Jika Numerik) | Bobot Nilai |
| :--- | :--- | :--- | :---: |
| **Diam** | `"diam"`, `"tidur"`, `"sleep"`, `"istirahat"`, `"rest"` | $< 10.0$ | **1** |
| **Lambat** | `"lambat"`, `"jalan"`, `"pelan"`, `"slow"`, `"walk"` | $\ge 10.0$ dan $< 30.0$ | **2** |
| **Aktif** | `"aktif"`, `"lari"`, `"berlari"`, `"run"`, `"makan"`, `"eat"`, `"active"`, `"bergerak"` | $\ge 30.0$ dan $< 60.0$ | **3** |
| **Sangat Aktif** | `"sangat aktif"`, `"very active"`, `"sangat bergerak"` | $\ge 60.0$ | **4** |

#### B. Penghitungan Rata-rata Tertimbang (Weighted Average)
Setelah semua perangkat diklasifikasikan, aplikasi menghitung rata-rata aktivitas kelompok dengan memberikan bobot nilai pada setiap kategori:
1. Hitung jumlah perangkat pada masing-masing kategori: `diamCount`, `lambatCount`, `aktifCount`, dan `sangatAktifCount`.
2. Hitung total perangkat terklasifikasi:
   $$\text{Total Terklasifikasi} = \text{diamCount} + \text{lambatCount} + \text{aktifCount} + \text{sangatAktifCount}$$
3. Hitung skor rata-rata tertimbang:
   $$\text{Skor Rata-rata} = \frac{(\text{diamCount} \times 1) + (\text{lambatCount} \times 2) + (\text{aktifCount} \times 3) + (\text{sangatAktifCount} \times 4)}{\text{Total Terklasifikasi}}$$
4. Bulatkan skor rata-rata ke integer terdekat (`round()`) dan petakan kembali ke label tampilan dashboard:
   - Skor **1** $\rightarrow$ **"Banyak Diam"**
   - Skor **2** $\rightarrow$ **"Lambat"**
   - Skor **3** $\rightarrow$ **"Aktif"**
   - Skor **4** $\rightarrow$ **"Sangat Aktif"**

---

## 🚀 Cara Menjalankan Projek
1. Pastikan Anda telah menginstal [Flutter SDK](https://docs.flutter.dev/get-started/install) versi terbaru.
2. Clone repositori ini ke komputer lokal Anda.
3. Jalankan perintah berikut untuk mengunduh semua dependensi proyek:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi di emulator atau perangkat fisik Anda:
   ```bash
   flutter run
   ```
