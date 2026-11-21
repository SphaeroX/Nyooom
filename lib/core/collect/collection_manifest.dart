/// What the user heard in a clip.
enum ClipLabel {
  open('offen'),
  vehicle('auto'),
  noVehicle('kein_auto'),
  unclear('unklar');

  const ClipLabel(this.key);

  /// Name in `collection.json` and `labels.csv`.
  final String key;

  static ClipLabel fromKey(String? key) => ClipLabel.values.firstWhere(
    (l) => l.key == key,
    orElse: () => ClipLabel.open,
  );
}

/// One clip of a collection: an event window cut out of the recording.
class ClipEntry {
  const ClipEntry({
    required this.file,
    required this.startS,
    required this.peakTimeS,
    required this.durationS,
    required this.peakLevelDb,
    required this.floorDb,
    required this.eventDurationS,
    required this.overlap,
    this.label = ClipLabel.open,
  });

  factory ClipEntry.fromJson(Map<String, dynamic> json) => ClipEntry(
    file: json['file'] as String,
    startS: (json['startS'] as num).toDouble(),
    peakTimeS: (json['peakTimeS'] as num).toDouble(),
    durationS: (json['durationS'] as num).toDouble(),
    peakLevelDb: (json['peakLevelDb'] as num).toDouble(),
    floorDb: (json['floorDb'] as num).toDouble(),
    eventDurationS: (json['eventDurationS'] as num).toDouble(),
    overlap: json['overlap'] == true,
    label: ClipLabel.fromKey(json['label'] as String?),
  );

  /// File name inside the collection folder.
  final String file;

  /// Start of the clip and time of the level maximum, both in seconds from
  /// the start of the recording.
  final double startS;
  final double peakTimeS;

  /// Length of the clip in seconds.
  final double durationS;

  /// Level maximum and noise floor in the event band, in dB.
  final double peakLevelDb;
  final double floorDb;

  /// Time the level stays high (`dauer`, technik.pdf 9.1).
  final double eventDurationS;

  /// A second maximum of similar level lies in the window.
  final bool overlap;
  final ClipLabel label;

  double get levelAboveFloorDb => peakLevelDb - floorDb;

  ClipEntry withLabel(ClipLabel label) => ClipEntry(
    file: file,
    startS: startS,
    peakTimeS: peakTimeS,
    durationS: durationS,
    peakLevelDb: peakLevelDb,
    floorDb: floorDb,
    eventDurationS: eventDurationS,
    overlap: overlap,
    label: label,
  );

  Map<String, dynamic> toJson() => {
    'file': file,
    'startS': startS,
    'peakTimeS': peakTimeS,
    'durationS': durationS,
    'peakLevelDb': peakLevelDb,
    'floorDb': floorDb,
    'eventDurationS': eventDurationS,
    'overlap': overlap,
    'label': label.key,
  };
}

/// A collection of event clips for labelling (`collection.json`).
class CollectionManifest {
  const CollectionManifest({
    required this.id,
    required this.createdAtUtcMs,
    required this.source,
    required this.deviceModel,
    required this.inputDevice,
    required this.sampleRate,
    required this.clips,
    this.recordedS = 0,
  });

  factory CollectionManifest.fromJson(Map<String, dynamic> json) =>
      CollectionManifest(
        id: (json['id'] as num).toInt(),
        createdAtUtcMs: (json['createdAtUtcMs'] as num).toInt(),
        source: json['source'] as String? ?? 'live',
        deviceModel: json['deviceModel'] as String? ?? '',
        inputDevice: json['inputDevice'] as String? ?? 'intern',
        sampleRate: (json['sampleRate'] as num).toInt(),
        recordedS: (json['recordedS'] as num?)?.toDouble() ?? 0,
        clips: [
          for (final c in (json['clips'] as List?) ?? const [])
            ClipEntry.fromJson((c as Map).cast<String, dynamic>()),
        ],
      );

  /// Creation time in ms since epoch; also the folder name.
  final int id;
  final int createdAtUtcMs;

  /// `live` or `messreihe <id>`.
  final String source;
  final String deviceModel;

  /// `intern` or the name of the external input device.
  final String inputDevice;
  final int sampleRate;

  /// Seconds of audio the clips were cut from.
  final double recordedS;
  final List<ClipEntry> clips;

  int get labelledCount => clips.where((c) => c.label != ClipLabel.open).length;

  /// First clip without a label; null when all are labelled.
  int? get firstOpenIndex {
    final i = clips.indexWhere((c) => c.label == ClipLabel.open);
    return i < 0 ? null : i;
  }

  String get nextClipFile =>
      'clip_${(clips.length + 1).toString().padLeft(3, '0')}.wav';

  CollectionManifest _copy({List<ClipEntry>? clips, double? recordedS}) =>
      CollectionManifest(
        id: id,
        createdAtUtcMs: createdAtUtcMs,
        source: source,
        deviceModel: deviceModel,
        inputDevice: inputDevice,
        sampleRate: sampleRate,
        recordedS: recordedS ?? this.recordedS,
        clips: clips ?? this.clips,
      );

  CollectionManifest withLabel(int index, ClipLabel label) => _copy(
    clips: [
      for (var i = 0; i < clips.length; i++)
        i == index ? clips[i].withLabel(label) : clips[i],
    ],
  );

  CollectionManifest withClip(ClipEntry clip) => _copy(clips: [...clips, clip]);

  CollectionManifest withRecorded(double seconds) => _copy(recordedS: seconds);

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAtUtcMs': createdAtUtcMs,
    'source': source,
    'deviceModel': deviceModel,
    'inputDevice': inputDevice,
    'sampleRate': sampleRate,
    'recordedS': recordedS,
    'clips': [for (final c in clips) c.toJson()],
  };
}

/// Columns of `labels.csv`.
const labelsCsvColumns = [
  'datei',
  'start_s',
  'max_s',
  'laenge_s',
  'pegel_db',
  'rauschboden_db',
  'ueber_boden_db',
  'dauer_s',
  'ueberlappung',
  'label',
];

/// `labels.csv`: separator `;`, decimal point `.` (as the series export).
String labelsCsv(CollectionManifest manifest) {
  final b = StringBuffer()..writeln(labelsCsvColumns.join(';'));
  for (final c in manifest.clips) {
    b.writeln(
      [
        c.file,
        c.startS.toStringAsFixed(3),
        c.peakTimeS.toStringAsFixed(3),
        c.durationS.toStringAsFixed(3),
        c.peakLevelDb.toStringAsFixed(2),
        c.floorDb.toStringAsFixed(2),
        c.levelAboveFloorDb.toStringAsFixed(2),
        c.eventDurationS.toStringAsFixed(2),
        c.overlap ? '1' : '0',
        c.label.key,
      ].join(';'),
    );
  }
  return b.toString();
}
