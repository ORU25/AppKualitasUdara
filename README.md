# Udara Kaltim

Aplikasi Flutter untuk memantau **kualitas udara** di 10 kabupaten/kota
**Kalimantan Timur**: Samarinda, Balikpapan, Bontang, Kutai Kartanegara,
Kutai Timur, Kutai Barat, Berau, Paser, Penajam Paser Utara, dan Mahakam Ulu.

Tugas Pertemuan 10 (Asinkron & REST API), dikembangkan dari
[Studi Kasus 13: Cuaca Kampus](https://github.com/antonprafanto/mobile2026/tree/main/pertemuan_10_async_dan_rest_api#13-studi-kasus-cuaca-kampus).
Sumber datanya diganti dari prakiraan cuaca menjadi
[Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api).

## Tampilan

<p align="center">
  <img src="screenshots/1_utama.png" width="200" alt="Samarinda: US AQI 69 kategori Sedang, polutan utama PM2.5, skala AQI berwarna, saran kesehatan, ringkasan 24 jam, grafik per jam, dan indeks UV">
  &nbsp;
  <img src="screenshots/2_polutan.png" width="200" alt="Ringkasan 24 jam, indeks UV, dan kotak polutan; PM2.5 bertanda 1,5 kali pedoman WHO">
  &nbsp;
  <img src="screenshots/3_detail.png" width="200" alt="Lembar detail PM2.5: kadar, pedoman WHO, sub-indeks AQI, sumber utama, dan dampak kesehatan">
</p>
<p align="center">
  <img src="screenshots/4_kaltim.png" width="200" alt="Mode gelap: peringkat 10 kabupaten/kota Kaltim dari yang terbersih, Kutai Barat terakhir dengan AQI 192">
  &nbsp;
  <img src="screenshots/5_gelap.png" width="200" alt="Mode gelap untuk Kutai Barat: AQI 192 Tidak sehat, puncak 247, peringatan tidak ada jam yang layak untuk aktivitas luar">
  &nbsp;
  <img src="screenshots/6_gagal.png" width="200" alt="Gagal memuat: ikon awan tercoret, pesan tidak dapat terhubung, dan tombol Coba lagi">
</p>

## Fitur

| Bagian | Isi |
| :--- | :--- |
| Pilihan wilayah | *Chip* 10 kabupaten/kota Kaltim; *chip* terpilih otomatis digulir agar terlihat |
| Indeks saat ini | Angka **US AQI**, kategori berwarna, **polutan utama**, skala 0–500 dengan penanda, saran kesehatan, jam data (WITA) |
| 24 jam ke depan | Puncak, rata-rata, **waktu terbaik untuk aktivitas luar** (06.00–17.00, hanya jika AQI ≤ 100), grafik batang per jam |
| Indeks UV | Nilai sekarang, puncak hari ini, dan saran perlindungan |
| Polutan | PM2.5, PM10, O₃, NO₂, SO₂, CO: kadar μg/m³, warna sub-indeks, dan perbandingan dengan **pedoman WHO 2021**. Ketuk untuk melihat sumber dan dampak kesehatannya |
| Se-Kalimantan Timur | Peringkat 10 wilayah dari yang terbersih; ketuk untuk berpindah wilayah |
| Cara membaca AQI | Penjelasan AQI dan arti setiap kategori |
| Interaksi | Tarik ke bawah untuk menyegarkan; tombol **Coba lagi** saat gagal |
| Tema | Mengikuti tema terang/gelap perangkat |

Kategori mengikuti standar US AQI (EPA):

| AQI | Kategori |
| :---: | :--- |
| 0–50 | Baik |
| 51–100 | Sedang |
| 101–150 | Tidak sehat bagi kelompok sensitif |
| 151–200 | Tidak sehat |
| 201–300 | Sangat tidak sehat |
| 301–500 | Berbahaya |

## Arsitektur (MVVM)

Mengikuti pola Contoh 11, dengan satu berkas per lapisan:

```text
lib/
├── main.dart                         # runApp + Provider (merangkai semua lapisan)
├── models/udara.dart                 # Kota, Kategori, Polutan, Udara, RingkasanKota, ...
├── services/layanan_open_meteo.dart  # LayananOpenMeteo, ApiException
├── repositories/repositori_udara.dart # RepositoriUdara, RepositoriUdaraOpenMeteo
├── viewmodels/udara_viewmodel.dart   # UdaraViewModel, StatusMuat, pesanRamah
├── views/
│   ├── halaman_udara.dart            # AplikasiUdara, HalamanUdara, PilihanKota, IsiUdara
│   └── komponen_udara.dart           # KartuIndeks, GrafikPerJam, KartuUv, DaftarPolutan, ...
└── pemeriksaan.dart                  # jalankanUji() dengan MockClient
```

| Lapisan | Kelas | Tugas |
| :--- | :--- | :--- |
| Model | `Kota`, `Kategori`, `Polutan`, `Udara`, … | Data dan aturan kategori AQI; tidak tahu apa-apa soal HTTP atau tampilan |
| Service | `LayananOpenMeteo` | Membuat alamat dengan `Uri.https`, `GET` dengan batas waktu 10 detik, memeriksa kode status, `jsonDecode` |
| Repository | `RepositoriUdaraOpenMeteo` | JSON → model dengan *pattern matching*; menyatukan **larik sejajar** `hourly.time[i]`, `hourly.us_aqi[i]`, dan `hourly.uv_index[i]`; nilai `null` tetap ditangani |
| ViewModel | `UdaraViewModel` | Detail wilayah dan peringkat diminta bersamaan (`Future.wait`), status memuat/berhasil/gagal, pesan galat ramah, nomor permintaan agar jawaban terlambat diabaikan |
| View | `KartuIndeks`, `GrafikPerJam`, `KartuUv`, `DaftarPolutan`, `PeringkatKaltim`, … | `RefreshIndicator`, `context.select` untuk *chip*, *bottom sheet* detail polutan, label semantik untuk pembaca layar |

Ada dua permintaan ke API:

```dart
// 1. Detail satu wilayah
Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
  'latitude': '-0.49',
  'longitude': '117.15',
  'current': 'us_aqi,uv_index,pm2_5,us_aqi_pm2_5,pm10,us_aqi_pm10,...',
  'hourly': 'us_aqi,uv_index',
  'timezone': 'auto',
  'forecast_hours': '24',
});

// 2. Peringkat: 10 koordinat dalam satu permintaan, jawabannya berupa daftar
Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
  'latitude': '-0.49,-1.27,0.13,...',
  'longitude': '117.15,116.83,117.49,...',
  'current': 'us_aqi',
});
```

## Pemeriksaan sebelum aplikasi tampil

`main` menjalankan `jalankanUji()` sebelum `runApp`. *Repository* dan ViewModel
diperiksa dengan `MockClient` (tanpa internet). Hasil di konsol:

```text
LULUS  Alamat memakai lintang wilayah
LULUS  AQI saat ini
LULUS  AQI 69 = Sedang
LULUS  Polutan utama PM2.5
LULUS  Ozon 69 (bulat) terbaca
LULUS  SO2 kosong
LULUS  Tiga jam prakiraan
LULUS  Jam kedua tidak sehat
LULUS  AQI jam ketiga kosong
LULUS  Peringkat: terbersih Bontang
LULUS  Peringkat: tanpa data paling akhir
Galat saat memuat kualitas udara: ApiException: kode status 500
LULUS  Kode 500: status gagal
LULUS  Kode 500: pesan ramah
```

Baris `Galat ... 500` memang diharapkan: uji ViewModel sengaja membuat server tiruan menjawab `500`.

## Menjalankan

```bash
flutter pub get
flutter run            # Android / Windows
flutter run -d chrome  # web (Open-Meteo mengizinkan CORS)
flutter test
```

Paket: [`http`](https://pub.dev/packages/http) dan [`provider`](https://pub.dev/packages/provider).

## Sumber data

Data kualitas udara dari [Open-Meteo.com](https://open-meteo.com) (model CAMS), lisensi
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Nilainya adalah prakiraan
model per grid ±40 km, bukan hasil alat ukur di lapangan. Pedoman polutan dari
[WHO Global Air Quality Guidelines 2021](https://www.who.int/publications/i/item/9789240034228).
