// REPOSITORY: JSON dari layanan -> model.

import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/services/layanan_open_meteo.dart';

abstract class RepositoriUdara {
  Future<Udara> ambil(Kota kota);
  Future<List<RingkasanKota>> ambilSemua();
}

class RepositoriUdaraOpenMeteo implements RepositoriUdara {
  RepositoriUdaraOpenMeteo({required this._layanan});

  final LayananOpenMeteo _layanan;

  @override
  Future<Udara> ambil(Kota kota) async {
    final Map<String, dynamic> json = await _layanan.ambilKualitasUdara(
      lintang: kota.lintang,
      bujur: kota.bujur,
    );
    return switch (json) {
      {
        'current': final Map<String, dynamic> saatIni,
        'hourly': final Map<String, dynamic> perJam,
      } =>
        Udara(kota: kota, saatIni: _saatIni(saatIni), perJam: _perJam(perJam)),
      _ => throw const FormatException('Bentuk data udara tidak sesuai'),
    };
  }

  // Diurutkan dari udara terbersih; wilayah tanpa data di paling akhir.
  @override
  Future<List<RingkasanKota>> ambilSemua() async {
    final List<dynamic> json = await _layanan.ambilAqiBanyak(
      lintang: [for (final Kota k in Kota.values) k.lintang],
      bujur: [for (final Kota k in Kota.values) k.bujur],
    );
    if (json.length != Kota.values.length) {
      throw const FormatException('Jumlah wilayah tidak sama');
    }
    final List<RingkasanKota> hasil = [
      for (int i = 0; i < json.length; i++)
        switch (json[i]) {
          {'current': {'us_aqi': final num? aqi}} => RingkasanKota(
            kota: Kota.values[i],
            aqi: aqi?.round(),
          ),
          _ => throw const FormatException('Bentuk data wilayah salah'),
        },
    ];
    return hasil..sort(
      (RingkasanKota a, RingkasanKota b) =>
          (a.aqi ?? 9999).compareTo(b.aqi ?? 9999),
    );
  }

  UdaraSaatIni _saatIni(Map<String, dynamic> json) {
    if (json case {'time': final String waktu, 'us_aqi': final num aqi}) {
      return UdaraSaatIni(
        waktu: DateTime.parse(waktu),
        aqi: aqi.round(),
        uv: (json['uv_index'] as num?)?.toDouble(),
        kadar: {
          for (final Polutan p in Polutan.values)
            p: Kadar(
              nilai: (json[p.kunci] as num?)?.toDouble(),
              aqi: (json['us_aqi_${p.kunci}'] as num?)?.round(),
            ),
        },
      );
    }
    throw const FormatException('Bentuk data udara saat ini salah');
  }

  // Data per jam berbentuk "array sejajar": time[i], us_aqi[i], dan
  // uv_index[i] adalah milik jam ke-i. Panjang semua array harus sama.
  List<PrakiraanJam> _perJam(Map<String, dynamic> json) {
    if (json case {
      'time': final List<dynamic> jam,
      'us_aqi': final List<dynamic> aqi,
      'uv_index': final List<dynamic> uv,
    }) {
      if (aqi.length != jam.length || uv.length != jam.length) {
        throw const FormatException('Panjang data per jam tidak sama');
      }
      return [
        for (int i = 0; i < jam.length; i++)
          PrakiraanJam(
            jam: DateTime.parse(jam[i] as String),
            aqi: (aqi[i] as num?)?.round(),
            uv: (uv[i] as num?)?.toDouble(),
          ),
      ];
    }
    throw const FormatException('Bentuk data per jam tidak sesuai');
  }
}
