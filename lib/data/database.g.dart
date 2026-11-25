// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputDeviceMeta = const VerificationMeta(
    'inputDevice',
  );
  @override
  late final GeneratedColumn<String> inputDevice = GeneratedColumn<String>(
    'input_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('intern'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, model, inputDevice];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('input_device')) {
      context.handle(
        _inputDeviceMeta,
        inputDevice.isAcceptableOrUnknown(
          data['input_device']!,
          _inputDeviceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      inputDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_device'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final int id;
  final String model;
  final String inputDevice;
  const DeviceRow({
    required this.id,
    required this.model,
    required this.inputDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['model'] = Variable<String>(model);
    map['input_device'] = Variable<String>(inputDevice);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      model: Value(model),
      inputDevice: Value(inputDevice),
    );
  }

  factory DeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      id: serializer.fromJson<int>(json['id']),
      model: serializer.fromJson<String>(json['model']),
      inputDevice: serializer.fromJson<String>(json['inputDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'model': serializer.toJson<String>(model),
      'inputDevice': serializer.toJson<String>(inputDevice),
    };
  }

  DeviceRow copyWith({int? id, String? model, String? inputDevice}) =>
      DeviceRow(
        id: id ?? this.id,
        model: model ?? this.model,
        inputDevice: inputDevice ?? this.inputDevice,
      );
  DeviceRow copyWithCompanion(DevicesCompanion data) {
    return DeviceRow(
      id: data.id.present ? data.id.value : this.id,
      model: data.model.present ? data.model.value : this.model,
      inputDevice: data.inputDevice.present
          ? data.inputDevice.value
          : this.inputDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('id: $id, ')
          ..write('model: $model, ')
          ..write('inputDevice: $inputDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, model, inputDevice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.id == this.id &&
          other.model == this.model &&
          other.inputDevice == this.inputDevice);
}

class DevicesCompanion extends UpdateCompanion<DeviceRow> {
  final Value<int> id;
  final Value<String> model;
  final Value<String> inputDevice;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.model = const Value.absent(),
    this.inputDevice = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required String model,
    this.inputDevice = const Value.absent(),
  }) : model = Value(model);
  static Insertable<DeviceRow> custom({
    Expression<int>? id,
    Expression<String>? model,
    Expression<String>? inputDevice,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (inputDevice != null) 'input_device': inputDevice,
    });
  }

  DevicesCompanion copyWith({
    Value<int>? id,
    Value<String>? model,
    Value<String>? inputDevice,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      model: model ?? this.model,
      inputDevice: inputDevice ?? this.inputDevice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (inputDevice.present) {
      map['input_device'] = Variable<String>(inputDevice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('model: $model, ')
          ..write('inputDevice: $inputDevice')
          ..write(')'))
        .toString();
  }
}

class $CalibrationsTable extends Calibrations
    with TableInfo<$CalibrationsTable, CalibrationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalibrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _micSpacingMMeta = const VerificationMeta(
    'micSpacingM',
  );
  @override
  late final GeneratedColumn<double> micSpacingM = GeneratedColumn<double>(
    'mic_spacing_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelOffsetSMeta = const VerificationMeta(
    'channelOffsetS',
  );
  @override
  late final GeneratedColumn<double> channelOffsetS = GeneratedColumn<double>(
    'channel_offset_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _swapChannelsMeta = const VerificationMeta(
    'swapChannels',
  );
  @override
  late final GeneratedColumn<bool> swapChannels = GeneratedColumn<bool>(
    'swap_channels',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("swap_channels" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksJsonMeta = const VerificationMeta(
    'checksJson',
  );
  @override
  late final GeneratedColumn<String> checksJson = GeneratedColumn<String>(
    'checks_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    micSpacingM,
    channelOffsetS,
    temperatureC,
    swapChannels,
    createdAtUtcMs,
    checksJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calibrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalibrationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('mic_spacing_m')) {
      context.handle(
        _micSpacingMMeta,
        micSpacingM.isAcceptableOrUnknown(
          data['mic_spacing_m']!,
          _micSpacingMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_micSpacingMMeta);
    }
    if (data.containsKey('channel_offset_s')) {
      context.handle(
        _channelOffsetSMeta,
        channelOffsetS.isAcceptableOrUnknown(
          data['channel_offset_s']!,
          _channelOffsetSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelOffsetSMeta);
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureCMeta);
    }
    if (data.containsKey('swap_channels')) {
      context.handle(
        _swapChannelsMeta,
        swapChannels.isAcceptableOrUnknown(
          data['swap_channels']!,
          _swapChannelsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('checks_json')) {
      context.handle(
        _checksJsonMeta,
        checksJson.isAcceptableOrUnknown(data['checks_json']!, _checksJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalibrationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalibrationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      micSpacingM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mic_spacing_m'],
      )!,
      channelOffsetS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}channel_offset_s'],
      )!,
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      )!,
      swapChannels: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}swap_channels'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      checksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checks_json'],
      ),
    );
  }

  @override
  $CalibrationsTable createAlias(String alias) {
    return $CalibrationsTable(attachedDatabase, alias);
  }
}

class CalibrationRow extends DataClass implements Insertable<CalibrationRow> {
  final int id;
  final int deviceId;
  final double micSpacingM;
  final double channelOffsetS;
  final double temperatureC;
  final bool swapChannels;
  final int createdAtUtcMs;

  /// Results of the suitability checks (technik.pdf 4.4) as JSON.
  final String? checksJson;
  const CalibrationRow({
    required this.id,
    required this.deviceId,
    required this.micSpacingM,
    required this.channelOffsetS,
    required this.temperatureC,
    required this.swapChannels,
    required this.createdAtUtcMs,
    this.checksJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<int>(deviceId);
    map['mic_spacing_m'] = Variable<double>(micSpacingM);
    map['channel_offset_s'] = Variable<double>(channelOffsetS);
    map['temperature_c'] = Variable<double>(temperatureC);
    map['swap_channels'] = Variable<bool>(swapChannels);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    if (!nullToAbsent || checksJson != null) {
      map['checks_json'] = Variable<String>(checksJson);
    }
    return map;
  }

  CalibrationsCompanion toCompanion(bool nullToAbsent) {
    return CalibrationsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      micSpacingM: Value(micSpacingM),
      channelOffsetS: Value(channelOffsetS),
      temperatureC: Value(temperatureC),
      swapChannels: Value(swapChannels),
      createdAtUtcMs: Value(createdAtUtcMs),
      checksJson: checksJson == null && nullToAbsent
          ? const Value.absent()
          : Value(checksJson),
    );
  }

  factory CalibrationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalibrationRow(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      micSpacingM: serializer.fromJson<double>(json['micSpacingM']),
      channelOffsetS: serializer.fromJson<double>(json['channelOffsetS']),
      temperatureC: serializer.fromJson<double>(json['temperatureC']),
      swapChannels: serializer.fromJson<bool>(json['swapChannels']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      checksJson: serializer.fromJson<String?>(json['checksJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<int>(deviceId),
      'micSpacingM': serializer.toJson<double>(micSpacingM),
      'channelOffsetS': serializer.toJson<double>(channelOffsetS),
      'temperatureC': serializer.toJson<double>(temperatureC),
      'swapChannels': serializer.toJson<bool>(swapChannels),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'checksJson': serializer.toJson<String?>(checksJson),
    };
  }

  CalibrationRow copyWith({
    int? id,
    int? deviceId,
    double? micSpacingM,
    double? channelOffsetS,
    double? temperatureC,
    bool? swapChannels,
    int? createdAtUtcMs,
    Value<String?> checksJson = const Value.absent(),
  }) => CalibrationRow(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    micSpacingM: micSpacingM ?? this.micSpacingM,
    channelOffsetS: channelOffsetS ?? this.channelOffsetS,
    temperatureC: temperatureC ?? this.temperatureC,
    swapChannels: swapChannels ?? this.swapChannels,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    checksJson: checksJson.present ? checksJson.value : this.checksJson,
  );
  CalibrationRow copyWithCompanion(CalibrationsCompanion data) {
    return CalibrationRow(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      micSpacingM: data.micSpacingM.present
          ? data.micSpacingM.value
          : this.micSpacingM,
      channelOffsetS: data.channelOffsetS.present
          ? data.channelOffsetS.value
          : this.channelOffsetS,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      swapChannels: data.swapChannels.present
          ? data.swapChannels.value
          : this.swapChannels,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      checksJson: data.checksJson.present
          ? data.checksJson.value
          : this.checksJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalibrationRow(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('micSpacingM: $micSpacingM, ')
          ..write('channelOffsetS: $channelOffsetS, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('swapChannels: $swapChannels, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('checksJson: $checksJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    micSpacingM,
    channelOffsetS,
    temperatureC,
    swapChannels,
    createdAtUtcMs,
    checksJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalibrationRow &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.micSpacingM == this.micSpacingM &&
          other.channelOffsetS == this.channelOffsetS &&
          other.temperatureC == this.temperatureC &&
          other.swapChannels == this.swapChannels &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.checksJson == this.checksJson);
}

class CalibrationsCompanion extends UpdateCompanion<CalibrationRow> {
  final Value<int> id;
  final Value<int> deviceId;
  final Value<double> micSpacingM;
  final Value<double> channelOffsetS;
  final Value<double> temperatureC;
  final Value<bool> swapChannels;
  final Value<int> createdAtUtcMs;
  final Value<String?> checksJson;
  const CalibrationsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.micSpacingM = const Value.absent(),
    this.channelOffsetS = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.swapChannels = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.checksJson = const Value.absent(),
  });
  CalibrationsCompanion.insert({
    this.id = const Value.absent(),
    required int deviceId,
    required double micSpacingM,
    required double channelOffsetS,
    required double temperatureC,
    this.swapChannels = const Value.absent(),
    required int createdAtUtcMs,
    this.checksJson = const Value.absent(),
  }) : deviceId = Value(deviceId),
       micSpacingM = Value(micSpacingM),
       channelOffsetS = Value(channelOffsetS),
       temperatureC = Value(temperatureC),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<CalibrationRow> custom({
    Expression<int>? id,
    Expression<int>? deviceId,
    Expression<double>? micSpacingM,
    Expression<double>? channelOffsetS,
    Expression<double>? temperatureC,
    Expression<bool>? swapChannels,
    Expression<int>? createdAtUtcMs,
    Expression<String>? checksJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (micSpacingM != null) 'mic_spacing_m': micSpacingM,
      if (channelOffsetS != null) 'channel_offset_s': channelOffsetS,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (swapChannels != null) 'swap_channels': swapChannels,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (checksJson != null) 'checks_json': checksJson,
    });
  }

  CalibrationsCompanion copyWith({
    Value<int>? id,
    Value<int>? deviceId,
    Value<double>? micSpacingM,
    Value<double>? channelOffsetS,
    Value<double>? temperatureC,
    Value<bool>? swapChannels,
    Value<int>? createdAtUtcMs,
    Value<String?>? checksJson,
  }) {
    return CalibrationsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      micSpacingM: micSpacingM ?? this.micSpacingM,
      channelOffsetS: channelOffsetS ?? this.channelOffsetS,
      temperatureC: temperatureC ?? this.temperatureC,
      swapChannels: swapChannels ?? this.swapChannels,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      checksJson: checksJson ?? this.checksJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (micSpacingM.present) {
      map['mic_spacing_m'] = Variable<double>(micSpacingM.value);
    }
    if (channelOffsetS.present) {
      map['channel_offset_s'] = Variable<double>(channelOffsetS.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (swapChannels.present) {
      map['swap_channels'] = Variable<bool>(swapChannels.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (checksJson.present) {
      map['checks_json'] = Variable<String>(checksJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalibrationsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('micSpacingM: $micSpacingM, ')
          ..write('channelOffsetS: $channelOffsetS, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('swapChannels: $swapChannels, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('checksJson: $checksJson')
          ..write(')'))
        .toString();
  }
}

class $SitesTable extends Sites with TableInfo<$SitesTable, SiteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _micHeightMMeta = const VerificationMeta(
    'micHeightM',
  );
  @override
  late final GeneratedColumn<double> micHeightM = GeneratedColumn<double>(
    'mic_height_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedLimitKmhMeta = const VerificationMeta(
    'speedLimitKmh',
  );
  @override
  late final GeneratedColumn<double> speedLimitKmh = GeneratedColumn<double>(
    'speed_limit_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plusXBearingDegMeta = const VerificationMeta(
    'plusXBearingDeg',
  );
  @override
  late final GeneratedColumn<double> plusXBearingDeg = GeneratedColumn<double>(
    'plus_x_bearing_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    micHeightM,
    speedLimitKmh,
    latitude,
    longitude,
    plusXBearingDeg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sites';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mic_height_m')) {
      context.handle(
        _micHeightMMeta,
        micHeightM.isAcceptableOrUnknown(
          data['mic_height_m']!,
          _micHeightMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_micHeightMMeta);
    }
    if (data.containsKey('speed_limit_kmh')) {
      context.handle(
        _speedLimitKmhMeta,
        speedLimitKmh.isAcceptableOrUnknown(
          data['speed_limit_kmh']!,
          _speedLimitKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_speedLimitKmhMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('plus_x_bearing_deg')) {
      context.handle(
        _plusXBearingDegMeta,
        plusXBearingDeg.isAcceptableOrUnknown(
          data['plus_x_bearing_deg']!,
          _plusXBearingDegMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SiteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      micHeightM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mic_height_m'],
      )!,
      speedLimitKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_limit_kmh'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      plusXBearingDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}plus_x_bearing_deg'],
      ),
    );
  }

  @override
  $SitesTable createAlias(String alias) {
    return $SitesTable(attachedDatabase, alias);
  }
}

class SiteRow extends DataClass implements Insertable<SiteRow> {
  final int id;
  final String name;
  final double micHeightM;
  final double speedLimitKmh;
  final double? latitude;
  final double? longitude;

  /// Compass bearing of the +x direction in degrees (schema 4).
  final double? plusXBearingDeg;
  const SiteRow({
    required this.id,
    required this.name,
    required this.micHeightM,
    required this.speedLimitKmh,
    this.latitude,
    this.longitude,
    this.plusXBearingDeg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['mic_height_m'] = Variable<double>(micHeightM);
    map['speed_limit_kmh'] = Variable<double>(speedLimitKmh);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || plusXBearingDeg != null) {
      map['plus_x_bearing_deg'] = Variable<double>(plusXBearingDeg);
    }
    return map;
  }

  SitesCompanion toCompanion(bool nullToAbsent) {
    return SitesCompanion(
      id: Value(id),
      name: Value(name),
      micHeightM: Value(micHeightM),
      speedLimitKmh: Value(speedLimitKmh),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      plusXBearingDeg: plusXBearingDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(plusXBearingDeg),
    );
  }

  factory SiteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      micHeightM: serializer.fromJson<double>(json['micHeightM']),
      speedLimitKmh: serializer.fromJson<double>(json['speedLimitKmh']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      plusXBearingDeg: serializer.fromJson<double?>(json['plusXBearingDeg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'micHeightM': serializer.toJson<double>(micHeightM),
      'speedLimitKmh': serializer.toJson<double>(speedLimitKmh),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'plusXBearingDeg': serializer.toJson<double?>(plusXBearingDeg),
    };
  }

  SiteRow copyWith({
    int? id,
    String? name,
    double? micHeightM,
    double? speedLimitKmh,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> plusXBearingDeg = const Value.absent(),
  }) => SiteRow(
    id: id ?? this.id,
    name: name ?? this.name,
    micHeightM: micHeightM ?? this.micHeightM,
    speedLimitKmh: speedLimitKmh ?? this.speedLimitKmh,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    plusXBearingDeg: plusXBearingDeg.present
        ? plusXBearingDeg.value
        : this.plusXBearingDeg,
  );
  SiteRow copyWithCompanion(SitesCompanion data) {
    return SiteRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      micHeightM: data.micHeightM.present
          ? data.micHeightM.value
          : this.micHeightM,
      speedLimitKmh: data.speedLimitKmh.present
          ? data.speedLimitKmh.value
          : this.speedLimitKmh,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      plusXBearingDeg: data.plusXBearingDeg.present
          ? data.plusXBearingDeg.value
          : this.plusXBearingDeg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('micHeightM: $micHeightM, ')
          ..write('speedLimitKmh: $speedLimitKmh, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('plusXBearingDeg: $plusXBearingDeg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    micHeightM,
    speedLimitKmh,
    latitude,
    longitude,
    plusXBearingDeg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.micHeightM == this.micHeightM &&
          other.speedLimitKmh == this.speedLimitKmh &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.plusXBearingDeg == this.plusXBearingDeg);
}

class SitesCompanion extends UpdateCompanion<SiteRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> micHeightM;
  final Value<double> speedLimitKmh;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> plusXBearingDeg;
  const SitesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.micHeightM = const Value.absent(),
    this.speedLimitKmh = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.plusXBearingDeg = const Value.absent(),
  });
  SitesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double micHeightM,
    required double speedLimitKmh,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.plusXBearingDeg = const Value.absent(),
  }) : name = Value(name),
       micHeightM = Value(micHeightM),
       speedLimitKmh = Value(speedLimitKmh);
  static Insertable<SiteRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? micHeightM,
    Expression<double>? speedLimitKmh,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? plusXBearingDeg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (micHeightM != null) 'mic_height_m': micHeightM,
      if (speedLimitKmh != null) 'speed_limit_kmh': speedLimitKmh,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (plusXBearingDeg != null) 'plus_x_bearing_deg': plusXBearingDeg,
    });
  }

  SitesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? micHeightM,
    Value<double>? speedLimitKmh,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? plusXBearingDeg,
  }) {
    return SitesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      micHeightM: micHeightM ?? this.micHeightM,
      speedLimitKmh: speedLimitKmh ?? this.speedLimitKmh,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      plusXBearingDeg: plusXBearingDeg ?? this.plusXBearingDeg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (micHeightM.present) {
      map['mic_height_m'] = Variable<double>(micHeightM.value);
    }
    if (speedLimitKmh.present) {
      map['speed_limit_kmh'] = Variable<double>(speedLimitKmh.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (plusXBearingDeg.present) {
      map['plus_x_bearing_deg'] = Variable<double>(plusXBearingDeg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SitesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('micHeightM: $micHeightM, ')
          ..write('speedLimitKmh: $speedLimitKmh, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('plusXBearingDeg: $plusXBearingDeg')
          ..write(')'))
        .toString();
  }
}

class $LanesTable extends Lanes with TableInfo<$LanesTable, LaneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LanesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sites (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horizontalDistanceMMeta =
      const VerificationMeta('horizontalDistanceM');
  @override
  late final GeneratedColumn<double> horizontalDistanceM =
      GeneratedColumn<double>(
        'horizontal_distance_m',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    siteId,
    position,
    horizontalDistanceM,
    direction,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lanes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LaneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('horizontal_distance_m')) {
      context.handle(
        _horizontalDistanceMMeta,
        horizontalDistanceM.isAcceptableOrUnknown(
          data['horizontal_distance_m']!,
          _horizontalDistanceMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_horizontalDistanceMMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LaneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LaneRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}site_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      horizontalDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}horizontal_distance_m'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
    );
  }

  @override
  $LanesTable createAlias(String alias) {
    return $LanesTable(attachedDatabase, alias);
  }
}

class LaneRow extends DataClass implements Insertable<LaneRow> {
  final int id;
  final int siteId;
  final int position;
  final double horizontalDistanceM;
  final int direction;
  const LaneRow({
    required this.id,
    required this.siteId,
    required this.position,
    required this.horizontalDistanceM,
    required this.direction,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['site_id'] = Variable<int>(siteId);
    map['position'] = Variable<int>(position);
    map['horizontal_distance_m'] = Variable<double>(horizontalDistanceM);
    map['direction'] = Variable<int>(direction);
    return map;
  }

  LanesCompanion toCompanion(bool nullToAbsent) {
    return LanesCompanion(
      id: Value(id),
      siteId: Value(siteId),
      position: Value(position),
      horizontalDistanceM: Value(horizontalDistanceM),
      direction: Value(direction),
    );
  }

  factory LaneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LaneRow(
      id: serializer.fromJson<int>(json['id']),
      siteId: serializer.fromJson<int>(json['siteId']),
      position: serializer.fromJson<int>(json['position']),
      horizontalDistanceM: serializer.fromJson<double>(
        json['horizontalDistanceM'],
      ),
      direction: serializer.fromJson<int>(json['direction']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'siteId': serializer.toJson<int>(siteId),
      'position': serializer.toJson<int>(position),
      'horizontalDistanceM': serializer.toJson<double>(horizontalDistanceM),
      'direction': serializer.toJson<int>(direction),
    };
  }

  LaneRow copyWith({
    int? id,
    int? siteId,
    int? position,
    double? horizontalDistanceM,
    int? direction,
  }) => LaneRow(
    id: id ?? this.id,
    siteId: siteId ?? this.siteId,
    position: position ?? this.position,
    horizontalDistanceM: horizontalDistanceM ?? this.horizontalDistanceM,
    direction: direction ?? this.direction,
  );
  LaneRow copyWithCompanion(LanesCompanion data) {
    return LaneRow(
      id: data.id.present ? data.id.value : this.id,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      position: data.position.present ? data.position.value : this.position,
      horizontalDistanceM: data.horizontalDistanceM.present
          ? data.horizontalDistanceM.value
          : this.horizontalDistanceM,
      direction: data.direction.present ? data.direction.value : this.direction,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LaneRow(')
          ..write('id: $id, ')
          ..write('siteId: $siteId, ')
          ..write('position: $position, ')
          ..write('horizontalDistanceM: $horizontalDistanceM, ')
          ..write('direction: $direction')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, siteId, position, horizontalDistanceM, direction);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LaneRow &&
          other.id == this.id &&
          other.siteId == this.siteId &&
          other.position == this.position &&
          other.horizontalDistanceM == this.horizontalDistanceM &&
          other.direction == this.direction);
}

class LanesCompanion extends UpdateCompanion<LaneRow> {
  final Value<int> id;
  final Value<int> siteId;
  final Value<int> position;
  final Value<double> horizontalDistanceM;
  final Value<int> direction;
  const LanesCompanion({
    this.id = const Value.absent(),
    this.siteId = const Value.absent(),
    this.position = const Value.absent(),
    this.horizontalDistanceM = const Value.absent(),
    this.direction = const Value.absent(),
  });
  LanesCompanion.insert({
    this.id = const Value.absent(),
    required int siteId,
    required int position,
    required double horizontalDistanceM,
    required int direction,
  }) : siteId = Value(siteId),
       position = Value(position),
       horizontalDistanceM = Value(horizontalDistanceM),
       direction = Value(direction);
  static Insertable<LaneRow> custom({
    Expression<int>? id,
    Expression<int>? siteId,
    Expression<int>? position,
    Expression<double>? horizontalDistanceM,
    Expression<int>? direction,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (siteId != null) 'site_id': siteId,
      if (position != null) 'position': position,
      if (horizontalDistanceM != null)
        'horizontal_distance_m': horizontalDistanceM,
      if (direction != null) 'direction': direction,
    });
  }

  LanesCompanion copyWith({
    Value<int>? id,
    Value<int>? siteId,
    Value<int>? position,
    Value<double>? horizontalDistanceM,
    Value<int>? direction,
  }) {
    return LanesCompanion(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      position: position ?? this.position,
      horizontalDistanceM: horizontalDistanceM ?? this.horizontalDistanceM,
      direction: direction ?? this.direction,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (horizontalDistanceM.present) {
      map['horizontal_distance_m'] = Variable<double>(
        horizontalDistanceM.value,
      );
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LanesCompanion(')
          ..write('id: $id, ')
          ..write('siteId: $siteId, ')
          ..write('position: $position, ')
          ..write('horizontalDistanceM: $horizontalDistanceM, ')
          ..write('direction: $direction')
          ..write(')'))
        .toString();
  }
}

class $MeasurementSeriesTable extends MeasurementSeries
    with TableInfo<$MeasurementSeriesTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementSeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sites (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _calibrationIdMeta = const VerificationMeta(
    'calibrationId',
  );
  @override
  late final GeneratedColumn<int> calibrationId = GeneratedColumn<int>(
    'calibration_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calibrations (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedOfSoundMeta = const VerificationMeta(
    'speedOfSound',
  );
  @override
  late final GeneratedColumn<double> speedOfSound = GeneratedColumn<double>(
    'speed_of_sound',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceHeightMMeta = const VerificationMeta(
    'sourceHeightM',
  );
  @override
  late final GeneratedColumn<double> sourceHeightM = GeneratedColumn<double>(
    'source_height_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtUtcMsMeta = const VerificationMeta(
    'startedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> startedAtUtcMs = GeneratedColumn<int>(
    'started_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtUtcMsMeta = const VerificationMeta(
    'endedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> endedAtUtcMs = GeneratedColumn<int>(
    'ended_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directoryMeta = const VerificationMeta(
    'directory',
  );
  @override
  late final GeneratedColumn<String> directory = GeneratedColumn<String>(
    'directory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saveRawAudioMeta = const VerificationMeta(
    'saveRawAudio',
  );
  @override
  late final GeneratedColumn<bool> saveRawAudio = GeneratedColumn<bool>(
    'save_raw_audio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("save_raw_audio" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _simulatedMeta = const VerificationMeta(
    'simulated',
  );
  @override
  late final GeneratedColumn<bool> simulated = GeneratedColumn<bool>(
    'simulated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("simulated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentsJsonMeta = const VerificationMeta(
    'segmentsJson',
  );
  @override
  late final GeneratedColumn<String> segmentsJson = GeneratedColumn<String>(
    'segments_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _learnedMicSpacingMMeta =
      const VerificationMeta('learnedMicSpacingM');
  @override
  late final GeneratedColumn<double> learnedMicSpacingM =
      GeneratedColumn<double>(
        'learned_mic_spacing_m',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _learnedChannelOffsetSMeta =
      const VerificationMeta('learnedChannelOffsetS');
  @override
  late final GeneratedColumn<double> learnedChannelOffsetS =
      GeneratedColumn<double>(
        'learned_channel_offset_s',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _learnedPassCountMeta = const VerificationMeta(
    'learnedPassCount',
  );
  @override
  late final GeneratedColumn<int> learnedPassCount = GeneratedColumn<int>(
    'learned_pass_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureLogJsonMeta =
      const VerificationMeta('temperatureLogJson');
  @override
  late final GeneratedColumn<String> temperatureLogJson =
      GeneratedColumn<String>(
        'temperature_log_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    siteId,
    deviceId,
    calibrationId,
    temperatureC,
    speedOfSound,
    sourceHeightM,
    startedAtUtcMs,
    endedAtUtcMs,
    directory,
    saveRawAudio,
    simulated,
    configJson,
    segmentsJson,
    learnedMicSpacingM,
    learnedChannelOffsetS,
    learnedPassCount,
    temperatureLogJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurement_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('calibration_id')) {
      context.handle(
        _calibrationIdMeta,
        calibrationId.isAcceptableOrUnknown(
          data['calibration_id']!,
          _calibrationIdMeta,
        ),
      );
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureCMeta);
    }
    if (data.containsKey('speed_of_sound')) {
      context.handle(
        _speedOfSoundMeta,
        speedOfSound.isAcceptableOrUnknown(
          data['speed_of_sound']!,
          _speedOfSoundMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_speedOfSoundMeta);
    }
    if (data.containsKey('source_height_m')) {
      context.handle(
        _sourceHeightMMeta,
        sourceHeightM.isAcceptableOrUnknown(
          data['source_height_m']!,
          _sourceHeightMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceHeightMMeta);
    }
    if (data.containsKey('started_at_utc_ms')) {
      context.handle(
        _startedAtUtcMsMeta,
        startedAtUtcMs.isAcceptableOrUnknown(
          data['started_at_utc_ms']!,
          _startedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtUtcMsMeta);
    }
    if (data.containsKey('ended_at_utc_ms')) {
      context.handle(
        _endedAtUtcMsMeta,
        endedAtUtcMs.isAcceptableOrUnknown(
          data['ended_at_utc_ms']!,
          _endedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('directory')) {
      context.handle(
        _directoryMeta,
        directory.isAcceptableOrUnknown(data['directory']!, _directoryMeta),
      );
    } else if (isInserting) {
      context.missing(_directoryMeta);
    }
    if (data.containsKey('save_raw_audio')) {
      context.handle(
        _saveRawAudioMeta,
        saveRawAudio.isAcceptableOrUnknown(
          data['save_raw_audio']!,
          _saveRawAudioMeta,
        ),
      );
    }
    if (data.containsKey('simulated')) {
      context.handle(
        _simulatedMeta,
        simulated.isAcceptableOrUnknown(data['simulated']!, _simulatedMeta),
      );
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('segments_json')) {
      context.handle(
        _segmentsJsonMeta,
        segmentsJson.isAcceptableOrUnknown(
          data['segments_json']!,
          _segmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('learned_mic_spacing_m')) {
      context.handle(
        _learnedMicSpacingMMeta,
        learnedMicSpacingM.isAcceptableOrUnknown(
          data['learned_mic_spacing_m']!,
          _learnedMicSpacingMMeta,
        ),
      );
    }
    if (data.containsKey('learned_channel_offset_s')) {
      context.handle(
        _learnedChannelOffsetSMeta,
        learnedChannelOffsetS.isAcceptableOrUnknown(
          data['learned_channel_offset_s']!,
          _learnedChannelOffsetSMeta,
        ),
      );
    }
    if (data.containsKey('learned_pass_count')) {
      context.handle(
        _learnedPassCountMeta,
        learnedPassCount.isAcceptableOrUnknown(
          data['learned_pass_count']!,
          _learnedPassCountMeta,
        ),
      );
    }
    if (data.containsKey('temperature_log_json')) {
      context.handle(
        _temperatureLogJsonMeta,
        temperatureLogJson.isAcceptableOrUnknown(
          data['temperature_log_json']!,
          _temperatureLogJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}site_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      ),
      calibrationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calibration_id'],
      ),
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      )!,
      speedOfSound: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_of_sound'],
      )!,
      sourceHeightM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}source_height_m'],
      )!,
      startedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_utc_ms'],
      )!,
      endedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_utc_ms'],
      ),
      directory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directory'],
      )!,
      saveRawAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}save_raw_audio'],
      )!,
      simulated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}simulated'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      segmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segments_json'],
      ),
      learnedMicSpacingM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}learned_mic_spacing_m'],
      ),
      learnedChannelOffsetS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}learned_channel_offset_s'],
      ),
      learnedPassCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_pass_count'],
      ),
      temperatureLogJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temperature_log_json'],
      ),
    );
  }

  @override
  $MeasurementSeriesTable createAlias(String alias) {
    return $MeasurementSeriesTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final int id;
  final int siteId;
  final int? deviceId;
  final int? calibrationId;
  final double temperatureC;
  final double speedOfSound;
  final double sourceHeightM;
  final int startedAtUtcMs;
  final int? endedAtUtcMs;
  final String directory;
  final bool saveRawAudio;
  final bool simulated;
  final String configJson;

  /// Recording parts of a continued series as JSON (schema 5); null for
  /// one continuous recording.
  final String? segmentsJson;

  /// Effective microphone spacing in m, channel offset in s and number of
  /// passes they were learned from (schema 6); null = calibration is used.
  final double? learnedMicSpacingM;
  final double? learnedChannelOffsetS;
  final int? learnedPassCount;

  /// Temperature readings over the recording as JSON (schema 7); null if
  /// the start temperature held for the whole series.
  final String? temperatureLogJson;
  const SeriesRow({
    required this.id,
    required this.siteId,
    this.deviceId,
    this.calibrationId,
    required this.temperatureC,
    required this.speedOfSound,
    required this.sourceHeightM,
    required this.startedAtUtcMs,
    this.endedAtUtcMs,
    required this.directory,
    required this.saveRawAudio,
    required this.simulated,
    required this.configJson,
    this.segmentsJson,
    this.learnedMicSpacingM,
    this.learnedChannelOffsetS,
    this.learnedPassCount,
    this.temperatureLogJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['site_id'] = Variable<int>(siteId);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<int>(deviceId);
    }
    if (!nullToAbsent || calibrationId != null) {
      map['calibration_id'] = Variable<int>(calibrationId);
    }
    map['temperature_c'] = Variable<double>(temperatureC);
    map['speed_of_sound'] = Variable<double>(speedOfSound);
    map['source_height_m'] = Variable<double>(sourceHeightM);
    map['started_at_utc_ms'] = Variable<int>(startedAtUtcMs);
    if (!nullToAbsent || endedAtUtcMs != null) {
      map['ended_at_utc_ms'] = Variable<int>(endedAtUtcMs);
    }
    map['directory'] = Variable<String>(directory);
    map['save_raw_audio'] = Variable<bool>(saveRawAudio);
    map['simulated'] = Variable<bool>(simulated);
    map['config_json'] = Variable<String>(configJson);
    if (!nullToAbsent || segmentsJson != null) {
      map['segments_json'] = Variable<String>(segmentsJson);
    }
    if (!nullToAbsent || learnedMicSpacingM != null) {
      map['learned_mic_spacing_m'] = Variable<double>(learnedMicSpacingM);
    }
    if (!nullToAbsent || learnedChannelOffsetS != null) {
      map['learned_channel_offset_s'] = Variable<double>(learnedChannelOffsetS);
    }
    if (!nullToAbsent || learnedPassCount != null) {
      map['learned_pass_count'] = Variable<int>(learnedPassCount);
    }
    if (!nullToAbsent || temperatureLogJson != null) {
      map['temperature_log_json'] = Variable<String>(temperatureLogJson);
    }
    return map;
  }

  MeasurementSeriesCompanion toCompanion(bool nullToAbsent) {
    return MeasurementSeriesCompanion(
      id: Value(id),
      siteId: Value(siteId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      calibrationId: calibrationId == null && nullToAbsent
          ? const Value.absent()
          : Value(calibrationId),
      temperatureC: Value(temperatureC),
      speedOfSound: Value(speedOfSound),
      sourceHeightM: Value(sourceHeightM),
      startedAtUtcMs: Value(startedAtUtcMs),
      endedAtUtcMs: endedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtUtcMs),
      directory: Value(directory),
      saveRawAudio: Value(saveRawAudio),
      simulated: Value(simulated),
      configJson: Value(configJson),
      segmentsJson: segmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentsJson),
      learnedMicSpacingM: learnedMicSpacingM == null && nullToAbsent
          ? const Value.absent()
          : Value(learnedMicSpacingM),
      learnedChannelOffsetS: learnedChannelOffsetS == null && nullToAbsent
          ? const Value.absent()
          : Value(learnedChannelOffsetS),
      learnedPassCount: learnedPassCount == null && nullToAbsent
          ? const Value.absent()
          : Value(learnedPassCount),
      temperatureLogJson: temperatureLogJson == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureLogJson),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<int>(json['id']),
      siteId: serializer.fromJson<int>(json['siteId']),
      deviceId: serializer.fromJson<int?>(json['deviceId']),
      calibrationId: serializer.fromJson<int?>(json['calibrationId']),
      temperatureC: serializer.fromJson<double>(json['temperatureC']),
      speedOfSound: serializer.fromJson<double>(json['speedOfSound']),
      sourceHeightM: serializer.fromJson<double>(json['sourceHeightM']),
      startedAtUtcMs: serializer.fromJson<int>(json['startedAtUtcMs']),
      endedAtUtcMs: serializer.fromJson<int?>(json['endedAtUtcMs']),
      directory: serializer.fromJson<String>(json['directory']),
      saveRawAudio: serializer.fromJson<bool>(json['saveRawAudio']),
      simulated: serializer.fromJson<bool>(json['simulated']),
      configJson: serializer.fromJson<String>(json['configJson']),
      segmentsJson: serializer.fromJson<String?>(json['segmentsJson']),
      learnedMicSpacingM: serializer.fromJson<double?>(
        json['learnedMicSpacingM'],
      ),
      learnedChannelOffsetS: serializer.fromJson<double?>(
        json['learnedChannelOffsetS'],
      ),
      learnedPassCount: serializer.fromJson<int?>(json['learnedPassCount']),
      temperatureLogJson: serializer.fromJson<String?>(
        json['temperatureLogJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'siteId': serializer.toJson<int>(siteId),
      'deviceId': serializer.toJson<int?>(deviceId),
      'calibrationId': serializer.toJson<int?>(calibrationId),
      'temperatureC': serializer.toJson<double>(temperatureC),
      'speedOfSound': serializer.toJson<double>(speedOfSound),
      'sourceHeightM': serializer.toJson<double>(sourceHeightM),
      'startedAtUtcMs': serializer.toJson<int>(startedAtUtcMs),
      'endedAtUtcMs': serializer.toJson<int?>(endedAtUtcMs),
      'directory': serializer.toJson<String>(directory),
      'saveRawAudio': serializer.toJson<bool>(saveRawAudio),
      'simulated': serializer.toJson<bool>(simulated),
      'configJson': serializer.toJson<String>(configJson),
      'segmentsJson': serializer.toJson<String?>(segmentsJson),
      'learnedMicSpacingM': serializer.toJson<double?>(learnedMicSpacingM),
      'learnedChannelOffsetS': serializer.toJson<double?>(
        learnedChannelOffsetS,
      ),
      'learnedPassCount': serializer.toJson<int?>(learnedPassCount),
      'temperatureLogJson': serializer.toJson<String?>(temperatureLogJson),
    };
  }

  SeriesRow copyWith({
    int? id,
    int? siteId,
    Value<int?> deviceId = const Value.absent(),
    Value<int?> calibrationId = const Value.absent(),
    double? temperatureC,
    double? speedOfSound,
    double? sourceHeightM,
    int? startedAtUtcMs,
    Value<int?> endedAtUtcMs = const Value.absent(),
    String? directory,
    bool? saveRawAudio,
    bool? simulated,
    String? configJson,
    Value<String?> segmentsJson = const Value.absent(),
    Value<double?> learnedMicSpacingM = const Value.absent(),
    Value<double?> learnedChannelOffsetS = const Value.absent(),
    Value<int?> learnedPassCount = const Value.absent(),
    Value<String?> temperatureLogJson = const Value.absent(),
  }) => SeriesRow(
    id: id ?? this.id,
    siteId: siteId ?? this.siteId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    calibrationId: calibrationId.present
        ? calibrationId.value
        : this.calibrationId,
    temperatureC: temperatureC ?? this.temperatureC,
    speedOfSound: speedOfSound ?? this.speedOfSound,
    sourceHeightM: sourceHeightM ?? this.sourceHeightM,
    startedAtUtcMs: startedAtUtcMs ?? this.startedAtUtcMs,
    endedAtUtcMs: endedAtUtcMs.present ? endedAtUtcMs.value : this.endedAtUtcMs,
    directory: directory ?? this.directory,
    saveRawAudio: saveRawAudio ?? this.saveRawAudio,
    simulated: simulated ?? this.simulated,
    configJson: configJson ?? this.configJson,
    segmentsJson: segmentsJson.present ? segmentsJson.value : this.segmentsJson,
    learnedMicSpacingM: learnedMicSpacingM.present
        ? learnedMicSpacingM.value
        : this.learnedMicSpacingM,
    learnedChannelOffsetS: learnedChannelOffsetS.present
        ? learnedChannelOffsetS.value
        : this.learnedChannelOffsetS,
    learnedPassCount: learnedPassCount.present
        ? learnedPassCount.value
        : this.learnedPassCount,
    temperatureLogJson: temperatureLogJson.present
        ? temperatureLogJson.value
        : this.temperatureLogJson,
  );
  SeriesRow copyWithCompanion(MeasurementSeriesCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      calibrationId: data.calibrationId.present
          ? data.calibrationId.value
          : this.calibrationId,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      speedOfSound: data.speedOfSound.present
          ? data.speedOfSound.value
          : this.speedOfSound,
      sourceHeightM: data.sourceHeightM.present
          ? data.sourceHeightM.value
          : this.sourceHeightM,
      startedAtUtcMs: data.startedAtUtcMs.present
          ? data.startedAtUtcMs.value
          : this.startedAtUtcMs,
      endedAtUtcMs: data.endedAtUtcMs.present
          ? data.endedAtUtcMs.value
          : this.endedAtUtcMs,
      directory: data.directory.present ? data.directory.value : this.directory,
      saveRawAudio: data.saveRawAudio.present
          ? data.saveRawAudio.value
          : this.saveRawAudio,
      simulated: data.simulated.present ? data.simulated.value : this.simulated,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      segmentsJson: data.segmentsJson.present
          ? data.segmentsJson.value
          : this.segmentsJson,
      learnedMicSpacingM: data.learnedMicSpacingM.present
          ? data.learnedMicSpacingM.value
          : this.learnedMicSpacingM,
      learnedChannelOffsetS: data.learnedChannelOffsetS.present
          ? data.learnedChannelOffsetS.value
          : this.learnedChannelOffsetS,
      learnedPassCount: data.learnedPassCount.present
          ? data.learnedPassCount.value
          : this.learnedPassCount,
      temperatureLogJson: data.temperatureLogJson.present
          ? data.temperatureLogJson.value
          : this.temperatureLogJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('siteId: $siteId, ')
          ..write('deviceId: $deviceId, ')
          ..write('calibrationId: $calibrationId, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('speedOfSound: $speedOfSound, ')
          ..write('sourceHeightM: $sourceHeightM, ')
          ..write('startedAtUtcMs: $startedAtUtcMs, ')
          ..write('endedAtUtcMs: $endedAtUtcMs, ')
          ..write('directory: $directory, ')
          ..write('saveRawAudio: $saveRawAudio, ')
          ..write('simulated: $simulated, ')
          ..write('configJson: $configJson, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('learnedMicSpacingM: $learnedMicSpacingM, ')
          ..write('learnedChannelOffsetS: $learnedChannelOffsetS, ')
          ..write('learnedPassCount: $learnedPassCount, ')
          ..write('temperatureLogJson: $temperatureLogJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    siteId,
    deviceId,
    calibrationId,
    temperatureC,
    speedOfSound,
    sourceHeightM,
    startedAtUtcMs,
    endedAtUtcMs,
    directory,
    saveRawAudio,
    simulated,
    configJson,
    segmentsJson,
    learnedMicSpacingM,
    learnedChannelOffsetS,
    learnedPassCount,
    temperatureLogJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.siteId == this.siteId &&
          other.deviceId == this.deviceId &&
          other.calibrationId == this.calibrationId &&
          other.temperatureC == this.temperatureC &&
          other.speedOfSound == this.speedOfSound &&
          other.sourceHeightM == this.sourceHeightM &&
          other.startedAtUtcMs == this.startedAtUtcMs &&
          other.endedAtUtcMs == this.endedAtUtcMs &&
          other.directory == this.directory &&
          other.saveRawAudio == this.saveRawAudio &&
          other.simulated == this.simulated &&
          other.configJson == this.configJson &&
          other.segmentsJson == this.segmentsJson &&
          other.learnedMicSpacingM == this.learnedMicSpacingM &&
          other.learnedChannelOffsetS == this.learnedChannelOffsetS &&
          other.learnedPassCount == this.learnedPassCount &&
          other.temperatureLogJson == this.temperatureLogJson);
}

class MeasurementSeriesCompanion extends UpdateCompanion<SeriesRow> {
  final Value<int> id;
  final Value<int> siteId;
  final Value<int?> deviceId;
  final Value<int?> calibrationId;
  final Value<double> temperatureC;
  final Value<double> speedOfSound;
  final Value<double> sourceHeightM;
  final Value<int> startedAtUtcMs;
  final Value<int?> endedAtUtcMs;
  final Value<String> directory;
  final Value<bool> saveRawAudio;
  final Value<bool> simulated;
  final Value<String> configJson;
  final Value<String?> segmentsJson;
  final Value<double?> learnedMicSpacingM;
  final Value<double?> learnedChannelOffsetS;
  final Value<int?> learnedPassCount;
  final Value<String?> temperatureLogJson;
  const MeasurementSeriesCompanion({
    this.id = const Value.absent(),
    this.siteId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.calibrationId = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.speedOfSound = const Value.absent(),
    this.sourceHeightM = const Value.absent(),
    this.startedAtUtcMs = const Value.absent(),
    this.endedAtUtcMs = const Value.absent(),
    this.directory = const Value.absent(),
    this.saveRawAudio = const Value.absent(),
    this.simulated = const Value.absent(),
    this.configJson = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    this.learnedMicSpacingM = const Value.absent(),
    this.learnedChannelOffsetS = const Value.absent(),
    this.learnedPassCount = const Value.absent(),
    this.temperatureLogJson = const Value.absent(),
  });
  MeasurementSeriesCompanion.insert({
    this.id = const Value.absent(),
    required int siteId,
    this.deviceId = const Value.absent(),
    this.calibrationId = const Value.absent(),
    required double temperatureC,
    required double speedOfSound,
    required double sourceHeightM,
    required int startedAtUtcMs,
    this.endedAtUtcMs = const Value.absent(),
    required String directory,
    this.saveRawAudio = const Value.absent(),
    this.simulated = const Value.absent(),
    required String configJson,
    this.segmentsJson = const Value.absent(),
    this.learnedMicSpacingM = const Value.absent(),
    this.learnedChannelOffsetS = const Value.absent(),
    this.learnedPassCount = const Value.absent(),
    this.temperatureLogJson = const Value.absent(),
  }) : siteId = Value(siteId),
       temperatureC = Value(temperatureC),
       speedOfSound = Value(speedOfSound),
       sourceHeightM = Value(sourceHeightM),
       startedAtUtcMs = Value(startedAtUtcMs),
       directory = Value(directory),
       configJson = Value(configJson);
  static Insertable<SeriesRow> custom({
    Expression<int>? id,
    Expression<int>? siteId,
    Expression<int>? deviceId,
    Expression<int>? calibrationId,
    Expression<double>? temperatureC,
    Expression<double>? speedOfSound,
    Expression<double>? sourceHeightM,
    Expression<int>? startedAtUtcMs,
    Expression<int>? endedAtUtcMs,
    Expression<String>? directory,
    Expression<bool>? saveRawAudio,
    Expression<bool>? simulated,
    Expression<String>? configJson,
    Expression<String>? segmentsJson,
    Expression<double>? learnedMicSpacingM,
    Expression<double>? learnedChannelOffsetS,
    Expression<int>? learnedPassCount,
    Expression<String>? temperatureLogJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (siteId != null) 'site_id': siteId,
      if (deviceId != null) 'device_id': deviceId,
      if (calibrationId != null) 'calibration_id': calibrationId,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (speedOfSound != null) 'speed_of_sound': speedOfSound,
      if (sourceHeightM != null) 'source_height_m': sourceHeightM,
      if (startedAtUtcMs != null) 'started_at_utc_ms': startedAtUtcMs,
      if (endedAtUtcMs != null) 'ended_at_utc_ms': endedAtUtcMs,
      if (directory != null) 'directory': directory,
      if (saveRawAudio != null) 'save_raw_audio': saveRawAudio,
      if (simulated != null) 'simulated': simulated,
      if (configJson != null) 'config_json': configJson,
      if (segmentsJson != null) 'segments_json': segmentsJson,
      if (learnedMicSpacingM != null)
        'learned_mic_spacing_m': learnedMicSpacingM,
      if (learnedChannelOffsetS != null)
        'learned_channel_offset_s': learnedChannelOffsetS,
      if (learnedPassCount != null) 'learned_pass_count': learnedPassCount,
      if (temperatureLogJson != null)
        'temperature_log_json': temperatureLogJson,
    });
  }

  MeasurementSeriesCompanion copyWith({
    Value<int>? id,
    Value<int>? siteId,
    Value<int?>? deviceId,
    Value<int?>? calibrationId,
    Value<double>? temperatureC,
    Value<double>? speedOfSound,
    Value<double>? sourceHeightM,
    Value<int>? startedAtUtcMs,
    Value<int?>? endedAtUtcMs,
    Value<String>? directory,
    Value<bool>? saveRawAudio,
    Value<bool>? simulated,
    Value<String>? configJson,
    Value<String?>? segmentsJson,
    Value<double?>? learnedMicSpacingM,
    Value<double?>? learnedChannelOffsetS,
    Value<int?>? learnedPassCount,
    Value<String?>? temperatureLogJson,
  }) {
    return MeasurementSeriesCompanion(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      deviceId: deviceId ?? this.deviceId,
      calibrationId: calibrationId ?? this.calibrationId,
      temperatureC: temperatureC ?? this.temperatureC,
      speedOfSound: speedOfSound ?? this.speedOfSound,
      sourceHeightM: sourceHeightM ?? this.sourceHeightM,
      startedAtUtcMs: startedAtUtcMs ?? this.startedAtUtcMs,
      endedAtUtcMs: endedAtUtcMs ?? this.endedAtUtcMs,
      directory: directory ?? this.directory,
      saveRawAudio: saveRawAudio ?? this.saveRawAudio,
      simulated: simulated ?? this.simulated,
      configJson: configJson ?? this.configJson,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      learnedMicSpacingM: learnedMicSpacingM ?? this.learnedMicSpacingM,
      learnedChannelOffsetS:
          learnedChannelOffsetS ?? this.learnedChannelOffsetS,
      learnedPassCount: learnedPassCount ?? this.learnedPassCount,
      temperatureLogJson: temperatureLogJson ?? this.temperatureLogJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (calibrationId.present) {
      map['calibration_id'] = Variable<int>(calibrationId.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (speedOfSound.present) {
      map['speed_of_sound'] = Variable<double>(speedOfSound.value);
    }
    if (sourceHeightM.present) {
      map['source_height_m'] = Variable<double>(sourceHeightM.value);
    }
    if (startedAtUtcMs.present) {
      map['started_at_utc_ms'] = Variable<int>(startedAtUtcMs.value);
    }
    if (endedAtUtcMs.present) {
      map['ended_at_utc_ms'] = Variable<int>(endedAtUtcMs.value);
    }
    if (directory.present) {
      map['directory'] = Variable<String>(directory.value);
    }
    if (saveRawAudio.present) {
      map['save_raw_audio'] = Variable<bool>(saveRawAudio.value);
    }
    if (simulated.present) {
      map['simulated'] = Variable<bool>(simulated.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (segmentsJson.present) {
      map['segments_json'] = Variable<String>(segmentsJson.value);
    }
    if (learnedMicSpacingM.present) {
      map['learned_mic_spacing_m'] = Variable<double>(learnedMicSpacingM.value);
    }
    if (learnedChannelOffsetS.present) {
      map['learned_channel_offset_s'] = Variable<double>(
        learnedChannelOffsetS.value,
      );
    }
    if (learnedPassCount.present) {
      map['learned_pass_count'] = Variable<int>(learnedPassCount.value);
    }
    if (temperatureLogJson.present) {
      map['temperature_log_json'] = Variable<String>(temperatureLogJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementSeriesCompanion(')
          ..write('id: $id, ')
          ..write('siteId: $siteId, ')
          ..write('deviceId: $deviceId, ')
          ..write('calibrationId: $calibrationId, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('speedOfSound: $speedOfSound, ')
          ..write('sourceHeightM: $sourceHeightM, ')
          ..write('startedAtUtcMs: $startedAtUtcMs, ')
          ..write('endedAtUtcMs: $endedAtUtcMs, ')
          ..write('directory: $directory, ')
          ..write('saveRawAudio: $saveRawAudio, ')
          ..write('simulated: $simulated, ')
          ..write('configJson: $configJson, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('learnedMicSpacingM: $learnedMicSpacingM, ')
          ..write('learnedChannelOffsetS: $learnedChannelOffsetS, ')
          ..write('learnedPassCount: $learnedPassCount, ')
          ..write('temperatureLogJson: $temperatureLogJson')
          ..write(')'))
        .toString();
  }
}

class $PassesTable extends Passes with TableInfo<$PassesTable, PassRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES measurement_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _zeitMeta = const VerificationMeta('zeit');
  @override
  late final GeneratedColumn<int> zeit = GeneratedColumn<int>(
    'zeit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetSMeta = const VerificationMeta(
    'offsetS',
  );
  @override
  late final GeneratedColumn<double> offsetS = GeneratedColumn<double>(
    'offset_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _richtungMeta = const VerificationMeta(
    'richtung',
  );
  @override
  late final GeneratedColumn<int> richtung = GeneratedColumn<int>(
    'richtung',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _klasseMeta = const VerificationMeta('klasse');
  @override
  late final GeneratedColumn<String> klasse = GeneratedColumn<String>(
    'klasse',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vMeta = const VerificationMeta('v');
  @override
  late final GeneratedColumn<double> v = GeneratedColumn<double>(
    'v',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sigmaVMeta = const VerificationMeta('sigmaV');
  @override
  late final GeneratedColumn<double> sigmaV = GeneratedColumn<double>(
    'sigma_v',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vLaufzeitMeta = const VerificationMeta(
    'vLaufzeit',
  );
  @override
  late final GeneratedColumn<double> vLaufzeit = GeneratedColumn<double>(
    'v_laufzeit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vDopplerMeta = const VerificationMeta(
    'vDoppler',
  );
  @override
  late final GeneratedColumn<double> vDoppler = GeneratedColumn<double>(
    'v_doppler',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kappaMeta = const VerificationMeta('kappa');
  @override
  late final GeneratedColumn<double> kappa = GeneratedColumn<double>(
    'kappa',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dEstMeta = const VerificationMeta('dEst');
  @override
  late final GeneratedColumn<double> dEst = GeneratedColumn<double>(
    'd_est',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nToeneMeta = const VerificationMeta('nToene');
  @override
  late final GeneratedColumn<int> nToene = GeneratedColumn<int>(
    'n_toene',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restLaufzeitMeta = const VerificationMeta(
    'restLaufzeit',
  );
  @override
  late final GeneratedColumn<double> restLaufzeit = GeneratedColumn<double>(
    'rest_laufzeit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pegelMeta = const VerificationMeta('pegel');
  @override
  late final GeneratedColumn<double> pegel = GeneratedColumn<double>(
    'pegel',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dauerMeta = const VerificationMeta('dauer');
  @override
  late final GeneratedColumn<double> dauer = GeneratedColumn<double>(
    'dauer',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grundMeta = const VerificationMeta('grund');
  @override
  late final GeneratedColumn<String> grund = GeneratedColumn<String>(
    'grund',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grundCodeMeta = const VerificationMeta(
    'grundCode',
  );
  @override
  late final GeneratedColumn<String> grundCode = GeneratedColumn<String>(
    'grund_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _laneIndexMeta = const VerificationMeta(
    'laneIndex',
  );
  @override
  late final GeneratedColumn<int> laneIndex = GeneratedColumn<int>(
    'lane_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceUsedMMeta = const VerificationMeta(
    'distanceUsedM',
  );
  @override
  late final GeneratedColumn<double> distanceUsedM = GeneratedColumn<double>(
    'distance_used_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sigmaLaufzeitMeta = const VerificationMeta(
    'sigmaLaufzeit',
  );
  @override
  late final GeneratedColumn<double> sigmaLaufzeit = GeneratedColumn<double>(
    'sigma_laufzeit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sigmaDopplerMeta = const VerificationMeta(
    'sigmaDoppler',
  );
  @override
  late final GeneratedColumn<double> sigmaDoppler = GeneratedColumn<double>(
    'sigma_doppler',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    zeit,
    offsetS,
    richtung,
    klasse,
    v,
    sigmaV,
    vLaufzeit,
    vDoppler,
    kappa,
    dEst,
    nToene,
    restLaufzeit,
    pegel,
    dauer,
    grund,
    grundCode,
    laneIndex,
    distanceUsedM,
    sigmaLaufzeit,
    sigmaDoppler,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'passes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PassRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('zeit')) {
      context.handle(
        _zeitMeta,
        zeit.isAcceptableOrUnknown(data['zeit']!, _zeitMeta),
      );
    } else if (isInserting) {
      context.missing(_zeitMeta);
    }
    if (data.containsKey('offset_s')) {
      context.handle(
        _offsetSMeta,
        offsetS.isAcceptableOrUnknown(data['offset_s']!, _offsetSMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetSMeta);
    }
    if (data.containsKey('richtung')) {
      context.handle(
        _richtungMeta,
        richtung.isAcceptableOrUnknown(data['richtung']!, _richtungMeta),
      );
    } else if (isInserting) {
      context.missing(_richtungMeta);
    }
    if (data.containsKey('klasse')) {
      context.handle(
        _klasseMeta,
        klasse.isAcceptableOrUnknown(data['klasse']!, _klasseMeta),
      );
    } else if (isInserting) {
      context.missing(_klasseMeta);
    }
    if (data.containsKey('v')) {
      context.handle(_vMeta, v.isAcceptableOrUnknown(data['v']!, _vMeta));
    }
    if (data.containsKey('sigma_v')) {
      context.handle(
        _sigmaVMeta,
        sigmaV.isAcceptableOrUnknown(data['sigma_v']!, _sigmaVMeta),
      );
    }
    if (data.containsKey('v_laufzeit')) {
      context.handle(
        _vLaufzeitMeta,
        vLaufzeit.isAcceptableOrUnknown(data['v_laufzeit']!, _vLaufzeitMeta),
      );
    }
    if (data.containsKey('v_doppler')) {
      context.handle(
        _vDopplerMeta,
        vDoppler.isAcceptableOrUnknown(data['v_doppler']!, _vDopplerMeta),
      );
    }
    if (data.containsKey('kappa')) {
      context.handle(
        _kappaMeta,
        kappa.isAcceptableOrUnknown(data['kappa']!, _kappaMeta),
      );
    }
    if (data.containsKey('d_est')) {
      context.handle(
        _dEstMeta,
        dEst.isAcceptableOrUnknown(data['d_est']!, _dEstMeta),
      );
    }
    if (data.containsKey('n_toene')) {
      context.handle(
        _nToeneMeta,
        nToene.isAcceptableOrUnknown(data['n_toene']!, _nToeneMeta),
      );
    } else if (isInserting) {
      context.missing(_nToeneMeta);
    }
    if (data.containsKey('rest_laufzeit')) {
      context.handle(
        _restLaufzeitMeta,
        restLaufzeit.isAcceptableOrUnknown(
          data['rest_laufzeit']!,
          _restLaufzeitMeta,
        ),
      );
    }
    if (data.containsKey('pegel')) {
      context.handle(
        _pegelMeta,
        pegel.isAcceptableOrUnknown(data['pegel']!, _pegelMeta),
      );
    } else if (isInserting) {
      context.missing(_pegelMeta);
    }
    if (data.containsKey('dauer')) {
      context.handle(
        _dauerMeta,
        dauer.isAcceptableOrUnknown(data['dauer']!, _dauerMeta),
      );
    } else if (isInserting) {
      context.missing(_dauerMeta);
    }
    if (data.containsKey('grund')) {
      context.handle(
        _grundMeta,
        grund.isAcceptableOrUnknown(data['grund']!, _grundMeta),
      );
    }
    if (data.containsKey('grund_code')) {
      context.handle(
        _grundCodeMeta,
        grundCode.isAcceptableOrUnknown(data['grund_code']!, _grundCodeMeta),
      );
    }
    if (data.containsKey('lane_index')) {
      context.handle(
        _laneIndexMeta,
        laneIndex.isAcceptableOrUnknown(data['lane_index']!, _laneIndexMeta),
      );
    }
    if (data.containsKey('distance_used_m')) {
      context.handle(
        _distanceUsedMMeta,
        distanceUsedM.isAcceptableOrUnknown(
          data['distance_used_m']!,
          _distanceUsedMMeta,
        ),
      );
    }
    if (data.containsKey('sigma_laufzeit')) {
      context.handle(
        _sigmaLaufzeitMeta,
        sigmaLaufzeit.isAcceptableOrUnknown(
          data['sigma_laufzeit']!,
          _sigmaLaufzeitMeta,
        ),
      );
    }
    if (data.containsKey('sigma_doppler')) {
      context.handle(
        _sigmaDopplerMeta,
        sigmaDoppler.isAcceptableOrUnknown(
          data['sigma_doppler']!,
          _sigmaDopplerMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PassRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PassRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      zeit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zeit'],
      )!,
      offsetS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}offset_s'],
      )!,
      richtung: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}richtung'],
      )!,
      klasse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}klasse'],
      )!,
      v: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}v'],
      ),
      sigmaV: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sigma_v'],
      ),
      vLaufzeit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}v_laufzeit'],
      ),
      vDoppler: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}v_doppler'],
      ),
      kappa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kappa'],
      ),
      dEst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}d_est'],
      ),
      nToene: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}n_toene'],
      )!,
      restLaufzeit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rest_laufzeit'],
      ),
      pegel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pegel'],
      )!,
      dauer: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dauer'],
      )!,
      grund: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grund'],
      ),
      grundCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grund_code'],
      ),
      laneIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane_index'],
      ),
      distanceUsedM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_used_m'],
      ),
      sigmaLaufzeit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sigma_laufzeit'],
      ),
      sigmaDoppler: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sigma_doppler'],
      ),
    );
  }

  @override
  $PassesTable createAlias(String alias) {
    return $PassesTable(attachedDatabase, alias);
  }
}

