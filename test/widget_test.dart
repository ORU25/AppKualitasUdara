import 'package:app_kualitas_udara/pemeriksaan.dart';
import 'package:app_kualitas_udara/repositories/repositori_udara.dart';
import 'package:app_kualitas_udara/services/layanan_open_meteo.dart';
import 'package:app_kualitas_udara/views/halaman_udara.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Menampilkan AQI, kategori, dan polutan utama', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Provider<RepositoriUdara>(
        create: (BuildContext context) => RepositoriUdaraOpenMeteo(
          layanan: LayananOpenMeteo(klien: MockClient(jawabanContoh)),
        ),
        child: const AplikasiUdara(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('69'), findsOneWidget);
    expect(find.text('Sedang'), findsOneWidget);
    expect(find.text('Polutan utama: PM2.5'), findsOneWidget);
    expect(find.textContaining('Puncak 152'), findsOneWidget);
  });
}
