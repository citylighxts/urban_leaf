# UrbanLeaf AI 🌿

UrbanLeaf AI adalah aplikasi mobile berbasis Flutter yang membantu masyarakat urban melakukan urban farming secara lebih cerdas menggunakan kombinasi AI, Machine Learning, dan Weather Forecast API. Aplikasi ini dirancang untuk membantu pengguna memantau kondisi tanaman, mendeteksi penyakit tanaman melalui AI, serta memberikan rekomendasi perawatan berdasarkan kondisi cuaca real-time dan prediksi cuaca beberapa hari ke depan.

UrbanLeaf AI memanfaatkan GPS pengguna untuk mengambil data cuaca dari Open-Meteo API seperti:

- Suhu (`temperature_2m`)
- Kelembapan (`relative_humidity_2m`)
- Curah hujan (`precipitation`)
- Probabilitas hujan (`rain_probability`)
- UV Index (`uv_index`)

Data tersebut dianalisis dan dikaitkan dengan profil tanaman pengguna untuk menghasilkan:

- Smart alert otomatis
- Rekomendasi perawatan tanaman
- Prediksi risiko penyakit tanaman
- Monitoring kesehatan tanaman berbasis AI

---

# 👨‍💻 Tim Pengembang


| No | Nama | NRP | Tugas |
|----|------|------|--------|
| 1 | Hana Azizah Nurhadi | 5025231134 | Create membuat alert otomatis berdasarkan kondisi cuaca ekstrem, Read menampilkan daftar notifikasi dan peringatan tanaman, Update mengubah status alert menjadi aman atau ditangani, Delete menghapus alert lama yang sudah tidak relevan. |
| 2 | Samuel Steve Mulyono | 5025231197 | Create menambahkan tanaman baru ke Kebunku, Read menampilkan daftar dan detail tanaman pengguna, Update mengubah informasi serta status perawatan tanaman, Delete menghapus tanaman dari database kebun pengguna. |
| 3 | Haliza Nur Kamila Apalwan | 5025231038 | Create menyimpan hasil scan AI penyakit tanaman, Read menampilkan riwayat diagnosis dan hasil analisis AI, Update memperbarui status perkembangan penyakit setelah perawatan, Delete menghapus riwayat diagnosis yang tidak diperlukan. |

---

# 🎯 Tujuan Aplikasi

UrbanLeaf AI bertujuan membantu masyarakat urban untuk:

- Mengelola tanaman secara lebih efisien
- Mengurangi risiko gagal panen
- Mendeteksi penyakit tanaman lebih awal
- Menyesuaikan perawatan tanaman berdasarkan kondisi cuaca
- Mendukung gaya hidup berkelanjutan dan urban farming modern

---

# 🌍 Dukungan Sustainable Development Goals (SDGs)

Aplikasi mendukung beberapa tujuan SDGs:

- **SDG 12** — Responsible Consumption and Production

---

# 📱 Struktur Halaman Aplikasi

## 1. Home Page (Dashboard Utama)

Halaman utama yang pertama kali dilihat pengguna saat membuka aplikasi.

Dashboard bersifat dinamis dan menyesuaikan kondisi cuaca serta kesehatan tanaman pengguna secara real-time.

### ✨ Fitur

- Weather Widget berbasis GPS pengguna
- Informasi suhu, kelembapan, UV Index, dan kondisi cuaca
- Garden Status Overview:
  - Tanaman sehat
  - Butuh perhatian
  - Karantina
- Dynamic Alert Banner berbasis AI
- Ringkasan tanaman yang membutuhkan tindakan segera

### 📌 Contoh Alert

> “Peringatan! Suhu hari ini mencapai 34°C. Selada Hidroponik Anda berisiko mengalami heat stress.”

---

## 2. Kebunku Page (Plant Management)

Halaman utama CRUD untuk mengelola seluruh tanaman pengguna.

### ✨ Fitur

- List/Grid seluruh tanaman pengguna
- Floating Action Button (+) untuk menambah tanaman
- Filter status tanaman:
  - Semua
  - Sehat
  - Butuh Perhatian
  - Karantina
