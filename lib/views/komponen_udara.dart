// VIEW: komponen isi halaman (kartu, grafik, polutan, peringkat).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/viewmodels/udara_viewmodel.dart';

String duaDigit(int angka) => angka.toString().padLeft(2, '0');

String jamMenit(DateTime waktu) =>
    '${duaDigit(waktu.hour)}.${duaDigit(waktu.minute)}';

// 22.2 -> "22,2"; 3412.0 -> "3412" (koma desimal ala Indonesia).
String angka(double? nilai) {
  if (nilai == null) return '–';
  return nilai >= 100
      ? nilai.round().toString()
      : nilai.toStringAsFixed(1).replaceAll('.', ',');
}

// Teks yang terbaca di atas warna kategori (kuning butuh teks gelap).
Color teksDiAtas(Color latar) =>
    ThemeData.estimateBrightnessForColor(latar) == Brightness.dark
    ? Colors.white
    : Colors.black87;

// Kategori indeks UV menurut WHO.
String labelUv(double uv) {
  return switch (uv.round()) {
    <= 2 => 'Rendah',
    <= 5 => 'Sedang',
    <= 7 => 'Tinggi',
    <= 10 => 'Sangat tinggi',
    _ => 'Ekstrem',
  };
}

const List<FontFeature> angkaTabular = [FontFeature.tabularFigures()];

class KartuIndeks extends StatelessWidget {
  const KartuIndeks({super.key, required this.udara, required this.diperbarui});

  final Udara udara;
  final DateTime diperbarui;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;
    final UdaraSaatIni saatIni = udara.saatIni;
    final Kategori kategori = saatIni.kategori;
    final Polutan? utama = saatIni.utama;
    final TextStyle? gayaRedup = gayaTeks.bodySmall?.copyWith(
      color: warna.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warna.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(udara.kota.nama, style: gayaTeks.titleLarge),
          Text(udara.kota.keterangan, style: gayaRedup),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${saatIni.aqi}',
                semanticsLabel: 'Indeks kualitas udara ${saatIni.aqi}',
                style: gayaTeks.displayLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFeatures: angkaTabular,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'US AQI',
                style: gayaTeks.titleSmall?.copyWith(
                  color: warna.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kategori.warna,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  kategori.label,
                  style: gayaTeks.labelLarge?.copyWith(
                    color: teksDiAtas(kategori.warna),
                  ),
                ),
              ),
              if (utama != null)
                Text(
                  'Polutan utama: ${utama.simbol}',
                  style: gayaTeks.bodyMedium,
                ),
            ],
          ),
          const SizedBox(height: 20),
          SkalaAqi(aqi: saatIni.aqi),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                kategori.ikon,
                size: 20,
                color: warna.onSurfaceVariant,
                semanticLabel: kategori.label,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(kategori.saran, style: gayaTeks.bodyMedium)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Data pukul ${jamMenit(saatIni.waktu)} WITA · diperbarui '
            '${jamMenit(diperbarui)}',
            style: gayaRedup,
          ),
        ],
      ),
    );
  }
}

// Enam segmen sama lebar (satu per kategori) dan penanda posisi AQI.
class SkalaAqi extends StatelessWidget {
  const SkalaAqi({super.key, required this.aqi});

  final int aqi;

