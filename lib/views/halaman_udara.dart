// VIEW: aplikasi, halaman, dan pilihan wilayah.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_kualitas_udara/repositories/repositori_udara.dart';
import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/viewmodels/udara_viewmodel.dart';
import 'package:app_kualitas_udara/views/komponen_udara.dart';

class AplikasiUdara extends StatelessWidget {
  const AplikasiUdara({super.key});

  ThemeData _tema(Brightness kecerahan) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F6470),
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        brightness: kecerahan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Udara Kaltim',
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

    final Widget isi = switch (vm.status) {
      StatusMuat.memuat => const Center(child: CircularProgressIndicator()),
      StatusMuat.gagal => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: Theme.of(context).colorScheme.error,
                semanticLabel: 'Gagal memuat',
              ),
              const SizedBox(height: 12),
              Text(vm.pesanGalat, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
      appBar: AppBar(title: const Text('Udara Kaltim')),
      body: Column(
        children: [
          const PilihanKota(),
          Expanded(child: isi),
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

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

    Widget judul(String teks, [String? keterangan]) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teks, style: gayaTeks.titleMedium),
          if (keterangan != null)
            Text(
              keterangan,
              style: gayaTeks.bodySmall?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    return ListView(
      // Selalu bisa digulir, agar "tarik untuk menyegarkan" tetap
      // berfungsi walaupun isinya pendek.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        KartuIndeks(udara: udara, diperbarui: diperbarui),
        judul('24 jam ke depan'),
        GrafikPerJam(perJam: udara.perJam),
        const SizedBox(height: 16),
        KartuUv(saatIni: udara.saatIni.uv, perJam: udara.perJam),
        judul('Polutan', 'Ketuk untuk melihat sumber dan dampaknya.'),
        DaftarPolutan(saatIni: udara.saatIni),
        judul(
          'Se-Kalimantan Timur',
          'Dari yang terbersih. Ketuk untuk melihat detail wilayah.',
        ),
        PeringkatKaltim(peringkat: peringkat, terpilih: udara.kota),
        const SizedBox(height: 8),
        const ArtiKategori(),
        const SizedBox(height: 16),
        Text(
          'Sumber data: Open-Meteo.com (CC BY 4.0), model CAMS. Nilai '
          'adalah prakiraan model per grid ±40 km, bukan alat ukur di '
          'lapangan. Tarik ke bawah untuk menyegarkan.',
          style: gayaTeks.bodySmall?.copyWith(color: warna.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
