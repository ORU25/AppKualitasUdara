// VIEW: aplikasi, halaman, dan pilihan wilayah.

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_kualitas_udara/repositories/repositori_udara.dart';
import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/viewmodels/udara_viewmodel.dart';
import 'package:app_kualitas_udara/views/komponen_udara.dart';
import 'package:app_kualitas_udara/views/peta_kaltim.dart';
   import 'package:app_kualitas_udara/views/kartu_aktivitas.dart';

// Jarak kiri-kanan isi halaman: isi dibatasi ±1200 px di layar sangat lebar, dan header, chip wilayah, serta isi memakai jarak yang sama agar sejajar.
double sisiHalaman(double lebar) {
  if (lebar > 1232) return (lebar - 1200) / 2;
  return lebar > 680 ? 24 : 16;
}

class AplikasiUdara extends StatelessWidget {
  const AplikasiUdara({super.key});

  // Hijau-teal hutan hujan Kalimantan sebagai warna dasar; warna kategori
  // AQI (hijau, kuning, jingga, merah, ungu) tetap jadi satu-satunya
  // warna "keras" di layar, sehingga mudah dibedakan dari tema.
  ThemeData _tema(Brightness kecerahan) {
    final ColorScheme warna = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F6F62),
      brightness: kecerahan,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: warna,
      scaffoldBackgroundColor: warna.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 68,
        backgroundColor: warna.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: warna.surfaceContainerHigh,
        selectedColor: warna.primaryContainer,
        labelStyle: TextStyle(color: warna.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(
          color: warna.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: warna.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(color: warna.outlineVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Udara Kalimantan Timur',
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      home: ChangeNotifierProvider(
        create: (BuildContext context) =>
            UdaraViewModel(repositori: context.read<RepositoriUdara>())..muat(),
        child: const HalamanUdara(),
      ),
    );
  }
}

class HalamanUdara extends StatelessWidget {
  const HalamanUdara({super.key});

  @override
  Widget build(BuildContext context) {
    final UdaraViewModel vm = context.watch<UdaraViewModel>();
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;

    final Widget isi = switch (vm.status) {
      StatusMuat.memuat => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Memuat data kualitas udara…',
              style: gayaTeks.bodyMedium?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      StatusMuat.gagal => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: warna.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off,
                  size: 44,
                  color: warna.onErrorContainer,
                  semanticLabel: 'Gagal memuat',
                ),
              ),
              const SizedBox(height: 20),
              Text('Data belum bisa dimuat', style: gayaTeks.titleMedium),
              const SizedBox(height: 6),
              Text(
                vm.pesanGalat,
                textAlign: TextAlign.center,
                style: gayaTeks.bodyMedium?.copyWith(
                  color: warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.read<UdaraViewModel>().muat(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
      StatusMuat.berhasil => RefreshIndicator(
        onRefresh: () => context.read<UdaraViewModel>().segarkan(),
        child: IsiUdara(
          udara: vm.udara!,
          peringkat: vm.peringkat,
          diperbarui: vm.diperbarui!,
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: sisiHalaman(MediaQuery.sizeOf(context).width),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Udara Kalimantan Timur',
              style: gayaTeks.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Kualitas udara 10 kabupaten/kota',
              style: gayaTeks.bodySmall?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const PilihanKota(),
          Expanded(
            // Peralihan halus saat status berganti (memuat/berhasil/gagal).
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey<StatusMuat>(vm.status), child: isi),
            ),
          ),
        ],
      ),
    );
  }
}

class PilihanKota extends StatelessWidget {
  const PilihanKota({super.key});

