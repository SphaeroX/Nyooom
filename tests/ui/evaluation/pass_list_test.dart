import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/ui/evaluation/pass_widgets.dart';

PassRecord record(QualityClass c, {DowngradeReason? reason, double? v}) =>
    PassRecord(
      zeitUtcMs: 1700000000000,
      offsetS: 5,
      richtung: 1,
      klasse: c,
      v: v,
      sigmaV: v == null ? null : 2.4,
      vLaufzeit: v,
      vDoppler: null,
      kappa: 2,
      dEst: null,
      nToene: 0,
      restLaufzeitUs: 5,
      pegel: 20,
      dauer: 1,
      reason: reason,
      laneIndex: 0,
      distanceUsedM: 4.1,
    );

void main() {
  testWidgets('result list shows class, speed and reason', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PassList(
              records: [
                record(QualityClass.b, v: 31.24),
                record(QualityClass.c, reason: DowngradeReason.overlap),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('31.2 ± 2.4 km/h'), findsOneWidget);
    expect(find.textContaining('Überlappung'), findsOneWidget);
    expect(find.text('B'), findsWidgets);
    expect(find.text('C'), findsWidgets);
  });
}