  // Posisi 0..1 di sepanjang skala; di dalam segmen, posisinya linear.
  double get _posisi {
    const List<int> b = Kategori.batas;
    final int nilai = aqi.clamp(0, b.last);
    for (int i = 1; i < b.length; i++) {
      if (nilai <= b[i]) {
        return (i - 1 + (nilai - b[i - 1]) / (b[i] - b[i - 1])) /
            (b.length - 1);
      }
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextStyle? gayaLabel = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: warna.onSurfaceVariant, fontFeatures: angkaTabular);

    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints ukuran) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 6,
                      height: 6,
                      child: Row(
                        children: [
                          for (final Kategori k in Kategori.values)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: k.warna,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: _posisi * ukuran.maxWidth - 2,
                      top: 0,
                      width: 4,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: warna.onSurface,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: warna.surfaceContainer,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final int b in Kategori.batas.skip(1))
                Expanded(
                  child: Text('$b', textAlign: TextAlign.end, style: gayaLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class GrafikPerJam extends StatelessWidget {
  const GrafikPerJam({super.key, required this.perJam});

  final List<PrakiraanJam> perJam;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;
    final List<PrakiraanJam> terisi = [
      for (final PrakiraanJam p in perJam)
        if (p.aqi != null) p,
    ];
    if (terisi.isEmpty) {
      return Text(
        'Prakiraan per jam belum tersedia.',
        style: gayaTeks.bodyMedium,
      );
    }
    PrakiraanJam? palingBaik(bool Function(PrakiraanJam) syarat) {
      PrakiraanJam? hasil;
      for (final PrakiraanJam p in terisi) {
        if (syarat(p) && (hasil == null || p.aqi! < hasil.aqi!)) hasil = p;
      }
      return hasil;
    }

    final PrakiraanJam puncak = terisi.reduce(
      (PrakiraanJam a, PrakiraanJam b) => b.aqi! > a.aqi! ? b : a,
    );
    // Jam terbaik untuk aktivitas luar: AQI terendah antara 06.00–17.00.
    final PrakiraanJam? terbaik = palingBaik(
      (PrakiraanJam p) => p.jam.hour >= 6 && p.jam.hour <= 17,
    );
    final int rataRata =
        (terisi.fold<int>(0, (int jumlah, PrakiraanJam p) => jumlah + p.aqi!) /
                terisi.length)
            .round();
    // Minimal 100 agar udara yang baik tidak tampak "penuh".
    final int skala = puncak.aqi! < 100 ? 100 : puncak.aqi!;
    final TextStyle? gayaLabel = gayaTeks.labelSmall?.copyWith(
      color: warna.onSurfaceVariant,
      fontFeatures: angkaTabular,
    );

    Widget baris(IconData ikon, String teks) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: warna.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(teks, style: gayaTeks.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        baris(
          Icons.trending_up,
          'Puncak ${puncak.aqi} pukul ${jamMenit(puncak.jam)} '
          '(${Kategori.dariAqi(puncak.aqi!).label.toLowerCase()})',
        ),
        baris(Icons.show_chart, 'Rata-rata $rataRata'),
        // Hanya disarankan jika udaranya memang layak (Baik/Sedang).
        if (terbaik != null && terbaik.aqi! <= 100)
          baris(
            Icons.directions_walk,
            'Waktu terbaik di luar ruangan: pukul ${jamMenit(terbaik.jam)} '
            '(AQI ${terbaik.aqi})',
          )
        else if (terbaik != null)
          baris(
            Icons.warning_amber,
            'Tidak ada jam siang yang layak untuk aktivitas luar. '
            'Terendah pukul ${jamMenit(terbaik.jam)} (AQI ${terbaik.aqi}).',
          ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final PrakiraanJam p in perJam)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: FractionallySizedBox(
                        heightFactor: p.aqi == null
                            ? 0.03
                            : (p.aqi! / skala).clamp(0.03, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.aqi == null
                                ? warna.outlineVariant
                                : Kategori.dariAqi(p.aqi!).warna,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: warna.outlineVariant),
        const SizedBox(height: 6),
        // Label setiap 6 jam, sejajar dengan batang pertamanya.
        Row(
          children: [
            for (int i = 0; i < perJam.length; i += 6)
              Expanded(
                flex: perJam.length - i < 6 ? perJam.length - i : 6,
                child: Text(jamMenit(perJam[i].jam), style: gayaLabel),
              ),
          ],
        ),
      ],
    );
  }
}

class KartuUv extends StatelessWidget {
  const KartuUv({super.key, required this.saatIni, required this.perJam});

  final double? saatIni;
  final List<PrakiraanJam> perJam;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;
    PrakiraanJam? puncak;
    for (final PrakiraanJam p in perJam) {
      if (p.uv != null && (puncak == null || p.uv! > puncak.uv!)) puncak = p;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: warna.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wb_sunny_outlined, color: warna.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Indeks UV', style: gayaTeks.titleSmall),
                Text(
                  saatIni == null
                      ? 'Sekarang: –'
                      : 'Sekarang ${angka(saatIni)} (${labelUv(saatIni!)})',
                  style: gayaTeks.bodyMedium,
                ),
                if (puncak != null) ...[
                  Text(
                    'Puncak ${angka(puncak.uv)} (${labelUv(puncak.uv!)}) '
                    'pukul ${jamMenit(puncak.jam)}',
                    style: gayaTeks.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    puncak.uv!.round() >= 3
                        ? 'Saat matahari tinggi, pakai tabir surya, topi, '
                              'dan kacamata hitam.'
                        : 'Tidak perlu perlindungan khusus.',
                    style: gayaTeks.bodySmall?.copyWith(
                      color: warna.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DaftarPolutan extends StatelessWidget {
  const DaftarPolutan({super.key, required this.saatIni});

  final UdaraSaatIni saatIni;

  @override
  Widget build(BuildContext context) {
    const List<Polutan> semua = Polutan.values;

    return Column(
      children: [
        for (int i = 0; i < semua.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final Polutan p in [semua[i], semua[i + 1]]) ...[
                    if (p != semua[i]) const SizedBox(width: 8),
                    Expanded(
                      child: KotakPolutan(polutan: p, kadar: saatIni.kadar[p]!),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class KotakPolutan extends StatelessWidget {
  const KotakPolutan({super.key, required this.polutan, required this.kadar});

  final Polutan polutan;
  final Kadar kadar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;
    final Kategori? kategori = kadar.aqi == null
        ? null
        : Kategori.dariAqi(kadar.aqi!);
    final double? rasio = kadar.nilai == null
        ? null
        : kadar.nilai! / polutan.batasWho;

    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (BuildContext context) =>
              DetailPolutan(polutan: polutan, kadar: kadar),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(polutan.simbol, style: gayaTeks.titleSmall),
                  ),
                  if (kategori != null)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: kategori.warna,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              Text(
                polutan.nama,
                style: gayaTeks.bodySmall?.copyWith(
                  color: warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: angka(kadar.nilai),
                      style: gayaTeks.headlineSmall?.copyWith(
                        fontFeatures: angkaTabular,
                      ),
                    ),
                    TextSpan(
                      text: ' μg/m³',
                      style: gayaTeks.bodySmall?.copyWith(
                        color: warna.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (rasio != null)
                Text(
                  rasio < 1
                      ? 'Di bawah pedoman WHO'
                      : '${angka(rasio)}× pedoman WHO',
                  style: gayaTeks.bodySmall?.copyWith(
                    color: rasio < 1 ? warna.onSurfaceVariant : warna.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailPolutan extends StatelessWidget {
  const DetailPolutan({super.key, required this.polutan, required this.kadar});

  final Polutan polutan;
  final Kadar kadar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;
    final TextStyle? gayaRedup = gayaTeks.bodyMedium?.copyWith(
      color: warna.onSurfaceVariant,
    );

    Widget fakta(String label, String nilai) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gayaRedup)),
          Text(nilai, style: gayaTeks.bodyMedium),
        ],
      ),
    );

    Widget bagian(String judul, String isi) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: gayaTeks.titleSmall),
          const SizedBox(height: 4),
          Text(isi, style: gayaTeks.bodyMedium),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${polutan.simbol} · ${polutan.nama}',
              style: gayaTeks.titleLarge,
            ),
            const SizedBox(height: 12),
            fakta('Kadar sekarang', '${angka(kadar.nilai)} μg/m³'),
            fakta(
              'Pedoman WHO (${polutan.periodeWho})',
              '${angka(polutan.batasWho)} μg/m³',
            ),
            fakta(
              'Sub-indeks AQI',
              kadar.aqi == null
                  ? '–'
                  : '${kadar.aqi} · ${Kategori.dariAqi(kadar.aqi!).label}',
            ),
            bagian('Sumber utama', polutan.sumber),
            bagian('Dampak kesehatan', polutan.dampak),
            const SizedBox(height: 16),
            Text(
              'Pedoman WHO 2021 berlaku untuk rata-rata ${polutan.periodeWho}, '
              'sedangkan kadar di sini per jam. Perbandingannya hanya '
              'perkiraan.',
              style: gayaTeks.bodySmall?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeringkatKaltim extends StatelessWidget {
  const PeringkatKaltim({
    super.key,
    required this.peringkat,
    required this.terpilih,
  });

  final List<RingkasanKota> peringkat;
  final Kota terpilih;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;

    return Column(
      children: [
        for (int i = 0; i < peringkat.length; i++)
          Builder(
            builder: (BuildContext context) {
              final RingkasanKota r = peringkat[i];
              final Kategori? kategori = r.aqi == null
                  ? null
                  : Kategori.dariAqi(r.aqi!);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: r.kota == terpilih,
                selectedColor: warna.onSurface,
                selectedTileColor: warna.surfaceContainer,
                leading: SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}',
                    style: gayaTeks.labelLarge?.copyWith(
                      color: warna.onSurfaceVariant,
                      fontFeatures: angkaTabular,
                    ),
                  ),
                ),
                minLeadingWidth: 20,
                title: Text(r.kota.nama, style: gayaTeks.bodyLarge),
                subtitle: Text(kategori?.label ?? 'Data tidak tersedia'),
                trailing: Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kategori?.warna ?? warna.outlineVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.aqi?.toString() ?? '–',
                    style: gayaTeks.labelLarge?.copyWith(
                      color: kategori == null
                          ? warna.onSurface
                          : teksDiAtas(kategori.warna),
                      fontFeatures: angkaTabular,
                    ),
                  ),
                ),
                onTap: () => context.read<UdaraViewModel>().pilihKota(r.kota),
              );
            },
          ),
      ],
    );
  }
}

class ArtiKategori extends StatelessWidget {
  const ArtiKategori({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text('Cara membaca AQI', style: gayaTeks.titleMedium),
      children: [
        Text(
          'US AQI meringkas kadar enam polutan menjadi satu angka 0–500. '
          'Setiap polutan punya sub-indeks sendiri, dan angka akhirnya '
          'mengikuti sub-indeks tertinggi (polutan utama). Makin tinggi '
          'angkanya, makin buruk udaranya.',
          style: gayaTeks.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (final Kategori k in Kategori.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: k.warna,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: Text(
                    k.rentang,
                    style: gayaTeks.bodyMedium?.copyWith(
                      fontFeatures: angkaTabular,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.label, style: gayaTeks.bodyMedium),
                      Text(
                        k.saran,
                        style: gayaTeks.bodySmall?.copyWith(
                          color: warna.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
