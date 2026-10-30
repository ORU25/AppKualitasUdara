// VIEW: kartu "Aktivitas hari ini" — saran aktivitas harian dari US AQI
// dan indeks UV saat ini. Tidak ada pengambilan data baru: semuanya
// dihitung dari UdaraSaatIni yang sudah dimuat.

import 'package:flutter/material.dart';

import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/views/komponen_udara.dart';

// Tiga tingkat kelayakan; warnanya meminjam warna kategori AQI agar
// konsisten dengan seluruh layar.
enum Tingkat {
  aman(Kategori.baik),
  waspada(Kategori.sedang),
  hindari(Kategori.tidakSehat);

  const Tingkat(this.kategori);

  final Kategori kategori;

  Color get warna => kategori.warna;
}

class Aktivitas {
  const Aktivitas({
    required this.nama,
    required this.ikon,
    required this.tingkat,
    required this.label,
    required this.catatan,
  });

  final String nama;
  final IconData ikon;
  final Tingkat tingkat;
  final String label; // teks pada lencana, mis. "Aman", "Disarankan"
  final String catatan; // satu-dua kalimat pendek
}

Tingkat _menurutAqi(int aqi, int amanSampai, int waspadaSampai) {
  if (aqi <= amanSampai) return Tingkat.aman;
  if (aqi <= waspadaSampai) return Tingkat.waspada;
  return Tingkat.hindari;
}

T _per<T>(Tingkat t, T aman, T waspada, T hindari) {
  return switch (t) {
    Tingkat.aman => aman,
    Tingkat.waspada => waspada,
    Tingkat.hindari => hindari,
  };
}

// Aturan sederhana berbasis ambang US AQI dan indeks UV (WHO).
List<Aktivitas> susunAktivitas(int aqi, double? uv) {
  final Tingkat jalan = _menurutAqi(aqi, 100, 150);
  final Tingkat olahraga = _menurutAqi(aqi, 50, 100);
  final Tingkat sensitif = _menurutAqi(aqi, 50, 100);
  final Tingkat jendela = _menurutAqi(aqi, 100, 150);
  final Tingkat masker = _menurutAqi(aqi, 100, 150);
  final int indeksUv = uv?.round() ?? 0;
  final Tingkat matahari = indeksUv < 3
      ? Tingkat.aman
      : indeksUv < 8
      ? Tingkat.waspada
      : Tingkat.hindari;

  return [
    Aktivitas(
      nama: 'Jalan santai',
      ikon: Icons.directions_walk,
      tingkat: jalan,
      label: _per(jalan, 'Aman', 'Singkat saja', 'Tunda'),
      catatan: _per(
        jalan,
        'Udara cukup baik untuk berjalan di luar.',
        'Batasi durasi, hindari jalan raya ramai.',
        'Pindahkan ke dalam ruangan.',
      ),
    ),
    Aktivitas(
      nama: 'Olahraga berat',
      ikon: Icons.directions_run,
      tingkat: olahraga,
      label: _per(olahraga, 'Aman', 'Ringan saja', 'Hindari'),
      catatan: _per(
        olahraga,
        'Silakan lari atau bersepeda di luar.',
        'Turunkan intensitas, istirahat lebih sering.',
        'Napas dalam saat berolahraga menarik polutan.',
      ),
    ),
    Aktivitas(
      nama: 'Anak & lansia',
      ikon: Icons.escalator_warning,
      tingkat: sensitif,
      label: _per(sensitif, 'Aman', 'Awasi', 'Di dalam'),
      catatan: _per(
        sensitif,
        'Bermain di luar tidak masalah.',
        'Awasi gejala batuk atau sesak.',
        'Kelompok sensitif sebaiknya di dalam.',
      ),
    ),
    Aktivitas(
      nama: 'Buka jendela',
      ikon: Icons.window_outlined,
      tingkat: jendela,
      label: _per(jendela, 'Boleh', 'Seperlunya', 'Tutup'),
      catatan: _per(
        jendela,
        'Ventilasi alami baik untuk rumah.',
        'Buka sebentar saja saat AQI turun.',
        'Tutup rapat agar asap tidak masuk.',
      ),
    ),
    Aktivitas(
      nama: 'Masker',
      ikon: Icons.masks_outlined,
      tingkat: masker,
      label: _per(masker, 'Tak perlu', 'Disarankan', 'Wajib'),
      catatan: _per(
        masker,
        'Tidak perlu masker khusus.',
        'Pakai masker jika sensitif atau berdebu.',
        aqi > 200
            ? 'Pakai masker N95 jika harus keluar.'
            : 'Pakai masker saat keluar rumah.',
      ),
    ),
    Aktivitas(
      nama: 'Paparan matahari',
      ikon: Icons.wb_sunny_outlined,
      tingkat: matahari,
      label: _per(matahari, 'Rendah', 'Tabir surya', 'Hindari'),
      catatan: _per(
        matahari,
        'Indeks UV rendah, aman di luar.',
        'Pakai tabir surya, topi, dan kacamata.',
        'Hindari matahari tengah hari.',
      ),
    ),
  ];
}

