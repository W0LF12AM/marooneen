# Marooneen - Smart Campus Attendance App 🎓

Marooneen adalah aplikasi absensi mahasiswa berbasis mobile (Android & iOS) yang dibangun menggunakan kerangka kerja **Flutter**. Aplikasi ini didesain sebagai prototipe sistem absensi kampus modern yang memadukan keamanan otentikasi biometrik dengan validasi lokasi geografis secara *real-time*.

## 🌟 Fitur Utama

1. **Autentikasi Aman & Manajemen Profil** 
   * Terintegrasi dengan Firebase Authentication (Login/Register).
   * Form *Setup Profile* wajib untuk pendataan Mahasiswa (NPM, Fakultas, Jurusan, Nomor HP, Gender).
   * Data profil immutable (hanya sekali isi) dan tersimpan aman di Cloud Firestore.

2. **Validasi Lokasi (Geofencing)** 🗺️
   * Menggunakan teknologi *Haversine formula* via library `geolocator`.
   * Sistem secara cerdas akan mengkalkulasi jarak *Latitude* dan *Longitude* Handphone pengguna dengan koordinat Kelas.
   * Toleransi presensi dapat diatur skalanya (misal: maksimal radiust 50 Meter dari titik absensi).

3. **Verifikasi Wajah AI (Face Recognition)** 🤖
   * Terintegrasi dengan **Google ML-Kit** pendeteksi wajah.
   * Perekaman wajah dan konversi foto menjadi vektor *Facial Embedding* (Array Numerik 192 Dimensi) melalui model TensorFlow Lite (`mobilefacenet.tflite`).
   * Mengamankan proses absensi (Anti Penitipan Absen) dengan mencocokkan wajah *real-time* ke wajah pendaftaran awal menggunakan kalkulasi komparasi **Euclidean Distance**.

4. **Deteksi Kedisiplinan Waktu (Hadir & Telat)** ⏳
   * Pengecekan *strict constraints* terhadap Hari H dan Jam *range* penjadwalan.
   * UI akan otomatis menyematkan *Badge Peringatan Merah* apabila mahasiswa presensi di luar jam kuliah. 

5. **Antarmuka Premium & Modern** 🎨
   * Dilengkapi library desain *Shadcn UI* dengan ikon dari *Lucide Icons*.
   * Menggunakan konsep Avatar dinamis, Tab Navigasi responsif, *Snackbar* notifikasi elegan, dan efek visual kelas *App Startup* masa kini.

## 🛠️ Tech Stack & Librari

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Backend / Database:** [Firebase](https://firebase.google.com/) (Firestore & Auth)
- **Machine Learning / AI:** [Google ML-Kit Vision](https://developers.google.com/ml-kit) & [TFLite Flutter](https://pub.dev/packages/tflite_flutter) (MobileFaceNet Model)
- **Geolocation:** [Geolocator Pakcage](https://pub.dev/packages/geolocator)
- **UI Components:** [Shadcn UI for Flutter](https://pub.dev/packages/shadcn_ui)

## ⚙️ Persyaratan (Requirements)

Sebelum menjalankan *project* ini secara lokal, pastikan Anda telah mempersiapkan:
1. Flutter SDK versi terbaru.
2. File Model TFLite `mobilefacenet.tflite` (Minimal disimpan di dalam folder root direktori `/assets`).
3. Konfigurasi `firebase_options.dart` beserta JSON otentikasi standar (tidak disematkan pada github ini untuk alasan keamanan privasi dan *billing* server).

## 🚀 Cara Menjalankan Aplikasi

1. Lakukan kloning *repository*.
   ```bash
   git clone https://github.com/username-anda/marooneen.git
   ```
2. Pindah ke direktori *project*.
   ```bash
   cd marooneen
   ```
3. Tarik seluruh dependensi dari `pubspec.yaml`.
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi (Disarankan di perangkat ASLI (HP) karena memerlukan kapabilitas GPS dan Kamera aktif).
   ```bash
   flutter run
   ```

***

> **Catatan untuk Developer:** File seperti konfig Firebase (`google-services.json` dsb) secara eksklusif telah dimasukkan ke dalam `.gitignore`. Anda perlu membuat *Project Firebase* Anda sendiri untuk menghubungkan fungsionalitas Backend aplikasi.
