import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/ui/stats/statistics_screen.dart';

PassRecord rec(double? v, QualityClass k, {DowngradeReason? reason}) =>
    PassRecord(
      zeitUtcMs: 1700000000000,
      offsetS: 0,
      richtung: 1,
      klasse: k,
      v: v,
      sigmaV: v == null ? null : 2,
      vLaufzeit: v,
      vDoppler: null,
      kappa: 1,
      dEst: null,
      nToene: 0,
      restLaufzeitUs: 5,
      pegel: 20,
      dauer: 1,
      reason: reason,
      laneIndex: 0,
      distanceUsedM: 5,
    );

void main() {
  testWidgets('shows key figures for A and B and the class-C share', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsView(
            limitKmh: 50,
            records: [
              rec(40, QualityClass.a),
              rec(52, QualityClass.b),
              rec(48, QualityClass.b),
              rec(null, QualityClass.c, reason: DowngradeReason.overlap),
            ],
          ),
        ),
      ),
    );
    expect(find.text('V85'), findsWidgets);
    expect(find.text('A+B'), findsWidgets);
    expect(
      find.textContaining('Klasse C (verworfen): 1 (25 %)'),
      findsOneWidget,
    );
    expect(find.textContaining('Überlappung: 1'), findsOneWidget);
    expect(find.text('50.0'), findsWidgets); // median of B: (48 + 52) / 2
  });
}