- Status kesehatan tanaman diperbarui otomatis berdasarkan:
  - Analisis AI
  - Kondisi cuaca

### 🌱 Detail Tanaman

Saat tanaman dipilih, pengguna dapat melihat:

- Umur tanaman
- Jadwal penyiraman
- Riwayat penyakit
- Riwayat perawatan
- Rekomendasi tindakan berdasarkan cuaca

---

## 3. AI Scanner Page (Deteksi Penyakit Tanaman)

Halaman berbasis Machine Learning untuk mendeteksi penyakit tanaman menggunakan kamera smartphone.

### ✨ Fitur

- Camera viewport untuk scan daun tanaman
- Upload gambar dari galeri
- AI disease classification
- Analisis tingkat keparahan penyakit
- Solusi penanganan dan perawatan
- Simpan hasil diagnosis ke tanaman tertentu

### 📌 Contoh Hasil Diagnosis

> “Terdeteksi Early Blight dengan tingkat keparahan sedang. Disarankan melakukan pemangkasan daun yang terinfeksi.”

---

## 4. Edukasi Page (Urban Farming Guide)

Halaman edukasi untuk membantu pengguna memahami urban farming.

### ✨ Fitur

- Artikel urban farming
- Tips menghadapi cuaca ekstrem
- Tutorial perawatan tanaman
- Kalender tanam berbasis tren cuaca wilayah pengguna
- Rekomendasi tanaman yang cocok ditanam bulan ini

---

# 🌱 3 Fitur Utama CRUD

## 1. Manajemen Tanaman Pengguna (CRUD)

### 🎯 Fokus

Mengelola data tanaman milik pengguna pada halaman Kebunku.

### 🔧 CRUD Operations

#### Create
Menambahkan tanaman baru lengkap dengan:
- Jenis tanaman
- Metode tanam
- Tanggal tanam
- Lokasi tanaman

#### Read
Menampilkan:
- Daftar tanaman
- Status kesehatan tanaman
- Kondisi terbaru tanaman

#### Update
Mengubah:
- Jadwal penyiraman
- Lokasi tanaman
- Catatan perawatan

#### Delete
Menghapus tanaman dari daftar kebun pengguna.

---

## 2. AI Diagnosis & Riwayat Penyakit (CRUD)

### 🎯 Fokus

Menyimpan dan mengelola hasil diagnosis penyakit tanaman berbasis AI.

### 🔧 CRUD Operations

#### Create
Menyimpan:
- Hasil scan AI
- Diagnosis penyakit tanaman

#### Read
Menampilkan:
- Riwayat diagnosis
- Nama penyakit
- Solusi penanganan

#### Update
Memperbarui:
- Status perkembangan penyakit
- Kondisi tanaman setelah perawatan

#### Delete
Menghapus:
- Riwayat diagnosis yang salah
- Data diagnosis yang tidak diperlukan

---

## 3. Smart Alert & Monitoring Cuaca (CRUD)

### 🎯 Fokus

Mengelola alert otomatis berdasarkan kondisi cuaca dan kesehatan tanaman.

### 🔧 CRUD Operations

#### Create
Sistem membuat alert otomatis ketika:
- Suhu terlalu tinggi
- Risiko jamur meningkat
- Cuaca ekstrem terdeteksi

#### Read
Menampilkan:
- Alert heat stress
- Risiko jamur
- Peringatan cuaca ekstrem

#### Update
Mengubah status alert menjadi:
- Ditangani
- Aman
- Update threshold notifikasi

#### Delete
Menghapus:
- Alert lama
- Notifikasi yang sudah tidak relevan

---

# 🛠️ Teknologi yang Digunakan

## Frontend
- Flutter
- Dart

## Backend & API
- Open-Meteo API
- GPS / Geolocation API

## Artificial Intelligence
- Machine Learning Image Classification
- Plant Disease Detection AI

## Database
- Firestore

## Authentication
- Firebase Auth
