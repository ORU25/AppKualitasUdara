// MODEL: data yang dipakai di seluruh aplikasi.

import 'package:flutter/material.dart';

// Titik koordinat = pusat pemerintahan tiap kabupaten/kota.
enum Kota {
  samarinda('Samarinda', 'Kota · ibu kota provinsi', -0.49, 117.15),
  balikpapan('Balikpapan', 'Kota', -1.27, 116.83),
  bontang('Bontang', 'Kota', 0.13, 117.49),
  kutaiKartanegara(
    'Kutai Kartanegara',
    'Kabupaten · pusat di Tenggarong',
    -0.42,
    116.99,
  ),
  kutaiTimur('Kutai Timur', 'Kabupaten · pusat di Sangatta', 0.50, 117.53),
  kutaiBarat('Kutai Barat', 'Kabupaten · pusat di Sendawar', -0.24, 115.69),
  berau('Berau', 'Kabupaten · pusat di Tanjung Redeb', 2.15, 117.50),
  paser('Paser', 'Kabupaten · pusat di Tanah Grogot', -1.91, 116.20),
  penajamPaserUtara(
    'Penajam Paser Utara',
    'Kabupaten · pusat di Penajam',
    -1.25,
    116.77,
  ),
  mahakamUlu('Mahakam Ulu', 'Kabupaten · pusat di Ujoh Bilang', 0.55, 115.25);

  const Kota(this.nama, this.keterangan, this.lintang, this.bujur);

  final String nama;
  final String keterangan;
  final double lintang; // latitude
  final double bujur; // longitude
}

// Kategori US AQI (EPA). Warnanya diredam dari warna resmi EPA agar
// tetap nyaman di tema terang maupun gelap.
enum Kategori {
  baik(
    'Baik',
    Color(0xFF2E9E5B),
    Icons.sentiment_satisfied_alt,
    'Udara bersih. Aman untuk olahraga di luar ruangan.',
  ),
  sedang(
    'Sedang',
    Color(0xFFE0B100),
    Icons.sentiment_neutral,
    'Masih dapat diterima. Orang yang sangat sensitif sebaiknya '
        'mengurangi aktivitas berat di luar.',
  ),
  sensitif(
    'Tidak sehat bagi kelompok sensitif',
    Color(0xFFE5732B),
    Icons.sentiment_dissatisfied,
    'Anak, lansia, dan penderita asma sebaiknya membatasi aktivitas '
        'lama di luar ruangan.',
  ),
  tidakSehat(
    'Tidak sehat',
    Color(0xFFD13F3F),
    Icons.masks,
    'Kurangi aktivitas di luar ruangan. Pakai masker jika harus keluar.',
  ),
  sangatTidakSehat(
    'Sangat tidak sehat',
    Color(0xFF8B4BA6),
    Icons.masks,
    'Hindari aktivitas di luar. Tutup jendela dan pakai masker N95.',
  ),
  berbahaya(
    'Berbahaya',
    Color(0xFF7D1F33),
    Icons.warning_amber,
    'Darurat kesehatan. Tetap di dalam ruangan.',
  );

  const Kategori(this.label, this.warna, this.ikon, this.saran);

  final String label;
  final Color warna;
  final IconData ikon;
  final String saran;

  // Batas atas setiap kategori, dipakai juga untuk skala di layar.
  static const List<int> batas = [0, 50, 100, 150, 200, 300, 500];

  String get rentang {
    final int i = index;
    return '${i == 0 ? 0 : batas[i] + 1}–${batas[i + 1]}';
  }

  static Kategori dariAqi(int aqi) {
    return switch (aqi) {
      <= 50 => Kategori.baik,
      <= 100 => Kategori.sedang,
      <= 150 => Kategori.sensitif,
      <= 200 => Kategori.tidakSehat,
      <= 300 => Kategori.sangatTidakSehat,
      _ => Kategori.berbahaya,
    };
  }
}