class PassRow extends DataClass implements Insertable<PassRow> {
  final int id;
  final int seriesId;

  /// Time of closest approach (UTC, ms).
  final int zeit;

  /// Time of closest approach relative to the recording start in s.
  final double offsetS;
  final int richtung;
  final String klasse;
  final double? v;
  final double? sigmaV;
  final double? vLaufzeit;
  final double? vDoppler;
  final double? kappa;
  final double? dEst;
  final int nToene;
  final double? restLaufzeit;
  final double pegel;
  final double dauer;
  final String? grund;

  /// Machine-readable reason code (docs/conventions.md).
  final String? grundCode;
  final int? laneIndex;
  final double? distanceUsedM;

  /// Uncertainties of the single estimates in km/h (schema 2).
  final double? sigmaLaufzeit;
  final double? sigmaDoppler;
  const PassRow({
    required this.id,
    required this.seriesId,
    required this.zeit,
    required this.offsetS,
    required this.richtung,
    required this.klasse,
    this.v,
    this.sigmaV,
    this.vLaufzeit,
    this.vDoppler,
    this.kappa,
    this.dEst,
    required this.nToene,
    this.restLaufzeit,
    required this.pegel,
    required this.dauer,
    this.grund,
    this.grundCode,
    this.laneIndex,
    this.distanceUsedM,
    this.sigmaLaufzeit,
    this.sigmaDoppler,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_id'] = Variable<int>(seriesId);
    map['zeit'] = Variable<int>(zeit);
    map['offset_s'] = Variable<double>(offsetS);
    map['richtung'] = Variable<int>(richtung);
    map['klasse'] = Variable<String>(klasse);
    if (!nullToAbsent || v != null) {
      map['v'] = Variable<double>(v);
    }
    if (!nullToAbsent || sigmaV != null) {
      map['sigma_v'] = Variable<double>(sigmaV);
    }
    if (!nullToAbsent || vLaufzeit != null) {
      map['v_laufzeit'] = Variable<double>(vLaufzeit);
    }
    if (!nullToAbsent || vDoppler != null) {
      map['v_doppler'] = Variable<double>(vDoppler);
    }
    if (!nullToAbsent || kappa != null) {
      map['kappa'] = Variable<double>(kappa);
    }
    if (!nullToAbsent || dEst != null) {
      map['d_est'] = Variable<double>(dEst);
    }
    map['n_toene'] = Variable<int>(nToene);
    if (!nullToAbsent || restLaufzeit != null) {
      map['rest_laufzeit'] = Variable<double>(restLaufzeit);
    }
    map['pegel'] = Variable<double>(pegel);
    map['dauer'] = Variable<double>(dauer);
    if (!nullToAbsent || grund != null) {
      map['grund'] = Variable<String>(grund);
    }
    if (!nullToAbsent || grundCode != null) {
      map['grund_code'] = Variable<String>(grundCode);
    }
    if (!nullToAbsent || laneIndex != null) {
      map['lane_index'] = Variable<int>(laneIndex);
    }
    if (!nullToAbsent || distanceUsedM != null) {
      map['distance_used_m'] = Variable<double>(distanceUsedM);
    }
    if (!nullToAbsent || sigmaLaufzeit != null) {
      map['sigma_laufzeit'] = Variable<double>(sigmaLaufzeit);
    }
    if (!nullToAbsent || sigmaDoppler != null) {
      map['sigma_doppler'] = Variable<double>(sigmaDoppler);
    }
    return map;
  }

  PassesCompanion toCompanion(bool nullToAbsent) {
    return PassesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      zeit: Value(zeit),
      offsetS: Value(offsetS),
      richtung: Value(richtung),
      klasse: Value(klasse),
      v: v == null && nullToAbsent ? const Value.absent() : Value(v),
      sigmaV: sigmaV == null && nullToAbsent
          ? const Value.absent()
          : Value(sigmaV),
      vLaufzeit: vLaufzeit == null && nullToAbsent
          ? const Value.absent()
          : Value(vLaufzeit),
      vDoppler: vDoppler == null && nullToAbsent
          ? const Value.absent()
          : Value(vDoppler),
      kappa: kappa == null && nullToAbsent
          ? const Value.absent()
          : Value(kappa),
      dEst: dEst == null && nullToAbsent ? const Value.absent() : Value(dEst),
      nToene: Value(nToene),
      restLaufzeit: restLaufzeit == null && nullToAbsent
          ? const Value.absent()
          : Value(restLaufzeit),
      pegel: Value(pegel),
      dauer: Value(dauer),
      grund: grund == null && nullToAbsent
          ? const Value.absent()
          : Value(grund),
      grundCode: grundCode == null && nullToAbsent
          ? const Value.absent()
          : Value(grundCode),
      laneIndex: laneIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(laneIndex),
      distanceUsedM: distanceUsedM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceUsedM),
      sigmaLaufzeit: sigmaLaufzeit == null && nullToAbsent
          ? const Value.absent()
          : Value(sigmaLaufzeit),
      sigmaDoppler: sigmaDoppler == null && nullToAbsent
          ? const Value.absent()
          : Value(sigmaDoppler),
    );
  }

  factory PassRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PassRow(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      zeit: serializer.fromJson<int>(json['zeit']),
      offsetS: serializer.fromJson<double>(json['offsetS']),
      richtung: serializer.fromJson<int>(json['richtung']),
      klasse: serializer.fromJson<String>(json['klasse']),
      v: serializer.fromJson<double?>(json['v']),
      sigmaV: serializer.fromJson<double?>(json['sigmaV']),
      vLaufzeit: serializer.fromJson<double?>(json['vLaufzeit']),
      vDoppler: serializer.fromJson<double?>(json['vDoppler']),
      kappa: serializer.fromJson<double?>(json['kappa']),
      dEst: serializer.fromJson<double?>(json['dEst']),
      nToene: serializer.fromJson<int>(json['nToene']),
      restLaufzeit: serializer.fromJson<double?>(json['restLaufzeit']),
      pegel: serializer.fromJson<double>(json['pegel']),
      dauer: serializer.fromJson<double>(json['dauer']),
      grund: serializer.fromJson<String?>(json['grund']),
      grundCode: serializer.fromJson<String?>(json['grundCode']),
      laneIndex: serializer.fromJson<int?>(json['laneIndex']),
      distanceUsedM: serializer.fromJson<double?>(json['distanceUsedM']),
      sigmaLaufzeit: serializer.fromJson<double?>(json['sigmaLaufzeit']),
      sigmaDoppler: serializer.fromJson<double?>(json['sigmaDoppler']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int>(seriesId),
      'zeit': serializer.toJson<int>(zeit),
      'offsetS': serializer.toJson<double>(offsetS),
      'richtung': serializer.toJson<int>(richtung),
      'klasse': serializer.toJson<String>(klasse),
      'v': serializer.toJson<double?>(v),
      'sigmaV': serializer.toJson<double?>(sigmaV),
      'vLaufzeit': serializer.toJson<double?>(vLaufzeit),
      'vDoppler': serializer.toJson<double?>(vDoppler),
      'kappa': serializer.toJson<double?>(kappa),
      'dEst': serializer.toJson<double?>(dEst),
      'nToene': serializer.toJson<int>(nToene),
      'restLaufzeit': serializer.toJson<double?>(restLaufzeit),
      'pegel': serializer.toJson<double>(pegel),
      'dauer': serializer.toJson<double>(dauer),
      'grund': serializer.toJson<String?>(grund),
      'grundCode': serializer.toJson<String?>(grundCode),
      'laneIndex': serializer.toJson<int?>(laneIndex),
      'distanceUsedM': serializer.toJson<double?>(distanceUsedM),
      'sigmaLaufzeit': serializer.toJson<double?>(sigmaLaufzeit),
      'sigmaDoppler': serializer.toJson<double?>(sigmaDoppler),
    };
  }

  PassRow copyWith({
    int? id,
    int? seriesId,
    int? zeit,
    double? offsetS,
    int? richtung,
    String? klasse,
    Value<double?> v = const Value.absent(),
    Value<double?> sigmaV = const Value.absent(),
    Value<double?> vLaufzeit = const Value.absent(),
    Value<double?> vDoppler = const Value.absent(),
    Value<double?> kappa = const Value.absent(),
    Value<double?> dEst = const Value.absent(),
    int? nToene,
    Value<double?> restLaufzeit = const Value.absent(),
    double? pegel,
    double? dauer,
    Value<String?> grund = const Value.absent(),
    Value<String?> grundCode = const Value.absent(),
    Value<int?> laneIndex = const Value.absent(),
    Value<double?> distanceUsedM = const Value.absent(),
    Value<double?> sigmaLaufzeit = const Value.absent(),
    Value<double?> sigmaDoppler = const Value.absent(),
  }) => PassRow(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    zeit: zeit ?? this.zeit,
    offsetS: offsetS ?? this.offsetS,
    richtung: richtung ?? this.richtung,
    klasse: klasse ?? this.klasse,
    v: v.present ? v.value : this.v,
    sigmaV: sigmaV.present ? sigmaV.value : this.sigmaV,
    vLaufzeit: vLaufzeit.present ? vLaufzeit.value : this.vLaufzeit,
    vDoppler: vDoppler.present ? vDoppler.value : this.vDoppler,
    kappa: kappa.present ? kappa.value : this.kappa,
    dEst: dEst.present ? dEst.value : this.dEst,
    nToene: nToene ?? this.nToene,
    restLaufzeit: restLaufzeit.present ? restLaufzeit.value : this.restLaufzeit,
    pegel: pegel ?? this.pegel,
    dauer: dauer ?? this.dauer,
    grund: grund.present ? grund.value : this.grund,
    grundCode: grundCode.present ? grundCode.value : this.grundCode,
    laneIndex: laneIndex.present ? laneIndex.value : this.laneIndex,
    distanceUsedM: distanceUsedM.present
        ? distanceUsedM.value
        : this.distanceUsedM,
    sigmaLaufzeit: sigmaLaufzeit.present
        ? sigmaLaufzeit.value
        : this.sigmaLaufzeit,
    sigmaDoppler: sigmaDoppler.present ? sigmaDoppler.value : this.sigmaDoppler,
  );
  PassRow copyWithCompanion(PassesCompanion data) {
    return PassRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      zeit: data.zeit.present ? data.zeit.value : this.zeit,
      offsetS: data.offsetS.present ? data.offsetS.value : this.offsetS,
      richtung: data.richtung.present ? data.richtung.value : this.richtung,
      klasse: data.klasse.present ? data.klasse.value : this.klasse,
      v: data.v.present ? data.v.value : this.v,
      sigmaV: data.sigmaV.present ? data.sigmaV.value : this.sigmaV,
      vLaufzeit: data.vLaufzeit.present ? data.vLaufzeit.value : this.vLaufzeit,
      vDoppler: data.vDoppler.present ? data.vDoppler.value : this.vDoppler,
      kappa: data.kappa.present ? data.kappa.value : this.kappa,
      dEst: data.dEst.present ? data.dEst.value : this.dEst,
      nToene: data.nToene.present ? data.nToene.value : this.nToene,
      restLaufzeit: data.restLaufzeit.present
          ? data.restLaufzeit.value
          : this.restLaufzeit,
      pegel: data.pegel.present ? data.pegel.value : this.pegel,
      dauer: data.dauer.present ? data.dauer.value : this.dauer,
      grund: data.grund.present ? data.grund.value : this.grund,
      grundCode: data.grundCode.present ? data.grundCode.value : this.grundCode,
      laneIndex: data.laneIndex.present ? data.laneIndex.value : this.laneIndex,
      distanceUsedM: data.distanceUsedM.present
          ? data.distanceUsedM.value
          : this.distanceUsedM,
      sigmaLaufzeit: data.sigmaLaufzeit.present
          ? data.sigmaLaufzeit.value
          : this.sigmaLaufzeit,
      sigmaDoppler: data.sigmaDoppler.present
          ? data.sigmaDoppler.value
          : this.sigmaDoppler,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PassRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('zeit: $zeit, ')
          ..write('offsetS: $offsetS, ')
          ..write('richtung: $richtung, ')
          ..write('klasse: $klasse, ')
          ..write('v: $v, ')
          ..write('sigmaV: $sigmaV, ')
          ..write('vLaufzeit: $vLaufzeit, ')
          ..write('vDoppler: $vDoppler, ')
          ..write('kappa: $kappa, ')
          ..write('dEst: $dEst, ')
          ..write('nToene: $nToene, ')
          ..write('restLaufzeit: $restLaufzeit, ')
          ..write('pegel: $pegel, ')
          ..write('dauer: $dauer, ')
          ..write('grund: $grund, ')
          ..write('grundCode: $grundCode, ')
          ..write('laneIndex: $laneIndex, ')
          ..write('distanceUsedM: $distanceUsedM, ')
          ..write('sigmaLaufzeit: $sigmaLaufzeit, ')
          ..write('sigmaDoppler: $sigmaDoppler')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    seriesId,
    zeit,
    offsetS,
    richtung,
    klasse,
    v,
    sigmaV,
    vLaufzeit,
    vDoppler,
    kappa,
    dEst,
    nToene,
    restLaufzeit,
    pegel,
    dauer,
    grund,
    grundCode,
    laneIndex,
    distanceUsedM,
    sigmaLaufzeit,
    sigmaDoppler,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.zeit == this.zeit &&
          other.offsetS == this.offsetS &&
          other.richtung == this.richtung &&
          other.klasse == this.klasse &&
          other.v == this.v &&
          other.sigmaV == this.sigmaV &&
          other.vLaufzeit == this.vLaufzeit &&
          other.vDoppler == this.vDoppler &&
          other.kappa == this.kappa &&
          other.dEst == this.dEst &&
          other.nToene == this.nToene &&
          other.restLaufzeit == this.restLaufzeit &&
          other.pegel == this.pegel &&
          other.dauer == this.dauer &&
          other.grund == this.grund &&
          other.grundCode == this.grundCode &&
          other.laneIndex == this.laneIndex &&
          other.distanceUsedM == this.distanceUsedM &&
          other.sigmaLaufzeit == this.sigmaLaufzeit &&
          other.sigmaDoppler == this.sigmaDoppler);
}

