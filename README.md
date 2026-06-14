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

## 🚀 Panduan Clone & Instalasi Proyek (Step-by-Step)

Berikut adalah panduan lengkap untuk melakukan *cloning* repositori dan menjalankan aplikasi Goatcheck di lingkungan lokal Anda.

### 📋 Prasyarat Sistem
Sebelum memulai, pastikan komputer Anda telah terinstal:
1. **Git**: Untuk meng-clone repositori ([Download Git](https://git-scm.com/)).
2. **Flutter SDK**: Gunakan Flutter versi stabil terbaru (minimum versi `3.10.7` sesuai `pubspec.yaml`). ([Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install)).
3. **Android Studio** atau **VS Code**: Dilengkapi dengan ekstensi **Flutter** dan **Dart**.
4. **Android SDK & Build Tools**: Diperlukan untuk melakukan build aplikasi Android.
5. **Perangkat/Emulator**: Emulator Android (AVD) atau HP Android fisik dengan fitur USB Debugging aktif.

---

### 📥 Langkah 1: Kloning Repositori (Clone)
Buka terminal (Command Prompt, PowerShell, atau Git Bash) di komputer Anda, lalu jalankan perintah berikut:

```bash
# Clone repositori ke lokal
git clone https://github.com/Grimpascal/goatcheck.git

# Masuk ke direktori hasil clone
cd goatcheck
```

---

### ⚙️ Langkah 2: Instalasi Dependensi (Installation & Setup)
Jalankan perintah ini di root direktori proyek untuk mendownload dan mengintegrasikan seluruh library/package Flutter yang digunakan (seperti Firebase, Flutter Background Service, dll.):

```bash
flutter pub get
```

Jika Anda ingin memastikan instalasi lingkungan Flutter Anda sudah lengkap dan tidak ada masalah konfigurasi, Anda dapat memeriksa dengan perintah:
```bash
flutter doctor
```

---

### 🔑 Langkah 3: Konfigurasi Firebase (Opsional)
Proyek ini sudah dilengkapi file konfigurasi default Android di path:
`android/app/google-services.json`

*Catatan:* Jika Anda ingin menggunakan database Firebase milik Anda sendiri:
1. Daftarkan aplikasi di [Firebase Console](https://console.firebase.google.com/).
2. Unduh file `google-services.json` yang baru dari Firebase Console.
3. Timpa file lama di path [android/app/google-services.json](file:///d:/PBM/goatcheck/android/app/google-services.json) dengan file yang baru diunduh.
4. Sesuaikan konfigurasi inisialisasi Firebase (seperti `apiKey` dan `appId` untuk latar belakang) pada file [background_service.dart](file:///d:/PBM/goatcheck/lib/services/background_service.dart#L48-L53) jika diperlukan.

---

### 📱 Langkah 4: Menjalankan Aplikasi (Running)
1. Sambungkan HP Android fisik Anda melalui kabel USB (pastikan USB Debugging aktif) atau jalankan Emulator Android dari Android Studio / VS Code.
2. Periksa apakah perangkat terdeteksi dengan perintah:
   ```bash
   flutter devices
   ```
3. Jalankan aplikasi menggunakan perintah berikut:
   ```bash
   flutter run
   ```
4. Jika Anda menggunakan VS Code, Anda juga bisa menekan tombol `F5` untuk menjalankan aplikasi dalam mode *Debugging*.

---

### 🛠️ Troubleshooting & Tips
- **Error pada Gradle**: Jika mengalami masalah *build* Gradle pertama kali, jalankan `flutter clean` lalu ulangi `flutter pub get` dan `flutter run`.
- **Izin Background Service**: Karena aplikasi ini menggunakan `flutter_background_service` untuk monitoring suhu $\ge 35^\circ\text{C}$ di latar belakang, pastikan memberikan izin autostart dan mematikan penghemat baterai khusus untuk aplikasi Goatcheck pada HP Android Anda agar background service dapat berjalan optimal.
