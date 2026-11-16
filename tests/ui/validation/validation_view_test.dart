import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/validation/validation.dart';
import 'package:nyooom/core/validation/validation_csv.dart';
import 'package:nyooom/ui/validation/validation_screen.dart';

PassRecord rec(int zeit, double v) => PassRecord(
  zeitUtcMs: zeit,
  offsetS: 0,
  richtung: 1,
  klasse: QualityClass.a,
  v: v,
  sigmaV: 1.5,
  vLaufzeit: v,
  vDoppler: v,
  kappa: 2,
  dEst: 5,
  nToene: 2,
  restLaufzeitUs: 5,
  pegel: 20,
  dauer: 1,
  reason: null,
  laneIndex: 0,
  distanceUsedM: 5,
);

void main() {
  final matches = [
    for (var i = 0; i < 4; i++)
      ValidationMatch(
        reference: ReferencePassage(
          timeUtcMs: i * 60000,
          referenceSpeed: 30 / 3.6,
          distanceM: 5,
          bearingDeg: 10,
        ),
        record: rec(i * 60000, i.isEven ? 30.5 : 29.5),
      ),
  ];
  const config = NyooomConfig();
  final report = ValidationReport.from(
    matches,
    config: config,
    plusXBearingDeg: 0,
  );

  testWidgets('traffic light shows each acceptance criterion', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ValidationView(
              seriesId: 1,
              data: ValidationData(
                hasPosition: true,
                plusXBearingDeg: 0,
                trackCount: 1,
                match: MatchResult(
                  matches: matches,
                  unmatchedReferences: const [],
                  unmatchedRecords: const [],
                ),
                report: report,
              ),
            ),
          ),
        ),
      ),
    );
    for (final c in AcceptanceCriterion.values) {
      expect(find.text(c.label), findsOneWidget);
    }
    expect(
      find.textContaining('4 Referenzvorbeifahrten zugeordnet'),
      findsOneWidget,
    );
  });

  testWidgets('without site position a hint is shown', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ValidationView(
              seriesId: 1,
              data: ValidationData(
                hasPosition: false,
                plusXBearingDeg: null,
                trackCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('braucht der Standort eine Position'),
      findsOneWidget,
    );
  });

  test('validation CSV lists reference, measurement and error', () {
    final csv = validationToCsv(matches, plusXBearingDeg: 0).split('\n');
    expect(csv.first, startsWith('zeit_referenz;v_referenz'));
    expect(csv[1].split(';')[6], '1'); // expected direction
    expect(csv[1].split(';')[8], '0.50'); // error
  });
}
