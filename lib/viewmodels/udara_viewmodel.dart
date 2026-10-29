// VIEWMODEL: status layar dan wilayah terpilih.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/repositories/repositori_udara.dart';
import 'package:app_kualitas_udara/services/layanan_open_meteo.dart';

enum StatusMuat { memuat, berhasil, gagal }

String pesanRamah(Object galat) {
  return switch (galat) {
    TimeoutException() => 'Server terlalu lama menjawab. Coba lagi.',
    ApiException(kodeStatus: >= 500) =>
      'Server kualitas udara sedang bermasalah. Coba lagi nanti.',
    ApiException() => 'Permintaan data kualitas udara ditolak server.',
    FormatException() => 'Data dari server tidak bisa dibaca.',
    http.ClientException() =>
      'Tidak dapat terhubung. Periksa koneksi internet Anda.',
    _ => 'Terjadi kesalahan yang tidak terduga.',
  };
}

class UdaraViewModel extends ChangeNotifier {
  UdaraViewModel({required this._repositori});

  final RepositoriUdara _repositori;

  Kota _kota = Kota.samarinda;
  StatusMuat _status = StatusMuat.memuat;
  Udara? _udara;
  List<RingkasanKota> _peringkat = const [];
  DateTime? _diperbarui;
  String _pesanGalat = '';
  int _nomorPermintaan = 0;
  bool _sudahDibuang = false;

  Kota get kota => _kota;
  StatusMuat get status => _status;
  Udara? get udara => _udara;
  List<RingkasanKota> get peringkat => _peringkat;
  DateTime? get diperbarui => _diperbarui;
  String get pesanGalat => _pesanGalat;

  // tampilkanMemuat: false saat ditarik untuk menyegarkan, karena
  // RefreshIndicator sudah menampilkan lingkarannya sendiri.
  Future<void> muat({bool tampilkanMemuat = true}) async {
    final int nomor = ++_nomorPermintaan;
    if (tampilkanMemuat) {
      _status = StatusMuat.memuat;
      notifyListeners();
    }
    try {
      // Detail wilayah dan peringkat se-Kaltim diminta bersamaan.
      // ponytail: peringkat ikut diambil ulang tiap ganti wilayah; simpan
      // dan ambil hanya saat segarkan jika jumlah permintaan jadi masalah.
      final List<Object> hasil = await Future.wait<Object>([
        _repositori.ambil(_kota),
        _repositori.ambilSemua(),
      ]);
      if (_sudahDibuang || nomor != _nomorPermintaan) {
        return; // jawaban terlambat (wilayah sudah diganti)
      }
      _udara = hasil[0] as Udara;
      _peringkat = hasil[1] as List<RingkasanKota>;
      _diperbarui = DateTime.now();
      _status = StatusMuat.berhasil;
    } catch (galat) {
      if (_sudahDibuang || nomor != _nomorPermintaan) {
        return;
      }
      debugPrint('Galat saat memuat kualitas udara: $galat');
      _pesanGalat = pesanRamah(galat);
      _status = StatusMuat.gagal;
    }
    notifyListeners();
  }

  Future<void> segarkan() => muat(tampilkanMemuat: false);

  void pilihKota(Kota kota) {
    if (kota == _kota) {
      return;
    }
    _kota = kota;
    muat();
  }

  @override
  void dispose() {
    _sudahDibuang = true;
    super.dispose();
  }
}
