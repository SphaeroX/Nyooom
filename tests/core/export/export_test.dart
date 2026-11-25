import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:nyooom/core/export/csv_export.dart';
import 'package:nyooom/core/export/json_export.dart';
import 'package:nyooom/core/export/zip_writer.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:test/test.dart';

const a = PassRecord(
  zeitUtcMs: 1763300000123,
  offsetS: 12.5,
  richtung: 1,
  klasse: QualityClass.a,
  v: 41.234,
  sigmaV: 1.6,
  vLaufzeit: 42,
  vDoppler: 40.9,
  kappa: 2.25,
  dEst: 5.1,
  nToene: 3,
  restLaufzeitUs: 6.5,
  pegel: 22.1,
  dauer: 1.3,
  reason: null,
  laneIndex: 0,
  distanceUsedM: 5,
  sigmaLaufzeit: 2.7,
  sigmaDoppler: 1.9,
);

const b = PassRecord(
  zeitUtcMs: 1763300020000,
  offsetS: 32.5,
  richtung: -1,
  klasse: QualityClass.b,
  v: 33,
  sigmaV: 2.6,
  vLaufzeit: 33,
  vDoppler: null,
  kappa: -1.3,
  dEst: null,
  nToene: 0,
  restLaufzeitUs: 7,
  pegel: 18,
  dauer: 1.1,
  reason: DowngradeReason.noTone,
  laneIndex: 1,
  distanceUsedM: 7.1,
);

void main() {
  group('CSV', () {
    test('header equals the field names of technik.pdf 9.1', () {
      final lines = const LineSplitter().convert(passesToCsv([a, b]));
      expect(
        lines.first,
        'zeit;richtung;klasse;v;sigma_v;v_laufzeit;v_doppler;kappa;d_est;'
        'n_toene;rest_laufzeit;pegel;dauer;grund;audio_pos_s;audio_pos',
      );
      expect(lines, hasLength(3));
    });

    test('empty Doppler fields stay empty, decimals use a point', () {
      final row = const LineSplitter().convert(passesToCsv([b]))[1].split(';');
      expect(row[0], '2025-11-16T13:33:40.000Z');
      expect(row[6], ''); // v_doppler
      expect(row[8], ''); // d_est
      expect(row[3], '33.00');
      expect(row[13], 'kein Ton');
    });

    test('position in the audio file in seconds and as h:mm:ss.s', () {
      final row = const LineSplitter().convert(passesToCsv([a]))[1].split(';');
      expect(row[14], '12.50');
      expect(row[15], '0:00:12.5');
    });

    test('audio position formatting rounds and carries into minutes', () {
      expect(formatAudioPosition(450), '0:07:30.0');
      expect(formatAudioPosition(59.96), '0:01:00.0');
      expect(formatAudioPosition(3723.44), '1:02:03.4');
      expect(formatAudioPosition(0), '0:00:00.0');
    });

    test('units name the audio position columns', () {
      expect(columnUnits['audio_pos_s'], contains('s'));
      expect(unitsText(), contains('audio_pos;'));
    });

    test('special characters in the reason are quoted', () {
      expect(csvField('a;b'), '"a;b"');
      expect(csvField('sagt "nein"'), '"sagt ""nein"""');
      expect(csvField('Zeile\nzwei'), '"Zeile\nzwei"');
      expect(csvField('normal'), 'normal');
    });
  });

  test('JSON round trip of a series gives identical data', () {
    final export = SeriesExport(
      series: const {'id': 4, 'site': 'Ring', 'temperatureC': 12.5},
      setup: const {'micSpacing': 0.148, 'lanes': []},
      config: const {'sampleRate': 48000},
      statistics: const {'medianAB': 37.1},
      records: const [a, b],
    );
    final text = export.toJsonText();
    final restored = SeriesExport.fromJsonText(text);
    expect(restored.toJsonText(), text);
    expect(restored.records.map((r) => r.toJson()), [a.toJson(), b.toJson()]);
    expect(jsonDecode(text)['units']['v'], 'km/h');
  });

  test('ZIP contains the expected files with their content', () {
    final writer = ZipWriter();
    writer.addFile('passes.csv', utf8.encode('x;y\n1;2\n'));
    final wav = Uint8List.fromList(List.generate(70000, (i) => i * 7 % 256));
    writer.addFile('audio.wav', wav);
    final bytes = writer.finish();
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.files.map((f) => f.name), ['passes.csv', 'audio.wav']);
    expect(utf8.decode(archive.files[0].content as List<int>), 'x;y\n1;2\n');
    expect(archive.files[1].content, wav);
  });
}
