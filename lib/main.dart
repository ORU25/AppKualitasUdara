// =====================================================================
// Udara Kaltim — kualitas udara 10 kabupaten/kota Kalimantan Timur
// Data: Open-Meteo Air Quality API (https://open-meteo.com, gratis,
//       tanpa kunci API, CC BY 4.0).
// Pola MVVM, satu folder per lapisan:
//   - models/        : Kota, Kategori, Polutan, Udara, ...
//   - services/      : LayananOpenMeteo — alamat + parameter query, HTTP,
//                      kode status, batas waktu, dan JSON;
//   - repositories/  : RepositoriUdara — JSON -> Model, termasuk data per
//                      jam yang berbentuk "array sejajar";
//   - viewmodels/    : UdaraViewModel — status memuat/berhasil/gagal,
//                      wilayah terpilih, pesan galat ramah;
//   - views/         : halaman dan komponennya.
// Sebelum aplikasi tampil, jalankanUji() (pemeriksaan.dart) memeriksa
// repository dan ViewModel dengan MockClient (tanpa internet).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_kualitas_udara/pemeriksaan.dart';
import 'package:app_kualitas_udara/repositories/repositori_udara.dart';
import 'package:app_kualitas_udara/services/layanan_open_meteo.dart';
import 'package:app_kualitas_udara/views/halaman_udara.dart';

Future<void> main() async {
  await jalankanUji();
  runApp(
    MultiProvider(
      providers: [
        Provider<LayananOpenMeteo>(
          create: (BuildContext context) => LayananOpenMeteo(),
          dispose: (BuildContext context, LayananOpenMeteo layanan) =>
              layanan.tutup(),
        ),
        Provider<RepositoriUdara>(
          create: (BuildContext context) => RepositoriUdaraOpenMeteo(
            layanan: context.read<LayananOpenMeteo>(),
          ),
        ),
      ],
      child: const AplikasiUdara(),
    ),
  );
}
