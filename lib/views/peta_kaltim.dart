// VIEW: peta interaktif 10 kabupaten/kota Kaltim.
// Data (koordinat + AQI) sudah tersedia dari RingkasanKota — tidak ada
// fetching baru. Titik berwarna kategori AQI, ketuk untuk pindah kota.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:app_kualitas_udara/models/udara.dart';
import 'package:app_kualitas_udara/viewmodels/udara_viewmodel.dart';

class PetaKaltim extends StatelessWidget {
  const PetaKaltim({
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 340,
        decoration: BoxDecoration(
          border: Border.all(color: warna.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // ---- Peta dasar ----
            FlutterMap(
              options: MapOptions(
                // Titik tengah Kalimantan Timur.
                initialCenter: const LatLng(0.5, 116.5),
                initialZoom: 6.3,
                minZoom: 4,
                maxZoom: 12,
                // Matikan rotasi agar tidak membingungkan.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_kualitas_udara',
                  // Diam saja kalau tile gagal (offline): marker tetap tampil.
                  errorTileCallback: (tile, error, stackTrace) {},
                ),
                // ---- Titik kota ----
                MarkerLayer(
                  markers: [
                    for (final RingkasanKota r in peringkat)
                      _marker(context, r, r.kota == terpilih),
                  ],
                ),
              ],
            ),

            // ---- Legenda (pojok kiri bawah) ----
            Positioned(
              left: 8,
              bottom: 8,
              child: _Legenda(warna: warna, gayaTeks: gayaTeks),
            ),

            // ---- Kredit OSM (wajib sesuai lisensi) ----
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: warna.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '© OpenStreetMap',
                  style: gayaTeks.labelSmall?.copyWith(
                    color: warna.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _marker(BuildContext context, RingkasanKota r, bool dipilih) {
    final Kategori? kategori = r.aqi == null ? null : Kategori.dariAqi(r.aqi!);
    final Color latar = kategori?.warna ?? Colors.grey.shade500;

    return Marker(
      point: LatLng(r.kota.lintang, r.kota.bujur),
      width: dipilih ? 52 : 40,
      height: dipilih ? 52 : 40,
      child: GestureDetector(
        onTap: () => context.read<UdaraViewModel>().pilihKota(r.kota),
        child: Tooltip(
          message: '${r.kota.nama}: AQI ${r.aqi ?? '–'}',
          child: Semantics(
            label: '${r.kota.nama}, AQI ${r.aqi ?? 'tidak tersedia'}',
            button: true,
            child: Container(
              decoration: BoxDecoration(
                color: latar,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dipilih ? Colors.white : Colors.white70,
                  width: dipilih ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                r.aqi?.toString() ?? '–',
                style: TextStyle(
                  color: _teksDiAtas(latar),
                  fontWeight: FontWeight.bold,
                  fontSize: dipilih ? 13 : 11,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _teksDiAtas(Color latar) =>
      ThemeData.estimateBrightnessForColor(latar) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.warna, required this.gayaTeks});

  final ColorScheme warna;
  final TextTheme gayaTeks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: warna.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final Kategori k in [
            Kategori.baik,
            Kategori.sedang,
            Kategori.sensitif,
            Kategori.tidakSehat,
            Kategori.sangatTidakSehat,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: k.warna,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    k.rentang.split('–').first,
                    style: gayaTeks.labelSmall?.copyWith(
                      color: warna.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}