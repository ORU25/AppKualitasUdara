// SERVICE (LAYANAN): HTTP ke Open-Meteo, kode status, batas waktu, JSON.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:app_kualitas_udara/models/udara.dart';

class ApiException implements Exception {
  const ApiException(this.kodeStatus);

  final int kodeStatus;

  @override
  String toString() => 'ApiException: kode status $kodeStatus';
}

class LayananOpenMeteo {
  LayananOpenMeteo({
    http.Client? klien,
    this.batasWaktu = const Duration(seconds: 10),
  }) : _klien = klien ?? http.Client();

  final http.Client _klien;
  final Duration batasWaktu;

  Future<Map<String, dynamic>> ambilKualitasUdara({
    required double lintang,
    required double bujur,
  }) async {
    final Object? json = await _ambil({
      'latitude': '$lintang',
      'longitude': '$bujur',
      'current': [
        'us_aqi',
        'uv_index',
        for (final Polutan p in Polutan.values) ...[
          p.kunci,
          'us_aqi_${p.kunci}',
        ],
      ].join(','),
      'hourly': 'us_aqi,uv_index',
      'timezone': 'auto', // jam mengikuti zona waktu wilayah itu
      'forecast_hours': '24', // mulai dari jam sekarang
    });
    return switch (json) {
      final Map<String, dynamic> data => data,
      _ => throw const FormatException('Bentuk JSON tidak dikenal'),
    };
  }

  // Banyak lokasi dalam satu permintaan: koordinat dipisah koma, dan
  // jawabannya berupa daftar dengan urutan yang sama.
  Future<List<dynamic>> ambilAqiBanyak({
    required List<double> lintang,
    required List<double> bujur,
  }) async {
    final Object? json = await _ambil({
      'latitude': lintang.join(','),
      'longitude': bujur.join(','),
      'current': 'us_aqi',
      'timezone': 'auto',
    });
    return switch (json) {
      final List<dynamic> data => data,
      _ => throw const FormatException('Bentuk JSON tidak dikenal'),
    };
  }

  Future<Object?> _ambil(Map<String, String> parameter) async {
    final Uri alamat = Uri.https(
      'air-quality-api.open-meteo.com',
      '/v1/air-quality',
      parameter,
    );
    debugPrint('GET $alamat');

    final http.Response respons = await _klien
        .get(alamat, headers: {'Accept': 'application/json'})
        .timeout(batasWaktu);
    if (respons.statusCode != 200) {
      throw ApiException(respons.statusCode);
    }
    return jsonDecode(utf8.decode(respons.bodyBytes));
  }

  void tutup() => _klien.close();
}
