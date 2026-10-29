// PEMERIKSAAN: uji repository dan ViewModel dengan MockClient.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/repositories/repositori_udara.dart';
import 'package:app_kualitas_udara/services/layanan_open_meteo.dart';
import 'package:app_kualitas_udara/viewmodels/udara_viewmodel.dart';

// Dijalankan sebelum aplikasi tampil. Tidak butuh internet: "server"
// diganti MockClient yang jawabannya ditulis di bawah ini.

const String contohJsonUdara = '''
{
  "latitude": -0.5,
  "longitude": 117.2,
  "timezone": "Asia/Makassar",
  "current": {
    "time": "2026-10-29T20:00",
    "interval": 3600,
    "us_aqi": 69,
    "uv_index": 0.0,
    "pm2_5": 22.2,
    "us_aqi_pm2_5": 69,
    "pm10": 23.9,
    "us_aqi_pm10": 20,
    "ozone": 69,
    "us_aqi_ozone": 42,
    "nitrogen_dioxide": 9.1,
    "us_aqi_nitrogen_dioxide": 5,
    "sulphur_dioxide": null,
    "us_aqi_sulphur_dioxide": null,
    "carbon_monoxide": 3412.0,
    "us_aqi_carbon_monoxide": 14
  },
  "hourly": {
    "time": ["2026-10-29T20:00", "2026-10-29T21:00", "2026-10-29T22:00"],
    "us_aqi": [69, 152, null],
    "uv_index": [0.0, 0.0, null]
  }
}
''';

// Jawaban banyak lokasi: satu objek per wilayah, urutan Kota.values.
final String contohJsonSemua = jsonEncode([
  for (final int? aqi in [69, 72, 63, 66, 65, 192, 74, 74, 72, null])
    {
      'current': {'us_aqi': aqi},
    },
]);

// "Server" tiruan: koordinat berkoma berarti permintaan banyak lokasi.
Future<http.Response> jawabanContoh(http.Request permintaan) async {
  final bool banyak = permintaan.url.queryParameters['latitude']!.contains(',');
  return http.Response(banyak ? contohJsonSemua : contohJsonUdara, 200);
}

void periksa(String nama, Object? didapat, Object? diharapkan) {
  if (didapat == diharapkan) {
    debugPrint('LULUS  $nama');
  } else {
    debugPrint('GAGAL  $nama: diharapkan $diharapkan, hasilnya $didapat');
  }
}

Future<void> jalankanUji() async {
  http.Request? terakhir;
  final RepositoriUdara repo = RepositoriUdaraOpenMeteo(
    layanan: LayananOpenMeteo(
      klien: MockClient((http.Request permintaan) {
        terakhir = permintaan;
        return jawabanContoh(permintaan);
      }),
    ),
  );

  final Udara udara = await repo.ambil(Kota.samarinda);
  periksa(
    'Alamat memakai lintang wilayah',
    terakhir!.url.queryParameters['latitude'],
    '${Kota.samarinda.lintang}',
  );
  periksa('AQI saat ini', udara.saatIni.aqi, 69);
  periksa('AQI 69 = Sedang', udara.saatIni.kategori, Kategori.sedang);
  periksa('Polutan utama PM2.5', udara.saatIni.utama, Polutan.pm25);
  periksa(
    'Ozon 69 (bulat) terbaca',
    udara.saatIni.kadar[Polutan.ozon]!.nilai,
    69.0,
  );
  periksa('SO2 kosong', udara.saatIni.kadar[Polutan.so2]!.nilai, null);
  periksa('Tiga jam prakiraan', udara.perJam.length, 3);
  periksa(
    'Jam kedua tidak sehat',
    Kategori.dariAqi(udara.perJam[1].aqi!),
    Kategori.tidakSehat,
  );
  periksa('AQI jam ketiga kosong', udara.perJam[2].aqi, null);

  final List<RingkasanKota> peringkat = await repo.ambilSemua();
  periksa('Peringkat: terbersih Bontang', peringkat.first.kota, Kota.bontang);
  periksa(
    'Peringkat: tanpa data paling akhir',
    peringkat.last.kota,
    Kota.mahakamUlu,
  );

  // ViewModel: server menjawab 500 -> status gagal + pesan ramah.
  final UdaraViewModel vm = UdaraViewModel(
    repositori: RepositoriUdaraOpenMeteo(
      layanan: LayananOpenMeteo(
        klien: MockClient(
          (http.Request permintaan) async => http.Response('{}', 500),
        ),
      ),
    ),
  );
  await vm.muat();
  periksa('Kode 500: status gagal', vm.status, StatusMuat.gagal);
  periksa(
    'Kode 500: pesan ramah',
    vm.pesanGalat,
    'Server kualitas udara sedang bermasalah. Coba lagi nanti.',
  );
  vm.dispose();
}