class PassesCompanion extends UpdateCompanion<PassRow> {
  final Value<int> id;
  final Value<int> seriesId;
  final Value<int> zeit;
  final Value<double> offsetS;
  final Value<int> richtung;
  final Value<String> klasse;
  final Value<double?> v;
  final Value<double?> sigmaV;
  final Value<double?> vLaufzeit;
  final Value<double?> vDoppler;
  final Value<double?> kappa;
  final Value<double?> dEst;
  final Value<int> nToene;
  final Value<double?> restLaufzeit;
  final Value<double> pegel;
  final Value<double> dauer;
  final Value<String?> grund;
  final Value<String?> grundCode;
  final Value<int?> laneIndex;
  final Value<double?> distanceUsedM;
  final Value<double?> sigmaLaufzeit;
  final Value<double?> sigmaDoppler;
  const PassesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.zeit = const Value.absent(),
    this.offsetS = const Value.absent(),
    this.richtung = const Value.absent(),
    this.klasse = const Value.absent(),
    this.v = const Value.absent(),
    this.sigmaV = const Value.absent(),
    this.vLaufzeit = const Value.absent(),
    this.vDoppler = const Value.absent(),
    this.kappa = const Value.absent(),
    this.dEst = const Value.absent(),
    this.nToene = const Value.absent(),
    this.restLaufzeit = const Value.absent(),
    this.pegel = const Value.absent(),
    this.dauer = const Value.absent(),
    this.grund = const Value.absent(),
    this.grundCode = const Value.absent(),
    this.laneIndex = const Value.absent(),
    this.distanceUsedM = const Value.absent(),
    this.sigmaLaufzeit = const Value.absent(),
    this.sigmaDoppler = const Value.absent(),
  });
  PassesCompanion.insert({
    this.id = const Value.absent(),
    required int seriesId,
    required int zeit,
    required double offsetS,
    required int richtung,
    required String klasse,
    this.v = const Value.absent(),
    this.sigmaV = const Value.absent(),
    this.vLaufzeit = const Value.absent(),
    this.vDoppler = const Value.absent(),
    this.kappa = const Value.absent(),
    this.dEst = const Value.absent(),
    required int nToene,
    this.restLaufzeit = const Value.absent(),
    required double pegel,
    required double dauer,
    this.grund = const Value.absent(),
    this.grundCode = const Value.absent(),
    this.laneIndex = const Value.absent(),
    this.distanceUsedM = const Value.absent(),
    this.sigmaLaufzeit = const Value.absent(),
    this.sigmaDoppler = const Value.absent(),
  }) : seriesId = Value(seriesId),
       zeit = Value(zeit),
       offsetS = Value(offsetS),
       richtung = Value(richtung),
       klasse = Value(klasse),
       nToene = Value(nToene),
       pegel = Value(pegel),
       dauer = Value(dauer);
  static Insertable<PassRow> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<int>? zeit,
    Expression<double>? offsetS,
    Expression<int>? richtung,
    Expression<String>? klasse,
    Expression<double>? v,
    Expression<double>? sigmaV,
    Expression<double>? vLaufzeit,
    Expression<double>? vDoppler,
    Expression<double>? kappa,
    Expression<double>? dEst,
    Expression<int>? nToene,
    Expression<double>? restLaufzeit,
    Expression<double>? pegel,
    Expression<double>? dauer,
    Expression<String>? grund,
    Expression<String>? grundCode,
    Expression<int>? laneIndex,
    Expression<double>? distanceUsedM,
    Expression<double>? sigmaLaufzeit,
    Expression<double>? sigmaDoppler,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (zeit != null) 'zeit': zeit,
      if (offsetS != null) 'offset_s': offsetS,
      if (richtung != null) 'richtung': richtung,
      if (klasse != null) 'klasse': klasse,
      if (v != null) 'v': v,
      if (sigmaV != null) 'sigma_v': sigmaV,
      if (vLaufzeit != null) 'v_laufzeit': vLaufzeit,
      if (vDoppler != null) 'v_doppler': vDoppler,
      if (kappa != null) 'kappa': kappa,
      if (dEst != null) 'd_est': dEst,
      if (nToene != null) 'n_toene': nToene,
      if (restLaufzeit != null) 'rest_laufzeit': restLaufzeit,
      if (pegel != null) 'pegel': pegel,
      if (dauer != null) 'dauer': dauer,
      if (grund != null) 'grund': grund,
      if (grundCode != null) 'grund_code': grundCode,
      if (laneIndex != null) 'lane_index': laneIndex,
      if (distanceUsedM != null) 'distance_used_m': distanceUsedM,
      if (sigmaLaufzeit != null) 'sigma_laufzeit': sigmaLaufzeit,
      if (sigmaDoppler != null) 'sigma_doppler': sigmaDoppler,
    });
  }

  PassesCompanion copyWith({
    Value<int>? id,
    Value<int>? seriesId,
    Value<int>? zeit,
    Value<double>? offsetS,
    Value<int>? richtung,
    Value<String>? klasse,
    Value<double?>? v,
    Value<double?>? sigmaV,
    Value<double?>? vLaufzeit,
    Value<double?>? vDoppler,
    Value<double?>? kappa,
    Value<double?>? dEst,
    Value<int>? nToene,
    Value<double?>? restLaufzeit,
    Value<double>? pegel,
    Value<double>? dauer,
    Value<String?>? grund,
    Value<String?>? grundCode,
    Value<int?>? laneIndex,
    Value<double?>? distanceUsedM,
    Value<double?>? sigmaLaufzeit,
    Value<double?>? sigmaDoppler,
  }) {
    return PassesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      zeit: zeit ?? this.zeit,
      offsetS: offsetS ?? this.offsetS,
      richtung: richtung ?? this.richtung,
      klasse: klasse ?? this.klasse,
      v: v ?? this.v,
      sigmaV: sigmaV ?? this.sigmaV,
      vLaufzeit: vLaufzeit ?? this.vLaufzeit,
      vDoppler: vDoppler ?? this.vDoppler,
      kappa: kappa ?? this.kappa,
      dEst: dEst ?? this.dEst,
      nToene: nToene ?? this.nToene,
      restLaufzeit: restLaufzeit ?? this.restLaufzeit,
      pegel: pegel ?? this.pegel,
      dauer: dauer ?? this.dauer,
      grund: grund ?? this.grund,
      grundCode: grundCode ?? this.grundCode,
      laneIndex: laneIndex ?? this.laneIndex,
      distanceUsedM: distanceUsedM ?? this.distanceUsedM,
      sigmaLaufzeit: sigmaLaufzeit ?? this.sigmaLaufzeit,
      sigmaDoppler: sigmaDoppler ?? this.sigmaDoppler,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (zeit.present) {
      map['zeit'] = Variable<int>(zeit.value);
    }
    if (offsetS.present) {
      map['offset_s'] = Variable<double>(offsetS.value);
    }
    if (richtung.present) {
      map['richtung'] = Variable<int>(richtung.value);
    }
    if (klasse.present) {
      map['klasse'] = Variable<String>(klasse.value);
    }
    if (v.present) {
      map['v'] = Variable<double>(v.value);
    }
    if (sigmaV.present) {
      map['sigma_v'] = Variable<double>(sigmaV.value);
    }
    if (vLaufzeit.present) {
      map['v_laufzeit'] = Variable<double>(vLaufzeit.value);
    }
    if (vDoppler.present) {
      map['v_doppler'] = Variable<double>(vDoppler.value);
    }
    if (kappa.present) {
      map['kappa'] = Variable<double>(kappa.value);
    }
    if (dEst.present) {
      map['d_est'] = Variable<double>(dEst.value);
    }
    if (nToene.present) {
      map['n_toene'] = Variable<int>(nToene.value);
    }
    if (restLaufzeit.present) {
      map['rest_laufzeit'] = Variable<double>(restLaufzeit.value);
    }
    if (pegel.present) {
      map['pegel'] = Variable<double>(pegel.value);
    }
    if (dauer.present) {
      map['dauer'] = Variable<double>(dauer.value);
    }
    if (grund.present) {
      map['grund'] = Variable<String>(grund.value);
    }
    if (grundCode.present) {
      map['grund_code'] = Variable<String>(grundCode.value);
    }
    if (laneIndex.present) {
      map['lane_index'] = Variable<int>(laneIndex.value);
    }
    if (distanceUsedM.present) {
      map['distance_used_m'] = Variable<double>(distanceUsedM.value);
    }
    if (sigmaLaufzeit.present) {
      map['sigma_laufzeit'] = Variable<double>(sigmaLaufzeit.value);
    }
    if (sigmaDoppler.present) {
      map['sigma_doppler'] = Variable<double>(sigmaDoppler.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('zeit: $zeit, ')
          ..write('offsetS: $offsetS, ')
          ..write('richtung: $richtung, ')
          ..write('klasse: $klasse, ')
          ..write('v: $v, ')
          ..write('sigmaV: $sigmaV, ')
          ..write('vLaufzeit: $vLaufzeit, ')
          ..write('vDoppler: $vDoppler, ')
          ..write('kappa: $kappa, ')
          ..write('dEst: $dEst, ')
          ..write('nToene: $nToene, ')
          ..write('restLaufzeit: $restLaufzeit, ')
          ..write('pegel: $pegel, ')
          ..write('dauer: $dauer, ')
          ..write('grund: $grund, ')
          ..write('grundCode: $grundCode, ')
          ..write('laneIndex: $laneIndex, ')
          ..write('distanceUsedM: $distanceUsedM, ')
          ..write('sigmaLaufzeit: $sigmaLaufzeit, ')
          ..write('sigmaDoppler: $sigmaDoppler')
          ..write(')'))
        .toString();
  }
}