  @override
  Widget build(BuildContext context) {
    // select: hanya dibangun ulang saat wilayah terpilih berubah.
    final Kota terpilih = context.select((UdaraViewModel vm) => vm.kota);
    final double lebar = MediaQuery.sizeOf(context).width;

    // Layar lebar: semua chip tampil (membungkus), sejajar dengan isi.
    if (lebar >= 900) {
      final double sisi = sisiHalaman(lebar);
      return SizedBox(
        width: double.infinity, // penuh, agar chip rata kiri (bukan di tengah)
        child: Padding(
        padding: EdgeInsets.fromLTRB(sisi, 8, sisi, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final Kota kota in Kota.values)
              ChoiceChip(
                label: Text(kota.nama),
                selected: kota == terpilih,
                onSelected: (_) =>
                    context.read<UdaraViewModel>().pilihKota(kota),
              ),
          ],
        ),
        ),
      );
    }

    // Layar sempit: chip digeser ke samping. Geser dengan mouse/trackpad
    // juga diaktifkan (bawaan Flutter hanya mengizinkan sentuhan).
    return SizedBox(
      height: 56,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: ListView(
        scrollDirection: Axis.horizontal,
        // Tiap chip punya jarak 4 px di kiri-kanan, jadi dikurangi 4 agar
        // chip pertama sejajar dengan tepi kartu.
        padding: EdgeInsets.symmetric(
          horizontal: sisiHalaman(lebar) - 4,
          vertical: 8,
        ),
        children: [
          for (final Kota kota in Kota.values)
            Builder(
              builder: (BuildContext context) {
                // Wilayah bisa dipilih dari daftar peringkat, jadi chip
                // terpilih digulir agar terlihat.
                if (kota == terpilih) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      Scrollable.ensureVisible(
                        context,
                        alignment: 0.5,
                        duration: const Duration(milliseconds: 300),
                      );
                    }
                  });
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(kota.nama),
                    selected: kota == terpilih,
                    onSelected: (_) =>
                        context.read<UdaraViewModel>().pilihKota(kota),
                  ),
                );
              },
            ),
        ],
        ),
      ),
    );
  }
}

class IsiUdara extends StatelessWidget {
  const IsiUdara({
    super.key,
    required this.udara,
    required this.peringkat,
    required this.diperbarui,
  });

  final Udara udara;
  final List<RingkasanKota> peringkat;
  final DateTime diperbarui;

  @override
  Widget build(BuildContext context) {
    final ColorScheme warna = Theme.of(context).colorScheme;
    final TextTheme gayaTeks = Theme.of(context).textTheme;

    // Judul bagian: ikon kecil sebagai penanda, lalu judul + keterangan.
    Widget judul(IconData ikon, String teks, [String? keterangan]) => Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: warna.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, size: 20, color: warna.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teks,
                  style: gayaTeks.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (keterangan != null)
                  Text(
                    keterangan,
                    style: gayaTeks.bodySmall?.copyWith(
                      color: warna.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints ukuran) {
        final double sisi = sisiHalaman(ukuran.maxWidth);

        return ListView(
          // Selalu bisa digulir, agar "tarik untuk menyegarkan" tetap
          // berfungsi walaupun isinya pendek.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(sisi, 8, sisi, 32),
          children: [
            KartuIndeks(udara: udara, diperbarui: diperbarui),
            judul(Icons.schedule, '24 jam ke depan'),
            GrafikPerJam(perJam: udara.perJam),
            const SizedBox(height: 12),
            KartuUv(saatIni: udara.saatIni.uv, perJam: udara.perJam),
            judul(
              Icons.directions_run,
              'Aktivitas hari ini',
              'Saran berdasarkan AQI dan indeks UV saat ini.',
            ),
            KartuAktivitas(saatIni: udara.saatIni),
            judul(
              Icons.blur_on,
              'Polutan',
              'Ketuk untuk melihat sumber dan dampaknya.',
            ),
            DaftarPolutan(saatIni: udara.saatIni),

            // Riwayat Telemetri (garis)
            judul(
              Icons.history,
              'Riwayat Telemetri',
              'Fluktuasi AQI 24 jam hingga 7 hari terakhir.',
            ),
            const RiwayatTelemetri(),

            // ---- PETA ----
            judul(
              Icons.map_outlined,
              'Peta Se-Kalimantan Timur',
              'Ketuk titik untuk melihat detail wilayah. Warna = kategori AQI.',
            ),
            PetaKaltim(peringkat: peringkat, terpilih: udara.kota),

            judul(
              Icons.leaderboard_outlined,
              'Se-Kalimantan Timur',
              'Dari yang terbersih. Ketuk untuk melihat detail wilayah.',
            ),
            PeringkatKaltim(peringkat: peringkat, terpilih: udara.kota),
            const SizedBox(height: 12),
            const ArtiKategori(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: warna.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sumber data: Open-Meteo.com (CC BY 4.0), model CAMS. Nilai '
                    'adalah prakiraan model per grid ±40 km, bukan alat ukur di '
                    'lapangan. Tarik ke bawah untuk menyegarkan.',
                    style: gayaTeks.bodySmall?.copyWith(
                      color: warna.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}