// Enam polutan yang membentuk US AQI. batasWho = pedoman kualitas udara
// WHO 2021 dalam μg/m³ (rata-rata 24 jam; ozon 8 jam).
enum Polutan {
  pm25(
    'PM2.5',
    'Partikel halus',
    'pm2_5',
    15,
    '24 jam',
    'Asap kebakaran hutan dan lahan, kendaraan, dan pembakaran batu bara.',
    'Masuk jauh ke paru-paru hingga aliran darah. Memicu ISPA, asma, '
        'dan penyakit jantung.',
  ),
  pm10(
    'PM10',
    'Partikel kasar',
    'pm10',
    45,
    '24 jam',
    'Debu jalan dan tambang, konstruksi, serta asap pembakaran.',
    'Mengiritasi hidung, tenggorokan, dan saluran napas atas.',
  ),
  ozon(
    'O₃',
    'Ozon permukaan',
    'ozone',
    100,
    '8 jam',
    'Terbentuk dari gas buang kendaraan dan industri yang bereaksi dengan '
        'sinar matahari, sehingga biasanya tertinggi siang hari.',
    'Membuat napas sesak dan memperparah asma.',
  ),
  no2(
    'NO₂',
    'Nitrogen dioksida',
    'nitrogen_dioxide',
    25,
    '24 jam',
    'Kendaraan bermotor, pembangkit listrik, dan industri.',
    'Meradangkan saluran napas. Paparan lama menurunkan fungsi paru.',
  ),
  so2(
    'SO₂',
    'Sulfur dioksida',
    'sulphur_dioxide',
    40,
    '24 jam',
    'Pembakaran batu bara (PLTU), kilang minyak, dan smelter.',
    'Memicu batuk dan penyempitan saluran napas, terutama pada penderita '
        'asma.',
  ),
  co(
    'CO',
    'Karbon monoksida',
    'carbon_monoxide',
    4000,
    '24 jam',
    'Pembakaran tidak sempurna: kendaraan dan kebakaran hutan.',
    'Mengurangi oksigen yang dibawa darah. Pada kadar tinggi menyebabkan '
        'pusing dan lemas.',
  );

  const Polutan(
    this.simbol,
    this.nama,
    this.kunci,
    this.batasWho,
    this.periodeWho,
    this.sumber,
    this.dampak,
  );

  final String simbol;
  final String nama;
  final String kunci; // nama variabel di Open-Meteo
  final double batasWho;
  final String periodeWho;
  final String sumber;
  final String dampak;
}

class Kadar {
  const Kadar({required this.nilai, required this.aqi});

  final double? nilai; // μg/m³
  final int? aqi; // sub-indeks US AQI polutan ini
}

class UdaraSaatIni {
  const UdaraSaatIni({
    required this.waktu,
    required this.aqi,
    required this.uv,
    required this.kadar,
  });

  final DateTime waktu; // jam data, zona waktu wilayah (WITA)
  final int aqi; // US AQI
  final double? uv;
  final Map<Polutan, Kadar> kadar;

  Kategori get kategori => Kategori.dariAqi(aqi);

  // US AQI = sub-indeks tertinggi, jadi polutan itulah penentunya.
  Polutan? get utama {
    Polutan? hasil;
    int tertinggi = -1;
    for (final MapEntry<Polutan, Kadar> e in kadar.entries) {
      if (e.value.aqi case final int aqi when aqi > tertinggi) {
        tertinggi = aqi;
        hasil = e.key;
      }
    }
    return hasil;
  }
}

class PrakiraanJam {
  const PrakiraanJam({required this.jam, required this.aqi, required this.uv});

  final DateTime jam;
  final int? aqi; // bisa kosong (null) dari server
  final double? uv;
}

class Udara {
  const Udara({
    required this.kota,
    required this.saatIni,
    required this.perJam,
  });

  final Kota kota;
  final UdaraSaatIni saatIni;
  final List<PrakiraanJam> perJam;
}

class RingkasanKota {
  const RingkasanKota({required this.kota, required this.aqi});

  final Kota kota;
  final int? aqi;
}