class $ReferenceTracksTable extends ReferenceTracks
    with TableInfo<$ReferenceTracksTable, ReferenceTrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
    'site_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sites (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    source,
    siteId,
    createdAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferenceTrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferenceTrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceTrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}site_id'],
      ),
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
    );
  }

  @override
  $ReferenceTracksTable createAlias(String alias) {
    return $ReferenceTracksTable(attachedDatabase, alias);
  }
}

class ReferenceTrackRow extends DataClass
    implements Insertable<ReferenceTrackRow> {
  final int id;
  final String name;

  /// `logger`, `gpx` or `csv`.
  final String source;
  final int? siteId;
  final int createdAtUtcMs;
  const ReferenceTrackRow({
    required this.id,
    required this.name,
    required this.source,
    this.siteId,
    required this.createdAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || siteId != null) {
      map['site_id'] = Variable<int>(siteId);
    }
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    return map;
  }

  ReferenceTracksCompanion toCompanion(bool nullToAbsent) {
    return ReferenceTracksCompanion(
      id: Value(id),
      name: Value(name),
      source: Value(source),
      siteId: siteId == null && nullToAbsent
          ? const Value.absent()
          : Value(siteId),
      createdAtUtcMs: Value(createdAtUtcMs),
    );
  }

  factory ReferenceTrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceTrackRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      siteId: serializer.fromJson<int?>(json['siteId']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'siteId': serializer.toJson<int?>(siteId),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
    };
  }

  ReferenceTrackRow copyWith({
    int? id,
    String? name,
    String? source,
    Value<int?> siteId = const Value.absent(),
    int? createdAtUtcMs,
  }) => ReferenceTrackRow(
    id: id ?? this.id,
    name: name ?? this.name,
    source: source ?? this.source,
    siteId: siteId.present ? siteId.value : this.siteId,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
  );
  ReferenceTrackRow copyWithCompanion(ReferenceTracksCompanion data) {
    return ReferenceTrackRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceTrackRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('siteId: $siteId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, source, siteId, createdAtUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceTrackRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.source == this.source &&
          other.siteId == this.siteId &&
          other.createdAtUtcMs == this.createdAtUtcMs);
}