class KartuAktivitas extends StatelessWidget {
  const KartuAktivitas({super.key, required this.saatIni});

  final UdaraSaatIni saatIni;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;

    final List<Aktivitas> daftar = susunAktivitas(saatIni.aqi, saatIni.uv);
    final int jumlahAman = daftar
        .where((Aktivitas a) => a.tingkat == Tingkat.aman)
        .length;
    final Kategori kategori = saatIni.kategori;
    final Color aksen = kategori.warna;

    final String judulRingkas = jumlahAman >= 5
        ? 'Hari yang bagus untuk di luar'
        : jumlahAman >= 3
        ? 'Boleh keluar, tetap waspada'
        : 'Sebaiknya di dalam ruangan dulu';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: warna.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: warna.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kepala kartu: gradien lembut berwarna kategori AQI.
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  aksen.withValues(alpha: 0.28),
                  aksen.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: aksen.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        kategori.ikon,
                        size: 26,
                        color: warna.onSurface,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            judulRingkas,
                            style: gayaTeks.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$jumlahAman dari ${daftar.length} aktivitas '
                            'aman dilakukan sekarang',
                            style: gayaTeks.bodySmall?.copyWith(
                              color: warna.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Satu segmen per aktivitas, berwarna sesuai tingkatnya.
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (final Aktivitas a in daftar)
                        Expanded(
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: a.tingkat.warna,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints ukuran) {
                const double jarak = 8;
                final int kolom = ukuran.maxWidth >= 720 ? 3 : 2;
                final double lebar =
                    (ukuran.maxWidth - jarak * (kolom - 1)) / kolom;
                return Wrap(
                  spacing: jarak,
                  runSpacing: jarak,
                  children: [
                    for (int i = 0; i < daftar.length; i++)
                      SizedBox(
                        width: lebar,
                        child: _MunculBertahap(
                          urutan: i,
                          child: _KotakAktivitas(aktivitas: daftar[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Text(
              'Saran umum berdasarkan US AQI dan indeks UV saat ini, '
              'bukan nasihat medis. Penderita asma atau jantung sebaiknya '
              'mengikuti anjuran dokter.',
              style: gayaTeks.labelSmall?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Setiap kotak muncul memudar dan naik sedikit, berurutan.
class _MunculBertahap extends StatelessWidget {
  const _MunculBertahap({required this.urutan, required this.child});

  final int urutan;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + urutan * 70),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? anak) {
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: anak),
        );
      },
      child: child,
    );
  }
}

class _KotakAktivitas extends StatelessWidget {
  const _KotakAktivitas({required this.aktivitas});

  final Aktivitas aktivitas;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;
    final Color aksen = aktivitas.tingkat.warna;

    return Semantics(
      label: '${aktivitas.nama}: ${aktivitas.label}. ${aktivitas.catatan}',
      excludeSemantics: true,
      child: Container(
        // Tinggi tetap agar semua kotak sejajar tanpa IntrinsicHeight.
        height: 144,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: aksen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: aksen.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: aksen.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(aktivitas.ikon, size: 20, color: warna.onSurface),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: ShapeDecoration(
                        color: aksen,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        aktivitas.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: gayaTeks.labelSmall?.copyWith(
                          color: teksDiAtas(aksen),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              aktivitas.nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gayaTeks.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                aktivitas.catatan,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: gayaTeks.bodySmall?.copyWith(
                  color: warna.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}