class ReferenceTracksCompanion extends UpdateCompanion<ReferenceTrackRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> source;
  final Value<int?> siteId;
  final Value<int> createdAtUtcMs;
  const ReferenceTracksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.siteId = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
  });
  ReferenceTracksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String source,
    this.siteId = const Value.absent(),
    required int createdAtUtcMs,
  }) : name = Value(name),
       source = Value(source),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<ReferenceTrackRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? source,
    Expression<int>? siteId,
    Expression<int>? createdAtUtcMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (siteId != null) 'site_id': siteId,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
    });
  }

  ReferenceTracksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? source,
    Value<int?>? siteId,
    Value<int>? createdAtUtcMs,
  }) {
    return ReferenceTracksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      siteId: siteId ?? this.siteId,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceTracksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('siteId: $siteId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs')
          ..write(')'))
        .toString();
  }
}

class $ReferencePointsTable extends ReferencePoints
    with TableInfo<$ReferencePointsTable, ReferencePointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferencePointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reference_tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timeUtcMsMeta = const VerificationMeta(
    'timeUtcMs',
  );
  @override
  late final GeneratedColumn<int> timeUtcMs = GeneratedColumn<int>(
    'time_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMsMeta = const VerificationMeta(
    'speedMs',
  );
  @override
  late final GeneratedColumn<double> speedMs = GeneratedColumn<double>(
    'speed_ms',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedAccuracyMeta = const VerificationMeta(
    'speedAccuracy',
  );
  @override
  late final GeneratedColumn<double> speedAccuracy = GeneratedColumn<double>(
    'speed_accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedDerivedMeta = const VerificationMeta(
    'speedDerived',
  );
  @override
  late final GeneratedColumn<bool> speedDerived = GeneratedColumn<bool>(
    'speed_derived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("speed_derived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    timeUtcMs,
    lat,
    lon,
    speedMs,
    accuracyM,
    speedAccuracy,
    speedDerived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferencePointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('time_utc_ms')) {
      context.handle(
        _timeUtcMsMeta,
        timeUtcMs.isAcceptableOrUnknown(data['time_utc_ms']!, _timeUtcMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeUtcMsMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('speed_ms')) {
      context.handle(
        _speedMsMeta,
        speedMs.isAcceptableOrUnknown(data['speed_ms']!, _speedMsMeta),
      );
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('speed_accuracy')) {
      context.handle(
        _speedAccuracyMeta,
        speedAccuracy.isAcceptableOrUnknown(
          data['speed_accuracy']!,
          _speedAccuracyMeta,
        ),
      );
    }
    if (data.containsKey('speed_derived')) {
      context.handle(
        _speedDerivedMeta,
        speedDerived.isAcceptableOrUnknown(
          data['speed_derived']!,
          _speedDerivedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferencePointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferencePointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      timeUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_utc_ms'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      speedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_ms'],
      ),
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      speedAccuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_accuracy'],
      ),
      speedDerived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}speed_derived'],
      )!,
    );
  }

  @override
  $ReferencePointsTable createAlias(String alias) {
    return $ReferencePointsTable(attachedDatabase, alias);
  }
}

class ReferencePointRow extends DataClass
    implements Insertable<ReferencePointRow> {
  final int id;
  final int trackId;
  final int timeUtcMs;
  final double lat;
  final double lon;
  final double? speedMs;
  final double? accuracyM;
  final double? speedAccuracy;
  final bool speedDerived;
  const ReferencePointRow({
    required this.id,
    required this.trackId,
    required this.timeUtcMs,
    required this.lat,
    required this.lon,
    this.speedMs,
    this.accuracyM,
    this.speedAccuracy,
    required this.speedDerived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['time_utc_ms'] = Variable<int>(timeUtcMs);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || speedMs != null) {
      map['speed_ms'] = Variable<double>(speedMs);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || speedAccuracy != null) {
      map['speed_accuracy'] = Variable<double>(speedAccuracy);
    }
    map['speed_derived'] = Variable<bool>(speedDerived);
    return map;
  }

  ReferencePointsCompanion toCompanion(bool nullToAbsent) {
    return ReferencePointsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      timeUtcMs: Value(timeUtcMs),
      lat: Value(lat),
      lon: Value(lon),
      speedMs: speedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMs),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      speedAccuracy: speedAccuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(speedAccuracy),
      speedDerived: Value(speedDerived),
    );
  }

  factory ReferencePointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferencePointRow(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      timeUtcMs: serializer.fromJson<int>(json['timeUtcMs']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      speedMs: serializer.fromJson<double?>(json['speedMs']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      speedAccuracy: serializer.fromJson<double?>(json['speedAccuracy']),
      speedDerived: serializer.fromJson<bool>(json['speedDerived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'timeUtcMs': serializer.toJson<int>(timeUtcMs),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'speedMs': serializer.toJson<double?>(speedMs),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'speedAccuracy': serializer.toJson<double?>(speedAccuracy),
      'speedDerived': serializer.toJson<bool>(speedDerived),
    };
  }

  ReferencePointRow copyWith({
    int? id,
    int? trackId,
    int? timeUtcMs,
    double? lat,
    double? lon,
    Value<double?> speedMs = const Value.absent(),
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> speedAccuracy = const Value.absent(),
    bool? speedDerived,
  }) => ReferencePointRow(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    timeUtcMs: timeUtcMs ?? this.timeUtcMs,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    speedMs: speedMs.present ? speedMs.value : this.speedMs,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    speedAccuracy: speedAccuracy.present
        ? speedAccuracy.value
        : this.speedAccuracy,
    speedDerived: speedDerived ?? this.speedDerived,
  );
  ReferencePointRow copyWithCompanion(ReferencePointsCompanion data) {
    return ReferencePointRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      timeUtcMs: data.timeUtcMs.present ? data.timeUtcMs.value : this.timeUtcMs,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      speedMs: data.speedMs.present ? data.speedMs.value : this.speedMs,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      speedAccuracy: data.speedAccuracy.present
          ? data.speedAccuracy.value
          : this.speedAccuracy,
      speedDerived: data.speedDerived.present
          ? data.speedDerived.value
          : this.speedDerived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferencePointRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('timeUtcMs: $timeUtcMs, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('speedMs: $speedMs, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedAccuracy: $speedAccuracy, ')
          ..write('speedDerived: $speedDerived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackId,
    timeUtcMs,
    lat,
    lon,
    speedMs,
    accuracyM,
    speedAccuracy,
    speedDerived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferencePointRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.timeUtcMs == this.timeUtcMs &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.speedMs == this.speedMs &&
          other.accuracyM == this.accuracyM &&
          other.speedAccuracy == this.speedAccuracy &&
          other.speedDerived == this.speedDerived);
}

class ReferencePointsCompanion extends UpdateCompanion<ReferencePointRow> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<int> timeUtcMs;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> speedMs;
  final Value<double?> accuracyM;
  final Value<double?> speedAccuracy;
  final Value<bool> speedDerived;
  const ReferencePointsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.timeUtcMs = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.speedMs = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedAccuracy = const Value.absent(),
    this.speedDerived = const Value.absent(),
  });
  ReferencePointsCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required int timeUtcMs,
    required double lat,
    required double lon,
    this.speedMs = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedAccuracy = const Value.absent(),
    this.speedDerived = const Value.absent(),
  }) : trackId = Value(trackId),
       timeUtcMs = Value(timeUtcMs),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<ReferencePointRow> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? timeUtcMs,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? speedMs,
    Expression<double>? accuracyM,
    Expression<double>? speedAccuracy,
    Expression<bool>? speedDerived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (timeUtcMs != null) 'time_utc_ms': timeUtcMs,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (speedMs != null) 'speed_ms': speedMs,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (speedAccuracy != null) 'speed_accuracy': speedAccuracy,
      if (speedDerived != null) 'speed_derived': speedDerived,
    });
  }

  ReferencePointsCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<int>? timeUtcMs,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? speedMs,
    Value<double?>? accuracyM,
    Value<double?>? speedAccuracy,
    Value<bool>? speedDerived,
  }) {
    return ReferencePointsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      timeUtcMs: timeUtcMs ?? this.timeUtcMs,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      speedMs: speedMs ?? this.speedMs,
      accuracyM: accuracyM ?? this.accuracyM,
      speedAccuracy: speedAccuracy ?? this.speedAccuracy,
      speedDerived: speedDerived ?? this.speedDerived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (timeUtcMs.present) {
      map['time_utc_ms'] = Variable<int>(timeUtcMs.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (speedMs.present) {
      map['speed_ms'] = Variable<double>(speedMs.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (speedAccuracy.present) {
      map['speed_accuracy'] = Variable<double>(speedAccuracy.value);
    }
    if (speedDerived.present) {
      map['speed_derived'] = Variable<bool>(speedDerived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferencePointsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('timeUtcMs: $timeUtcMs, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('speedMs: $speedMs, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedAccuracy: $speedAccuracy, ')
          ..write('speedDerived: $speedDerived')
          ..write(')'))
        .toString();
  }
}

abstract class _$NyooomDatabase extends GeneratedDatabase {
  _$NyooomDatabase(QueryExecutor e) : super(e);
  $NyooomDatabaseManager get managers => $NyooomDatabaseManager(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $CalibrationsTable calibrations = $CalibrationsTable(this);
  late final $SitesTable sites = $SitesTable(this);
  late final $LanesTable lanes = $LanesTable(this);
  late final $MeasurementSeriesTable measurementSeries =
      $MeasurementSeriesTable(this);
  late final $PassesTable passes = $PassesTable(this);
  late final $ReferenceTracksTable referenceTracks = $ReferenceTracksTable(
    this,
  );
  late final $ReferencePointsTable referencePoints = $ReferencePointsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    devices,
    calibrations,
    sites,
    lanes,
    measurementSeries,
    passes,
    referenceTracks,
    referencePoints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calibrations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sites',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lanes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sites',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('measurement_series', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('measurement_series', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calibrations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('measurement_series', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurement_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('passes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sites',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reference_tracks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'reference_tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reference_points', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  Value<int> id,
  required String model,
  Value<String> inputDevice,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<int> id,
  Value<String> model,
  Value<String> inputDevice,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$NyooomDatabase, $DevicesTable, DeviceRow> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CalibrationsTable, List<CalibrationRow>>
  _calibrationsRefsTable(_$NyooomDatabase db) => MultiTypedResultKey.fromTable(
    db.calibrations,
    aliasName: 'devices__id__calibrations__device_id',
  );

  $$CalibrationsTableProcessedTableManager get calibrationsRefs {
    final manager = $$CalibrationsTableTableManager(
      $_db,
      $_db.calibrations,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_calibrationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MeasurementSeriesTable, List<SeriesRow>>
  _measurementSeriesRefsTable(_$NyooomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.measurementSeries,
        aliasName: 'devices__id__measurement_series__device_id',
      );

  $$MeasurementSeriesTableProcessedTableManager get measurementSeriesRefs {
    final manager = $$MeasurementSeriesTableTableManager(
      $_db,
      $_db.measurementSeries,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _measurementSeriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$NyooomDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputDevice => $composableBuilder(
    column: $table.inputDevice,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> calibrationsRefs(
    Expression<bool> Function($$CalibrationsTableFilterComposer f) f,
  ) {
    final $$CalibrationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calibrations,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalibrationsTableFilterComposer(
            $db: $db,
            $table: $db.calibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> measurementSeriesRefs(
    Expression<bool> Function($$MeasurementSeriesTableFilterComposer f) f,
  ) {
    final $$MeasurementSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurementSeries,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementSeriesTableFilterComposer(
            $db: $db,
            $table: $db.measurementSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$NyooomDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputDevice => $composableBuilder(
    column: $table.inputDevice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get inputDevice => $composableBuilder(
    column: $table.inputDevice,
    builder: (column) => column,
  );

  Expression<T> calibrationsRefs<T extends Object>(
    Expression<T> Function($$CalibrationsTableAnnotationComposer a) f,
  ) {
    final $$CalibrationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calibrations,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalibrationsTableAnnotationComposer(
            $db: $db,
            $table: $db.calibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> measurementSeriesRefs<T extends Object>(
    Expression<T> Function($$MeasurementSeriesTableAnnotationComposer a) f,
  ) {
    final $$MeasurementSeriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.measurementSeries,
          getReferencedColumn: (t) => t.deviceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeasurementSeriesTableAnnotationComposer(
                $db: $db,
                $table: $db.measurementSeries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $DevicesTable,
          DeviceRow,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (DeviceRow, $$DevicesTableReferences),
          DeviceRow,
          PrefetchHooks Function({
            bool calibrationsRefs,
            bool measurementSeriesRefs,
          })
        > {
  $$DevicesTableTableManager(_$NyooomDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> inputDevice = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                model: model,
                inputDevice: inputDevice,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String model,
                Value<String> inputDevice = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                model: model,
                inputDevice: inputDevice,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DevicesTable, DeviceRow>(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({calibrationsRefs = false, measurementSeriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (calibrationsRefs) db.calibrations,
                    if (measurementSeriesRefs) db.measurementSeries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (calibrationsRefs)
                        await $_getPrefetchedDataByColumns<
                          DeviceRow,
                          $DevicesTable,
                          CalibrationRow,
                          $CalibrationsTable
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._calibrationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).calibrationsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'device_id',
                          typedResults: items,
                        ),
                      if (measurementSeriesRefs)
                        await $_getPrefetchedDataByColumns<
                          DeviceRow,
                          $DevicesTable,
                          SeriesRow,
                          $MeasurementSeriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._measurementSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementSeriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'device_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $DevicesTable,
      DeviceRow,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (DeviceRow, $$DevicesTableReferences),
      DeviceRow,
      PrefetchHooks Function({
        bool calibrationsRefs,
        bool measurementSeriesRefs,
      })
    >;
typedef $$CalibrationsTableCreateCompanionBuilder =
    CalibrationsCompanion Function({
      Value<int> id,
      required int deviceId,
      required double micSpacingM,
      required double channelOffsetS,
      required double temperatureC,
      Value<bool> swapChannels,
      required int createdAtUtcMs,
      Value<String?> checksJson,
    });
typedef $$CalibrationsTableUpdateCompanionBuilder =
    CalibrationsCompanion Function({
      Value<int> id,
      Value<int> deviceId,
      Value<double> micSpacingM,
      Value<double> channelOffsetS,
      Value<double> temperatureC,
      Value<bool> swapChannels,
      Value<int> createdAtUtcMs,
      Value<String?> checksJson,
    });

final class $$CalibrationsTableReferences
    extends
        BaseReferences<_$NyooomDatabase, $CalibrationsTable, CalibrationRow> {
  $$CalibrationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceIdTable(_$NyooomDatabase db) =>
      db.devices.createAlias('calibrations__device_id__devices__id');

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<int>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MeasurementSeriesTable, List<SeriesRow>>
  _measurementSeriesRefsTable(_$NyooomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.measurementSeries,
        aliasName: 'calibrations__id__measurement_series__calibration_id',
      );

  $$MeasurementSeriesTableProcessedTableManager get measurementSeriesRefs {
    final manager = $$MeasurementSeriesTableTableManager(
      $_db,
      $_db.measurementSeries,
    ).filter((f) => f.calibrationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _measurementSeriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CalibrationsTableFilterComposer
    extends Composer<_$NyooomDatabase, $CalibrationsTable> {
  $$CalibrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get micSpacingM => $composableBuilder(
    column: $table.micSpacingM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get channelOffsetS => $composableBuilder(
    column: $table.channelOffsetS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get swapChannels => $composableBuilder(
    column: $table.swapChannels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksJson => $composableBuilder(
    column: $table.checksJson,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> measurementSeriesRefs(
    Expression<bool> Function($$MeasurementSeriesTableFilterComposer f) f,
  ) {
    final $$MeasurementSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurementSeries,
      getReferencedColumn: (t) => t.calibrationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementSeriesTableFilterComposer(
            $db: $db,
            $table: $db.measurementSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalibrationsTableOrderingComposer
    extends Composer<_$NyooomDatabase, $CalibrationsTable> {
  $$CalibrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get micSpacingM => $composableBuilder(
    column: $table.micSpacingM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get channelOffsetS => $composableBuilder(
    column: $table.channelOffsetS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get swapChannels => $composableBuilder(
    column: $table.swapChannels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksJson => $composableBuilder(
    column: $table.checksJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalibrationsTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $CalibrationsTable> {
  $$CalibrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get micSpacingM => $composableBuilder(
    column: $table.micSpacingM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get channelOffsetS => $composableBuilder(
    column: $table.channelOffsetS,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get swapChannels => $composableBuilder(
    column: $table.swapChannels,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksJson => $composableBuilder(
    column: $table.checksJson,
    builder: (column) => column,
  );

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> measurementSeriesRefs<T extends Object>(
    Expression<T> Function($$MeasurementSeriesTableAnnotationComposer a) f,
  ) {
    final $$MeasurementSeriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.measurementSeries,
          getReferencedColumn: (t) => t.calibrationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeasurementSeriesTableAnnotationComposer(
                $db: $db,
                $table: $db.measurementSeries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CalibrationsTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $CalibrationsTable,
          CalibrationRow,
          $$CalibrationsTableFilterComposer,
          $$CalibrationsTableOrderingComposer,
          $$CalibrationsTableAnnotationComposer,
          $$CalibrationsTableCreateCompanionBuilder,
          $$CalibrationsTableUpdateCompanionBuilder,
          (CalibrationRow, $$CalibrationsTableReferences),
          CalibrationRow,
          PrefetchHooks Function({bool deviceId, bool measurementSeriesRefs})
        > {
  $$CalibrationsTableTableManager(_$NyooomDatabase db, $CalibrationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalibrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalibrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalibrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deviceId = const Value.absent(),
                Value<double> micSpacingM = const Value.absent(),
                Value<double> channelOffsetS = const Value.absent(),
                Value<double> temperatureC = const Value.absent(),
                Value<bool> swapChannels = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<String?> checksJson = const Value.absent(),
              }) => CalibrationsCompanion(
                id: id,
                deviceId: deviceId,
                micSpacingM: micSpacingM,
                channelOffsetS: channelOffsetS,
                temperatureC: temperatureC,
                swapChannels: swapChannels,
                createdAtUtcMs: createdAtUtcMs,
                checksJson: checksJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deviceId,
                required double micSpacingM,
                required double channelOffsetS,
                required double temperatureC,
                Value<bool> swapChannels = const Value.absent(),
                required int createdAtUtcMs,
                Value<String?> checksJson = const Value.absent(),
              }) => CalibrationsCompanion.insert(
                id: id,
                deviceId: deviceId,
                micSpacingM: micSpacingM,
                channelOffsetS: channelOffsetS,
                temperatureC: temperatureC,
                swapChannels: swapChannels,
                createdAtUtcMs: createdAtUtcMs,
                checksJson: checksJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalibrationsTable, CalibrationRow>(table),
                  $$CalibrationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({deviceId = false, measurementSeriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (measurementSeriesRefs) db.measurementSeries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (deviceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.deviceId,
                            referencedTable: $$CalibrationsTableReferences
                                ._deviceIdTable(db),
                            referencedColumn: $$CalibrationsTableReferences
                                ._deviceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (measurementSeriesRefs)
                        await $_getPrefetchedDataByColumns<
                          CalibrationRow,
                          $CalibrationsTable,
                          SeriesRow,
                          $MeasurementSeriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CalibrationsTableReferences
                              ._measurementSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CalibrationsTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementSeriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'calibration_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CalibrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $CalibrationsTable,
      CalibrationRow,
      $$CalibrationsTableFilterComposer,
      $$CalibrationsTableOrderingComposer,
      $$CalibrationsTableAnnotationComposer,
      $$CalibrationsTableCreateCompanionBuilder,
      $$CalibrationsTableUpdateCompanionBuilder,
      (CalibrationRow, $$CalibrationsTableReferences),
      CalibrationRow,
      PrefetchHooks Function({bool deviceId, bool measurementSeriesRefs})
    >;
typedef $$SitesTableCreateCompanionBuilder = SitesCompanion Function({
  Value<int> id,
  required String name,
  required double micHeightM,
  required double speedLimitKmh,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> plusXBearingDeg,
});
typedef $$SitesTableUpdateCompanionBuilder = SitesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double> micHeightM,
  Value<double> speedLimitKmh,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> plusXBearingDeg,
});

final class $$SitesTableReferences
    extends BaseReferences<_$NyooomDatabase, $SitesTable, SiteRow> {
  $$SitesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LanesTable, List<LaneRow>> _lanesRefsTable(
    _$NyooomDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lanes,
    aliasName: 'sites__id__lanes__site_id',
  );

  $$LanesTableProcessedTableManager get lanesRefs {
    final manager = $$LanesTableTableManager(
      $_db,
      $_db.lanes,
    ).filter((f) => f.siteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lanesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MeasurementSeriesTable, List<SeriesRow>>
  _measurementSeriesRefsTable(_$NyooomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.measurementSeries,
        aliasName: 'sites__id__measurement_series__site_id',
      );

  $$MeasurementSeriesTableProcessedTableManager get measurementSeriesRefs {
    final manager = $$MeasurementSeriesTableTableManager(
      $_db,
      $_db.measurementSeries,
    ).filter((f) => f.siteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _measurementSeriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReferenceTracksTable, List<ReferenceTrackRow>>
  _referenceTracksRefsTable(_$NyooomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.referenceTracks,
        aliasName: 'sites__id__reference_tracks__site_id',
      );

  $$ReferenceTracksTableProcessedTableManager get referenceTracksRefs {
    final manager = $$ReferenceTracksTableTableManager(
      $_db,
      $_db.referenceTracks,
    ).filter((f) => f.siteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _referenceTracksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SitesTableFilterComposer
    extends Composer<_$NyooomDatabase, $SitesTable> {
  $$SitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get micHeightM => $composableBuilder(
    column: $table.micHeightM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedLimitKmh => $composableBuilder(
    column: $table.speedLimitKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get plusXBearingDeg => $composableBuilder(
    column: $table.plusXBearingDeg,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lanesRefs(
    Expression<bool> Function($$LanesTableFilterComposer f) f,
  ) {
    final $$LanesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lanes,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanesTableFilterComposer(
            $db: $db,
            $table: $db.lanes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> measurementSeriesRefs(
    Expression<bool> Function($$MeasurementSeriesTableFilterComposer f) f,
  ) {
    final $$MeasurementSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurementSeries,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementSeriesTableFilterComposer(
            $db: $db,
            $table: $db.measurementSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> referenceTracksRefs(
    Expression<bool> Function($$ReferenceTracksTableFilterComposer f) f,
  ) {
    final $$ReferenceTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referenceTracks,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceTracksTableFilterComposer(
            $db: $db,
            $table: $db.referenceTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SitesTableOrderingComposer
    extends Composer<_$NyooomDatabase, $SitesTable> {
  $$SitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get micHeightM => $composableBuilder(
    column: $table.micHeightM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedLimitKmh => $composableBuilder(
    column: $table.speedLimitKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get plusXBearingDeg => $composableBuilder(
    column: $table.plusXBearingDeg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SitesTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $SitesTable> {
  $$SitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get micHeightM => $composableBuilder(
    column: $table.micHeightM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedLimitKmh => $composableBuilder(
    column: $table.speedLimitKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get plusXBearingDeg => $composableBuilder(
    column: $table.plusXBearingDeg,
    builder: (column) => column,
  );

  Expression<T> lanesRefs<T extends Object>(
    Expression<T> Function($$LanesTableAnnotationComposer a) f,
  ) {
    final $$LanesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lanes,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanesTableAnnotationComposer(
            $db: $db,
            $table: $db.lanes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> measurementSeriesRefs<T extends Object>(
    Expression<T> Function($$MeasurementSeriesTableAnnotationComposer a) f,
  ) {
    final $$MeasurementSeriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.measurementSeries,
          getReferencedColumn: (t) => t.siteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeasurementSeriesTableAnnotationComposer(
                $db: $db,
                $table: $db.measurementSeries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> referenceTracksRefs<T extends Object>(
    Expression<T> Function($$ReferenceTracksTableAnnotationComposer a) f,
  ) {
    final $$ReferenceTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referenceTracks,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.referenceTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SitesTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $SitesTable,
          SiteRow,
          $$SitesTableFilterComposer,
          $$SitesTableOrderingComposer,
          $$SitesTableAnnotationComposer,
          $$SitesTableCreateCompanionBuilder,
          $$SitesTableUpdateCompanionBuilder,
          (SiteRow, $$SitesTableReferences),
          SiteRow,
          PrefetchHooks Function({
            bool lanesRefs,
            bool measurementSeriesRefs,
            bool referenceTracksRefs,
          })
        > {
  $$SitesTableTableManager(_$NyooomDatabase db, $SitesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> micHeightM = const Value.absent(),
                Value<double> speedLimitKmh = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> plusXBearingDeg = const Value.absent(),
              }) => SitesCompanion(
                id: id,
                name: name,
                micHeightM: micHeightM,
                speedLimitKmh: speedLimitKmh,
                latitude: latitude,
                longitude: longitude,
                plusXBearingDeg: plusXBearingDeg,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double micHeightM,
                required double speedLimitKmh,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> plusXBearingDeg = const Value.absent(),
              }) => SitesCompanion.insert(
                id: id,
                name: name,
                micHeightM: micHeightM,
                speedLimitKmh: speedLimitKmh,
                latitude: latitude,
                longitude: longitude,
                plusXBearingDeg: plusXBearingDeg,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SitesTable, SiteRow>(table),
                  $$SitesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                lanesRefs = false,
                measurementSeriesRefs = false,
                referenceTracksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lanesRefs) db.lanes,
                    if (measurementSeriesRefs) db.measurementSeries,
                    if (referenceTracksRefs) db.referenceTracks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lanesRefs)
                        await $_getPrefetchedDataByColumns<
                          SiteRow,
                          $SitesTable,
                          LaneRow,
                          $LanesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SitesTableReferences
                              ._lanesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SitesTableReferences(db, table, p0).lanesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'site_id',
                          typedResults: items,
                        ),
                      if (measurementSeriesRefs)
                        await $_getPrefetchedDataByColumns<
                          SiteRow,
                          $SitesTable,
                          SeriesRow,
                          $MeasurementSeriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SitesTableReferences
                              ._measurementSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SitesTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementSeriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'site_id',
                          typedResults: items,
                        ),
                      if (referenceTracksRefs)
                        await $_getPrefetchedDataByColumns<
                          SiteRow,
                          $SitesTable,
                          ReferenceTrackRow,
                          $ReferenceTracksTable
                        >(
                          currentTable: table,
                          referencedTable: $$SitesTableReferences
                              ._referenceTracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SitesTableReferences(
                                db,
                                table,
                                p0,
                              ).referenceTracksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'site_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SitesTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $SitesTable,
      SiteRow,
      $$SitesTableFilterComposer,
      $$SitesTableOrderingComposer,
      $$SitesTableAnnotationComposer,
      $$SitesTableCreateCompanionBuilder,
      $$SitesTableUpdateCompanionBuilder,
      (SiteRow, $$SitesTableReferences),
      SiteRow,
      PrefetchHooks Function({
        bool lanesRefs,
        bool measurementSeriesRefs,
        bool referenceTracksRefs,
      })
    >;
typedef $$LanesTableCreateCompanionBuilder = LanesCompanion Function({
  Value<int> id,
  required int siteId,
  required int position,
  required double horizontalDistanceM,
  required int direction,
});
typedef $$LanesTableUpdateCompanionBuilder = LanesCompanion Function({
  Value<int> id,
  Value<int> siteId,
  Value<int> position,
  Value<double> horizontalDistanceM,
  Value<int> direction,
});

final class $$LanesTableReferences
    extends BaseReferences<_$NyooomDatabase, $LanesTable, LaneRow> {
  $$LanesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SitesTable _siteIdTable(_$NyooomDatabase db) =>
      db.sites.createAlias('lanes__site_id__sites__id');

  $$SitesTableProcessedTableManager get siteId {
    final $_column = $_itemColumn<int>('site_id')!;

    final manager = $$SitesTableTableManager(
      $_db,
      $_db.sites,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_siteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LanesTableFilterComposer
    extends Composer<_$NyooomDatabase, $LanesTable> {
  $$LanesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get horizontalDistanceM => $composableBuilder(
    column: $table.horizontalDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  $$SitesTableFilterComposer get siteId {
    final $$SitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableFilterComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LanesTableOrderingComposer
    extends Composer<_$NyooomDatabase, $LanesTable> {
  $$LanesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get horizontalDistanceM => $composableBuilder(
    column: $table.horizontalDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  $$SitesTableOrderingComposer get siteId {
    final $$SitesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableOrderingComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LanesTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $LanesTable> {
  $$LanesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get horizontalDistanceM => $composableBuilder(
    column: $table.horizontalDistanceM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  $$SitesTableAnnotationComposer get siteId {
    final $$SitesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableAnnotationComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LanesTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $LanesTable,
          LaneRow,
          $$LanesTableFilterComposer,
          $$LanesTableOrderingComposer,
          $$LanesTableAnnotationComposer,
          $$LanesTableCreateCompanionBuilder,
          $$LanesTableUpdateCompanionBuilder,
          (LaneRow, $$LanesTableReferences),
          LaneRow,
          PrefetchHooks Function({bool siteId})
        > {
  $$LanesTableTableManager(_$NyooomDatabase db, $LanesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LanesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LanesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LanesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> siteId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double> horizontalDistanceM = const Value.absent(),
                Value<int> direction = const Value.absent(),
              }) => LanesCompanion(
                id: id,
                siteId: siteId,
                position: position,
                horizontalDistanceM: horizontalDistanceM,
                direction: direction,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int siteId,
                required int position,
                required double horizontalDistanceM,
                required int direction,
              }) => LanesCompanion.insert(
                id: id,
                siteId: siteId,
                position: position,
                horizontalDistanceM: horizontalDistanceM,
                direction: direction,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LanesTable, LaneRow>(table),
                  $$LanesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({siteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (siteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.siteId,
                        referencedTable: $$LanesTableReferences._siteIdTable(
                          db,
                        ),
                        referencedColumn: $$LanesTableReferences
                            ._siteIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LanesTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $LanesTable,
      LaneRow,
      $$LanesTableFilterComposer,
      $$LanesTableOrderingComposer,
      $$LanesTableAnnotationComposer,
      $$LanesTableCreateCompanionBuilder,
      $$LanesTableUpdateCompanionBuilder,
      (LaneRow, $$LanesTableReferences),
      LaneRow,
      PrefetchHooks Function({bool siteId})
    >;
typedef $$MeasurementSeriesTableCreateCompanionBuilder =
    MeasurementSeriesCompanion Function({
      Value<int> id,
      required int siteId,
      Value<int?> deviceId,
      Value<int?> calibrationId,
      required double temperatureC,
      required double speedOfSound,
      required double sourceHeightM,
      required int startedAtUtcMs,
      Value<int?> endedAtUtcMs,
      required String directory,
      Value<bool> saveRawAudio,
      Value<bool> simulated,
      required String configJson,
      Value<String?> segmentsJson,
      Value<double?> learnedMicSpacingM,
      Value<double?> learnedChannelOffsetS,
      Value<int?> learnedPassCount,
      Value<String?> temperatureLogJson,
    });
typedef $$MeasurementSeriesTableUpdateCompanionBuilder =
    MeasurementSeriesCompanion Function({
      Value<int> id,
      Value<int> siteId,
      Value<int?> deviceId,
      Value<int?> calibrationId,
      Value<double> temperatureC,
      Value<double> speedOfSound,
      Value<double> sourceHeightM,
      Value<int> startedAtUtcMs,
      Value<int?> endedAtUtcMs,
      Value<String> directory,
      Value<bool> saveRawAudio,
      Value<bool> simulated,
      Value<String> configJson,
      Value<String?> segmentsJson,
      Value<double?> learnedMicSpacingM,
      Value<double?> learnedChannelOffsetS,
      Value<int?> learnedPassCount,
      Value<String?> temperatureLogJson,
    });

final class $$MeasurementSeriesTableReferences
    extends
        BaseReferences<_$NyooomDatabase, $MeasurementSeriesTable, SeriesRow> {
  $$MeasurementSeriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SitesTable _siteIdTable(_$NyooomDatabase db) =>
      db.sites.createAlias('measurement_series__site_id__sites__id');

  $$SitesTableProcessedTableManager get siteId {
    final $_column = $_itemColumn<int>('site_id')!;

    final manager = $$SitesTableTableManager(
      $_db,
      $_db.sites,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_siteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DevicesTable _deviceIdTable(_$NyooomDatabase db) =>
      db.devices.createAlias('measurement_series__device_id__devices__id');

  $$DevicesTableProcessedTableManager? get deviceId {
    final $_column = $_itemColumn<int>('device_id');
    if ($_column == null) return null;
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CalibrationsTable _calibrationIdTable(_$NyooomDatabase db) => db
      .calibrations
      .createAlias('measurement_series__calibration_id__calibrations__id');

  $$CalibrationsTableProcessedTableManager? get calibrationId {
    final $_column = $_itemColumn<int>('calibration_id');
    if ($_column == null) return null;
    final manager = $$CalibrationsTableTableManager(
      $_db,
      $_db.calibrations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calibrationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PassesTable, List<PassRow>> _passesRefsTable(
    _$NyooomDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.passes,
    aliasName: 'measurement_series__id__passes__series_id',
  );

  $$PassesTableProcessedTableManager get passesRefs {
    final manager = $$PassesTableTableManager(
      $_db,
      $_db.passes,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_passesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MeasurementSeriesTableFilterComposer
    extends Composer<_$NyooomDatabase, $MeasurementSeriesTable> {
  $$MeasurementSeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedOfSound => $composableBuilder(
    column: $table.speedOfSound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sourceHeightM => $composableBuilder(
    column: $table.sourceHeightM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtUtcMs => $composableBuilder(
    column: $table.startedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtUtcMs => $composableBuilder(
    column: $table.endedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saveRawAudio => $composableBuilder(
    column: $table.saveRawAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get simulated => $composableBuilder(
    column: $table.simulated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get learnedMicSpacingM => $composableBuilder(
    column: $table.learnedMicSpacingM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get learnedChannelOffsetS => $composableBuilder(
    column: $table.learnedChannelOffsetS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedPassCount => $composableBuilder(
    column: $table.learnedPassCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get temperatureLogJson => $composableBuilder(
    column: $table.temperatureLogJson,
    builder: (column) => ColumnFilters(column),
  );

  $$SitesTableFilterComposer get siteId {
    final $$SitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableFilterComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CalibrationsTableFilterComposer get calibrationId {
    final $$CalibrationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calibrationId,
      referencedTable: $db.calibrations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalibrationsTableFilterComposer(
            $db: $db,
            $table: $db.calibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> passesRefs(
    Expression<bool> Function($$PassesTableFilterComposer f) f,
  ) {
    final $$PassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passes,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassesTableFilterComposer(
            $db: $db,
            $table: $db.passes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MeasurementSeriesTableOrderingComposer
    extends Composer<_$NyooomDatabase, $MeasurementSeriesTable> {
  $$MeasurementSeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedOfSound => $composableBuilder(
    column: $table.speedOfSound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sourceHeightM => $composableBuilder(
    column: $table.sourceHeightM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtUtcMs => $composableBuilder(
    column: $table.startedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtUtcMs => $composableBuilder(
    column: $table.endedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saveRawAudio => $composableBuilder(
    column: $table.saveRawAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get simulated => $composableBuilder(
    column: $table.simulated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get learnedMicSpacingM => $composableBuilder(
    column: $table.learnedMicSpacingM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get learnedChannelOffsetS => $composableBuilder(
    column: $table.learnedChannelOffsetS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedPassCount => $composableBuilder(
    column: $table.learnedPassCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get temperatureLogJson => $composableBuilder(
    column: $table.temperatureLogJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$SitesTableOrderingComposer get siteId {
    final $$SitesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableOrderingComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CalibrationsTableOrderingComposer get calibrationId {
    final $$CalibrationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calibrationId,
      referencedTable: $db.calibrations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalibrationsTableOrderingComposer(
            $db: $db,
            $table: $db.calibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementSeriesTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $MeasurementSeriesTable> {
  $$MeasurementSeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedOfSound => $composableBuilder(
    column: $table.speedOfSound,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sourceHeightM => $composableBuilder(
    column: $table.sourceHeightM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtUtcMs => $composableBuilder(
    column: $table.startedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtUtcMs => $composableBuilder(
    column: $table.endedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get directory =>
      $composableBuilder(column: $table.directory, builder: (column) => column);

  GeneratedColumn<bool> get saveRawAudio => $composableBuilder(
    column: $table.saveRawAudio,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get simulated =>
      $composableBuilder(column: $table.simulated, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get learnedMicSpacingM => $composableBuilder(
    column: $table.learnedMicSpacingM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get learnedChannelOffsetS => $composableBuilder(
    column: $table.learnedChannelOffsetS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedPassCount => $composableBuilder(
    column: $table.learnedPassCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get temperatureLogJson => $composableBuilder(
    column: $table.temperatureLogJson,
    builder: (column) => column,
  );

  $$SitesTableAnnotationComposer get siteId {
    final $$SitesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableAnnotationComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CalibrationsTableAnnotationComposer get calibrationId {
    final $$CalibrationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calibrationId,
      referencedTable: $db.calibrations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalibrationsTableAnnotationComposer(
            $db: $db,
            $table: $db.calibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> passesRefs<T extends Object>(
    Expression<T> Function($$PassesTableAnnotationComposer a) f,
  ) {
    final $$PassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passes,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassesTableAnnotationComposer(
            $db: $db,
            $table: $db.passes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MeasurementSeriesTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $MeasurementSeriesTable,
          SeriesRow,
          $$MeasurementSeriesTableFilterComposer,
          $$MeasurementSeriesTableOrderingComposer,
          $$MeasurementSeriesTableAnnotationComposer,
          $$MeasurementSeriesTableCreateCompanionBuilder,
          $$MeasurementSeriesTableUpdateCompanionBuilder,
          (SeriesRow, $$MeasurementSeriesTableReferences),
          SeriesRow,
          PrefetchHooks Function({
            bool siteId,
            bool deviceId,
            bool calibrationId,
            bool passesRefs,
          })
        > {
  $$MeasurementSeriesTableTableManager(
    _$NyooomDatabase db,
    $MeasurementSeriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementSeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementSeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementSeriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> siteId = const Value.absent(),
                Value<int?> deviceId = const Value.absent(),
                Value<int?> calibrationId = const Value.absent(),
                Value<double> temperatureC = const Value.absent(),
                Value<double> speedOfSound = const Value.absent(),
                Value<double> sourceHeightM = const Value.absent(),
                Value<int> startedAtUtcMs = const Value.absent(),
                Value<int?> endedAtUtcMs = const Value.absent(),
                Value<String> directory = const Value.absent(),
                Value<bool> saveRawAudio = const Value.absent(),
                Value<bool> simulated = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<String?> segmentsJson = const Value.absent(),
                Value<double?> learnedMicSpacingM = const Value.absent(),
                Value<double?> learnedChannelOffsetS = const Value.absent(),
                Value<int?> learnedPassCount = const Value.absent(),
                Value<String?> temperatureLogJson = const Value.absent(),
              }) => MeasurementSeriesCompanion(
                id: id,
                siteId: siteId,
                deviceId: deviceId,
                calibrationId: calibrationId,
                temperatureC: temperatureC,
                speedOfSound: speedOfSound,
                sourceHeightM: sourceHeightM,
                startedAtUtcMs: startedAtUtcMs,
                endedAtUtcMs: endedAtUtcMs,
                directory: directory,
                saveRawAudio: saveRawAudio,
                simulated: simulated,
                configJson: configJson,
                segmentsJson: segmentsJson,
                learnedMicSpacingM: learnedMicSpacingM,
                learnedChannelOffsetS: learnedChannelOffsetS,
                learnedPassCount: learnedPassCount,
                temperatureLogJson: temperatureLogJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int siteId,
                Value<int?> deviceId = const Value.absent(),
                Value<int?> calibrationId = const Value.absent(),
                required double temperatureC,
                required double speedOfSound,
                required double sourceHeightM,
                required int startedAtUtcMs,
                Value<int?> endedAtUtcMs = const Value.absent(),
                required String directory,
                Value<bool> saveRawAudio = const Value.absent(),
                Value<bool> simulated = const Value.absent(),
                required String configJson,
                Value<String?> segmentsJson = const Value.absent(),
                Value<double?> learnedMicSpacingM = const Value.absent(),
                Value<double?> learnedChannelOffsetS = const Value.absent(),
                Value<int?> learnedPassCount = const Value.absent(),
                Value<String?> temperatureLogJson = const Value.absent(),
              }) => MeasurementSeriesCompanion.insert(
                id: id,
                siteId: siteId,
                deviceId: deviceId,
                calibrationId: calibrationId,
                temperatureC: temperatureC,
                speedOfSound: speedOfSound,
                sourceHeightM: sourceHeightM,
                startedAtUtcMs: startedAtUtcMs,
                endedAtUtcMs: endedAtUtcMs,
                directory: directory,
                saveRawAudio: saveRawAudio,
                simulated: simulated,
                configJson: configJson,
                segmentsJson: segmentsJson,
                learnedMicSpacingM: learnedMicSpacingM,
                learnedChannelOffsetS: learnedChannelOffsetS,
                learnedPassCount: learnedPassCount,
                temperatureLogJson: temperatureLogJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MeasurementSeriesTable, SeriesRow>(table),
                  $$MeasurementSeriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                siteId = false,
                deviceId = false,
                calibrationId = false,
                passesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (passesRefs) db.passes],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (siteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.siteId,
                            referencedTable: $$MeasurementSeriesTableReferences
                                ._siteIdTable(db),
                            referencedColumn: $$MeasurementSeriesTableReferences
                                ._siteIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (deviceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.deviceId,
                            referencedTable: $$MeasurementSeriesTableReferences
                                ._deviceIdTable(db),
                            referencedColumn: $$MeasurementSeriesTableReferences
                                ._deviceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (calibrationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.calibrationId,
                            referencedTable: $$MeasurementSeriesTableReferences
                                ._calibrationIdTable(db),
                            referencedColumn: $$MeasurementSeriesTableReferences
                                ._calibrationIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (passesRefs)
                        await $_getPrefetchedDataByColumns<
                          SeriesRow,
                          $MeasurementSeriesTable,
                          PassRow,
                          $PassesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MeasurementSeriesTableReferences
                              ._passesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MeasurementSeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).passesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'series_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MeasurementSeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $MeasurementSeriesTable,
      SeriesRow,
      $$MeasurementSeriesTableFilterComposer,
      $$MeasurementSeriesTableOrderingComposer,
      $$MeasurementSeriesTableAnnotationComposer,
      $$MeasurementSeriesTableCreateCompanionBuilder,
      $$MeasurementSeriesTableUpdateCompanionBuilder,
      (SeriesRow, $$MeasurementSeriesTableReferences),
      SeriesRow,
      PrefetchHooks Function({
        bool siteId,
        bool deviceId,
        bool calibrationId,
        bool passesRefs,
      })
    >;
typedef $$PassesTableCreateCompanionBuilder = PassesCompanion Function({
  Value<int> id,
  required int seriesId,
  required int zeit,
  required double offsetS,
  required int richtung,
  required String klasse,
  Value<double?> v,
  Value<double?> sigmaV,
  Value<double?> vLaufzeit,
  Value<double?> vDoppler,
  Value<double?> kappa,
  Value<double?> dEst,
  required int nToene,
  Value<double?> restLaufzeit,
  required double pegel,
  required double dauer,
  Value<String?> grund,
  Value<String?> grundCode,
  Value<int?> laneIndex,
  Value<double?> distanceUsedM,
  Value<double?> sigmaLaufzeit,
  Value<double?> sigmaDoppler,
});
typedef $$PassesTableUpdateCompanionBuilder = PassesCompanion Function({
  Value<int> id,
  Value<int> seriesId,
  Value<int> zeit,
  Value<double> offsetS,
  Value<int> richtung,
  Value<String> klasse,
  Value<double?> v,
  Value<double?> sigmaV,
  Value<double?> vLaufzeit,
  Value<double?> vDoppler,
  Value<double?> kappa,
  Value<double?> dEst,
  Value<int> nToene,
  Value<double?> restLaufzeit,
  Value<double> pegel,
  Value<double> dauer,
  Value<String?> grund,
  Value<String?> grundCode,
  Value<int?> laneIndex,
  Value<double?> distanceUsedM,
  Value<double?> sigmaLaufzeit,
  Value<double?> sigmaDoppler,
});

final class $$PassesTableReferences
    extends BaseReferences<_$NyooomDatabase, $PassesTable, PassRow> {
  $$PassesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeasurementSeriesTable _seriesIdTable(_$NyooomDatabase db) => db
      .measurementSeries
      .createAlias('passes__series_id__measurement_series__id');

  $$MeasurementSeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<int>('series_id')!;

    final manager = $$MeasurementSeriesTableTableManager(
      $_db,
      $_db.measurementSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PassesTableFilterComposer
    extends Composer<_$NyooomDatabase, $PassesTable> {
  $$PassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zeit => $composableBuilder(
    column: $table.zeit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get offsetS => $composableBuilder(
    column: $table.offsetS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get richtung => $composableBuilder(
    column: $table.richtung,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get klasse => $composableBuilder(
    column: $table.klasse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get v => $composableBuilder(
    column: $table.v,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sigmaV => $composableBuilder(
    column: $table.sigmaV,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vLaufzeit => $composableBuilder(
    column: $table.vLaufzeit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vDoppler => $composableBuilder(
    column: $table.vDoppler,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kappa => $composableBuilder(
    column: $table.kappa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dEst => $composableBuilder(
    column: $table.dEst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nToene => $composableBuilder(
    column: $table.nToene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get restLaufzeit => $composableBuilder(
    column: $table.restLaufzeit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pegel => $composableBuilder(
    column: $table.pegel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dauer => $composableBuilder(
    column: $table.dauer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grund => $composableBuilder(
    column: $table.grund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grundCode => $composableBuilder(
    column: $table.grundCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get laneIndex => $composableBuilder(
    column: $table.laneIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceUsedM => $composableBuilder(
    column: $table.distanceUsedM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sigmaLaufzeit => $composableBuilder(
    column: $table.sigmaLaufzeit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sigmaDoppler => $composableBuilder(
    column: $table.sigmaDoppler,
    builder: (column) => ColumnFilters(column),
  );

  $$MeasurementSeriesTableFilterComposer get seriesId {
    final $$MeasurementSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.measurementSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementSeriesTableFilterComposer(
            $db: $db,
            $table: $db.measurementSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassesTableOrderingComposer
    extends Composer<_$NyooomDatabase, $PassesTable> {
  $$PassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zeit => $composableBuilder(
    column: $table.zeit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get offsetS => $composableBuilder(
    column: $table.offsetS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get richtung => $composableBuilder(
    column: $table.richtung,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get klasse => $composableBuilder(
    column: $table.klasse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get v => $composableBuilder(
    column: $table.v,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sigmaV => $composableBuilder(
    column: $table.sigmaV,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vLaufzeit => $composableBuilder(
    column: $table.vLaufzeit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vDoppler => $composableBuilder(
    column: $table.vDoppler,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kappa => $composableBuilder(
    column: $table.kappa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dEst => $composableBuilder(
    column: $table.dEst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nToene => $composableBuilder(
    column: $table.nToene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get restLaufzeit => $composableBuilder(
    column: $table.restLaufzeit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pegel => $composableBuilder(
    column: $table.pegel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dauer => $composableBuilder(
    column: $table.dauer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grund => $composableBuilder(
    column: $table.grund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grundCode => $composableBuilder(
    column: $table.grundCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get laneIndex => $composableBuilder(
    column: $table.laneIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceUsedM => $composableBuilder(
    column: $table.distanceUsedM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sigmaLaufzeit => $composableBuilder(
    column: $table.sigmaLaufzeit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sigmaDoppler => $composableBuilder(
    column: $table.sigmaDoppler,
    builder: (column) => ColumnOrderings(column),
  );

  $$MeasurementSeriesTableOrderingComposer get seriesId {
    final $$MeasurementSeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.measurementSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementSeriesTableOrderingComposer(
            $db: $db,
            $table: $db.measurementSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassesTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $PassesTable> {
  $$PassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get zeit =>
      $composableBuilder(column: $table.zeit, builder: (column) => column);

  GeneratedColumn<double> get offsetS =>
      $composableBuilder(column: $table.offsetS, builder: (column) => column);

  GeneratedColumn<int> get richtung =>
      $composableBuilder(column: $table.richtung, builder: (column) => column);

  GeneratedColumn<String> get klasse =>
      $composableBuilder(column: $table.klasse, builder: (column) => column);

  GeneratedColumn<double> get v =>
      $composableBuilder(column: $table.v, builder: (column) => column);

  GeneratedColumn<double> get sigmaV =>
      $composableBuilder(column: $table.sigmaV, builder: (column) => column);

  GeneratedColumn<double> get vLaufzeit =>
      $composableBuilder(column: $table.vLaufzeit, builder: (column) => column);

  GeneratedColumn<double> get vDoppler =>
      $composableBuilder(column: $table.vDoppler, builder: (column) => column);

  GeneratedColumn<double> get kappa =>
      $composableBuilder(column: $table.kappa, builder: (column) => column);

  GeneratedColumn<double> get dEst =>
      $composableBuilder(column: $table.dEst, builder: (column) => column);

  GeneratedColumn<int> get nToene =>
      $composableBuilder(column: $table.nToene, builder: (column) => column);

  GeneratedColumn<double> get restLaufzeit => $composableBuilder(
    column: $table.restLaufzeit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pegel =>
      $composableBuilder(column: $table.pegel, builder: (column) => column);

  GeneratedColumn<double> get dauer =>
      $composableBuilder(column: $table.dauer, builder: (column) => column);

  GeneratedColumn<String> get grund =>
      $composableBuilder(column: $table.grund, builder: (column) => column);

  GeneratedColumn<String> get grundCode =>
      $composableBuilder(column: $table.grundCode, builder: (column) => column);

  GeneratedColumn<int> get laneIndex =>
      $composableBuilder(column: $table.laneIndex, builder: (column) => column);

  GeneratedColumn<double> get distanceUsedM => $composableBuilder(
    column: $table.distanceUsedM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sigmaLaufzeit => $composableBuilder(
    column: $table.sigmaLaufzeit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sigmaDoppler => $composableBuilder(
    column: $table.sigmaDoppler,
    builder: (column) => column,
  );

  $$MeasurementSeriesTableAnnotationComposer get seriesId {
    final $$MeasurementSeriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.measurementSeries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeasurementSeriesTableAnnotationComposer(
                $db: $db,
                $table: $db.measurementSeries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PassesTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $PassesTable,
          PassRow,
          $$PassesTableFilterComposer,
          $$PassesTableOrderingComposer,
          $$PassesTableAnnotationComposer,
          $$PassesTableCreateCompanionBuilder,
          $$PassesTableUpdateCompanionBuilder,
          (PassRow, $$PassesTableReferences),
          PassRow,
          PrefetchHooks Function({bool seriesId})
        > {
  $$PassesTableTableManager(_$NyooomDatabase db, $PassesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seriesId = const Value.absent(),
                Value<int> zeit = const Value.absent(),
                Value<double> offsetS = const Value.absent(),
                Value<int> richtung = const Value.absent(),
                Value<String> klasse = const Value.absent(),
                Value<double?> v = const Value.absent(),
                Value<double?> sigmaV = const Value.absent(),
                Value<double?> vLaufzeit = const Value.absent(),
                Value<double?> vDoppler = const Value.absent(),
                Value<double?> kappa = const Value.absent(),
                Value<double?> dEst = const Value.absent(),
                Value<int> nToene = const Value.absent(),
                Value<double?> restLaufzeit = const Value.absent(),
                Value<double> pegel = const Value.absent(),
                Value<double> dauer = const Value.absent(),
                Value<String?> grund = const Value.absent(),
                Value<String?> grundCode = const Value.absent(),
                Value<int?> laneIndex = const Value.absent(),
                Value<double?> distanceUsedM = const Value.absent(),
                Value<double?> sigmaLaufzeit = const Value.absent(),
                Value<double?> sigmaDoppler = const Value.absent(),
              }) => PassesCompanion(
                id: id,
                seriesId: seriesId,
                zeit: zeit,
                offsetS: offsetS,
                richtung: richtung,
                klasse: klasse,
                v: v,
                sigmaV: sigmaV,
                vLaufzeit: vLaufzeit,
                vDoppler: vDoppler,
                kappa: kappa,
                dEst: dEst,
                nToene: nToene,
                restLaufzeit: restLaufzeit,
                pegel: pegel,
                dauer: dauer,
                grund: grund,
                grundCode: grundCode,
                laneIndex: laneIndex,
                distanceUsedM: distanceUsedM,
                sigmaLaufzeit: sigmaLaufzeit,
                sigmaDoppler: sigmaDoppler,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seriesId,
                required int zeit,
                required double offsetS,
                required int richtung,
                required String klasse,
                Value<double?> v = const Value.absent(),
                Value<double?> sigmaV = const Value.absent(),
                Value<double?> vLaufzeit = const Value.absent(),
                Value<double?> vDoppler = const Value.absent(),
                Value<double?> kappa = const Value.absent(),
                Value<double?> dEst = const Value.absent(),
                required int nToene,
                Value<double?> restLaufzeit = const Value.absent(),
                required double pegel,
                required double dauer,
                Value<String?> grund = const Value.absent(),
                Value<String?> grundCode = const Value.absent(),
                Value<int?> laneIndex = const Value.absent(),
                Value<double?> distanceUsedM = const Value.absent(),
                Value<double?> sigmaLaufzeit = const Value.absent(),
                Value<double?> sigmaDoppler = const Value.absent(),
              }) => PassesCompanion.insert(
                id: id,
                seriesId: seriesId,
                zeit: zeit,
                offsetS: offsetS,
                richtung: richtung,
                klasse: klasse,
                v: v,
                sigmaV: sigmaV,
                vLaufzeit: vLaufzeit,
                vDoppler: vDoppler,
                kappa: kappa,
                dEst: dEst,
                nToene: nToene,
                restLaufzeit: restLaufzeit,
                pegel: pegel,
                dauer: dauer,
                grund: grund,
                grundCode: grundCode,
                laneIndex: laneIndex,
                distanceUsedM: distanceUsedM,
                sigmaLaufzeit: sigmaLaufzeit,
                sigmaDoppler: sigmaDoppler,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PassesTable, PassRow>(table),
                  $$PassesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (seriesId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.seriesId,
                        referencedTable: $$PassesTableReferences._seriesIdTable(
                          db,
                        ),
                        referencedColumn: $$PassesTableReferences
                            ._seriesIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PassesTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $PassesTable,
      PassRow,
      $$PassesTableFilterComposer,
      $$PassesTableOrderingComposer,
      $$PassesTableAnnotationComposer,
      $$PassesTableCreateCompanionBuilder,
      $$PassesTableUpdateCompanionBuilder,
      (PassRow, $$PassesTableReferences),
      PassRow,
      PrefetchHooks Function({bool seriesId})
    >;
typedef $$ReferenceTracksTableCreateCompanionBuilder =
    ReferenceTracksCompanion Function({
      Value<int> id,
      required String name,
      required String source,
      Value<int?> siteId,
      required int createdAtUtcMs,
    });
typedef $$ReferenceTracksTableUpdateCompanionBuilder =
    ReferenceTracksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> source,
      Value<int?> siteId,
      Value<int> createdAtUtcMs,
    });

final class $$ReferenceTracksTableReferences
    extends
        BaseReferences<
          _$NyooomDatabase,
          $ReferenceTracksTable,
          ReferenceTrackRow
        > {
  $$ReferenceTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SitesTable _siteIdTable(_$NyooomDatabase db) =>
      db.sites.createAlias('reference_tracks__site_id__sites__id');

  $$SitesTableProcessedTableManager? get siteId {
    final $_column = $_itemColumn<int>('site_id');
    if ($_column == null) return null;
    final manager = $$SitesTableTableManager(
      $_db,
      $_db.sites,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_siteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReferencePointsTable, List<ReferencePointRow>>
  _referencePointsRefsTable(_$NyooomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.referencePoints,
        aliasName: 'reference_tracks__id__reference_points__track_id',
      );

  $$ReferencePointsTableProcessedTableManager get referencePointsRefs {
    final manager = $$ReferencePointsTableTableManager(
      $_db,
      $_db.referencePoints,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _referencePointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReferenceTracksTableFilterComposer
    extends Composer<_$NyooomDatabase, $ReferenceTracksTable> {
  $$ReferenceTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $$SitesTableFilterComposer get siteId {
    final $$SitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableFilterComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> referencePointsRefs(
    Expression<bool> Function($$ReferencePointsTableFilterComposer f) f,
  ) {
    final $$ReferencePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referencePoints,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferencePointsTableFilterComposer(
            $db: $db,
            $table: $db.referencePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReferenceTracksTableOrderingComposer
    extends Composer<_$NyooomDatabase, $ReferenceTracksTable> {
  $$ReferenceTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$SitesTableOrderingComposer get siteId {
    final $$SitesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableOrderingComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferenceTracksTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $ReferenceTracksTable> {
  $$ReferenceTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  $$SitesTableAnnotationComposer get siteId {
    final $$SitesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableAnnotationComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> referencePointsRefs<T extends Object>(
    Expression<T> Function($$ReferencePointsTableAnnotationComposer a) f,
  ) {
    final $$ReferencePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referencePoints,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferencePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.referencePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReferenceTracksTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $ReferenceTracksTable,
          ReferenceTrackRow,
          $$ReferenceTracksTableFilterComposer,
          $$ReferenceTracksTableOrderingComposer,
          $$ReferenceTracksTableAnnotationComposer,
          $$ReferenceTracksTableCreateCompanionBuilder,
          $$ReferenceTracksTableUpdateCompanionBuilder,
          (ReferenceTrackRow, $$ReferenceTracksTableReferences),
          ReferenceTrackRow,
          PrefetchHooks Function({bool siteId, bool referencePointsRefs})
        > {
  $$ReferenceTracksTableTableManager(
    _$NyooomDatabase db,
    $ReferenceTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferenceTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferenceTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferenceTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> siteId = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
              }) => ReferenceTracksCompanion(
                id: id,
                name: name,
                source: source,
                siteId: siteId,
                createdAtUtcMs: createdAtUtcMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String source,
                Value<int?> siteId = const Value.absent(),
                required int createdAtUtcMs,
              }) => ReferenceTracksCompanion.insert(
                id: id,
                name: name,
                source: source,
                siteId: siteId,
                createdAtUtcMs: createdAtUtcMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReferenceTracksTable, ReferenceTrackRow>(table),
                  $$ReferenceTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({siteId = false, referencePointsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (referencePointsRefs) db.referencePoints,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (siteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.siteId,
                            referencedTable: $$ReferenceTracksTableReferences
                                ._siteIdTable(db),
                            referencedColumn: $$ReferenceTracksTableReferences
                                ._siteIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (referencePointsRefs)
                        await $_getPrefetchedDataByColumns<
                          ReferenceTrackRow,
                          $ReferenceTracksTable,
                          ReferencePointRow,
                          $ReferencePointsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ReferenceTracksTableReferences
                              ._referencePointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReferenceTracksTableReferences(
                                db,
                                table,
                                p0,
                              ).referencePointsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReferenceTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $ReferenceTracksTable,
      ReferenceTrackRow,
      $$ReferenceTracksTableFilterComposer,
      $$ReferenceTracksTableOrderingComposer,
      $$ReferenceTracksTableAnnotationComposer,
      $$ReferenceTracksTableCreateCompanionBuilder,
      $$ReferenceTracksTableUpdateCompanionBuilder,
      (ReferenceTrackRow, $$ReferenceTracksTableReferences),
      ReferenceTrackRow,
      PrefetchHooks Function({bool siteId, bool referencePointsRefs})
    >;
typedef $$ReferencePointsTableCreateCompanionBuilder =
    ReferencePointsCompanion Function({
      Value<int> id,
      required int trackId,
      required int timeUtcMs,
      required double lat,
      required double lon,
      Value<double?> speedMs,
      Value<double?> accuracyM,
      Value<double?> speedAccuracy,
      Value<bool> speedDerived,
    });
typedef $$ReferencePointsTableUpdateCompanionBuilder =
    ReferencePointsCompanion Function({
      Value<int> id,
      Value<int> trackId,
      Value<int> timeUtcMs,
      Value<double> lat,
      Value<double> lon,
      Value<double?> speedMs,
      Value<double?> accuracyM,
      Value<double?> speedAccuracy,
      Value<bool> speedDerived,
    });

final class $$ReferencePointsTableReferences
    extends
        BaseReferences<
          _$NyooomDatabase,
          $ReferencePointsTable,
          ReferencePointRow
        > {
  $$ReferencePointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReferenceTracksTable _trackIdTable(_$NyooomDatabase db) => db
      .referenceTracks
      .createAlias('reference_points__track_id__reference_tracks__id');

  $$ReferenceTracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$ReferenceTracksTableTableManager(
      $_db,
      $_db.referenceTracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReferencePointsTableFilterComposer
    extends Composer<_$NyooomDatabase, $ReferencePointsTable> {
  $$ReferencePointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeUtcMs => $composableBuilder(
    column: $table.timeUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMs => $composableBuilder(
    column: $table.speedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedAccuracy => $composableBuilder(
    column: $table.speedAccuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get speedDerived => $composableBuilder(
    column: $table.speedDerived,
    builder: (column) => ColumnFilters(column),
  );

  $$ReferenceTracksTableFilterComposer get trackId {
    final $$ReferenceTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.referenceTracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceTracksTableFilterComposer(
            $db: $db,
            $table: $db.referenceTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferencePointsTableOrderingComposer
    extends Composer<_$NyooomDatabase, $ReferencePointsTable> {
  $$ReferencePointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeUtcMs => $composableBuilder(
    column: $table.timeUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMs => $composableBuilder(
    column: $table.speedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedAccuracy => $composableBuilder(
    column: $table.speedAccuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get speedDerived => $composableBuilder(
    column: $table.speedDerived,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReferenceTracksTableOrderingComposer get trackId {
    final $$ReferenceTracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.referenceTracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceTracksTableOrderingComposer(
            $db: $db,
            $table: $db.referenceTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferencePointsTableAnnotationComposer
    extends Composer<_$NyooomDatabase, $ReferencePointsTable> {
  $$ReferencePointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeUtcMs =>
      $composableBuilder(column: $table.timeUtcMs, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get speedMs =>
      $composableBuilder(column: $table.speedMs, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get speedAccuracy => $composableBuilder(
    column: $table.speedAccuracy,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get speedDerived => $composableBuilder(
    column: $table.speedDerived,
    builder: (column) => column,
  );

  $$ReferenceTracksTableAnnotationComposer get trackId {
    final $$ReferenceTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.referenceTracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.referenceTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferencePointsTableTableManager
    extends
        RootTableManager<
          _$NyooomDatabase,
          $ReferencePointsTable,
          ReferencePointRow,
          $$ReferencePointsTableFilterComposer,
          $$ReferencePointsTableOrderingComposer,
          $$ReferencePointsTableAnnotationComposer,
          $$ReferencePointsTableCreateCompanionBuilder,
          $$ReferencePointsTableUpdateCompanionBuilder,
          (ReferencePointRow, $$ReferencePointsTableReferences),
          ReferencePointRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$ReferencePointsTableTableManager(
    _$NyooomDatabase db,
    $ReferencePointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferencePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferencePointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferencePointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> timeUtcMs = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> speedMs = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedAccuracy = const Value.absent(),
                Value<bool> speedDerived = const Value.absent(),
              }) => ReferencePointsCompanion(
                id: id,
                trackId: trackId,
                timeUtcMs: timeUtcMs,
                lat: lat,
                lon: lon,
                speedMs: speedMs,
                accuracyM: accuracyM,
                speedAccuracy: speedAccuracy,
                speedDerived: speedDerived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                required int timeUtcMs,
                required double lat,
                required double lon,
                Value<double?> speedMs = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedAccuracy = const Value.absent(),
                Value<bool> speedDerived = const Value.absent(),
              }) => ReferencePointsCompanion.insert(
                id: id,
                trackId: trackId,
                timeUtcMs: timeUtcMs,
                lat: lat,
                lon: lon,
                speedMs: speedMs,
                accuracyM: accuracyM,
                speedAccuracy: speedAccuracy,
                speedDerived: speedDerived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReferencePointsTable, ReferencePointRow>(table),
                  $$ReferencePointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$ReferencePointsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$ReferencePointsTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReferencePointsTableProcessedTableManager =
    ProcessedTableManager<
      _$NyooomDatabase,
      $ReferencePointsTable,
      ReferencePointRow,
      $$ReferencePointsTableFilterComposer,
      $$ReferencePointsTableOrderingComposer,
      $$ReferencePointsTableAnnotationComposer,
      $$ReferencePointsTableCreateCompanionBuilder,
      $$ReferencePointsTableUpdateCompanionBuilder,
      (ReferencePointRow, $$ReferencePointsTableReferences),
      ReferencePointRow,
      PrefetchHooks Function({bool trackId})
    >;

class $NyooomDatabaseManager {
  final _$NyooomDatabase _db;
  $NyooomDatabaseManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$CalibrationsTableTableManager get calibrations =>
      $$CalibrationsTableTableManager(_db, _db.calibrations);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$LanesTableTableManager get lanes =>
      $$LanesTableTableManager(_db, _db.lanes);
  $$MeasurementSeriesTableTableManager get measurementSeries =>
      $$MeasurementSeriesTableTableManager(_db, _db.measurementSeries);
  $$PassesTableTableManager get passes =>
      $$PassesTableTableManager(_db, _db.passes);
  $$ReferenceTracksTableTableManager get referenceTracks =>
      $$ReferenceTracksTableTableManager(_db, _db.referenceTracks);
  $$ReferencePointsTableTableManager get referencePoints =>
      $$ReferencePointsTableTableManager(_db, _db.referencePoints);
}
