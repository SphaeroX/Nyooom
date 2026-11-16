import 'dart:convert';
import 'dart:typed_data';

/// CRC-32 (IEEE) as used by ZIP.
class Crc32 {
  static final Uint32List _table = () {
    final t = Uint32List(256);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
      t[n] = c;
    }
    return t;
  }();

  int _crc = 0xFFFFFFFF;

  void add(List<int> bytes) {
    var c = _crc;
    for (final b in bytes) {
      c = _table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    _crc = c;
  }

  int get value => _crc ^ 0xFFFFFFFF;

  static int of(List<int> bytes) => (Crc32()..add(bytes)).value;
}

/// One file of a ZIP archive (for the central directory).
class ZipEntry {
  ZipEntry(this.name, this.crc, this.size, this.offset);
  final List<int> name;
  final int crc;
  final int size;
  final int offset;
}

/// Minimal ZIP writer without compression ("stored"); enough for CSV, JSON
/// and WAV (audio barely compresses). Sizes below 4 GB (no ZIP64).
class ZipWriter {
  final BytesBuilder _out = BytesBuilder(copy: false);
  final List<ZipEntry> _entries = [];

  void addFile(String name, List<int> data) {
    final nameBytes = utf8.encode(name);
    final crc = Crc32.of(data);
    final offset = _out.length;
    _out.add(localHeader(nameBytes, crc, data.length));
    _out.add(data);
    _entries.add(ZipEntry(nameBytes, crc, data.length, offset));
  }

  /// Local file header (method 0, UTF-8 names).
  static Uint8List localHeader(List<int> name, int crc, int size) {
    final h = ByteData(30);
    h.setUint32(0, 0x04034b50, Endian.little);
    h.setUint16(4, 20, Endian.little); // version needed
    h.setUint16(6, 0x0800, Endian.little); // UTF-8
    h.setUint16(8, 0, Endian.little); // stored
    h.setUint16(10, 0, Endian.little); // time
    h.setUint16(12, 0x21, Endian.little); // date 1980-01-01
    h.setUint32(14, crc, Endian.little);
    h.setUint32(18, size, Endian.little);
    h.setUint32(22, size, Endian.little);
    h.setUint16(26, name.length, Endian.little);
    h.setUint16(28, 0, Endian.little);
    return Uint8List.fromList([...h.buffer.asUint8List(), ...name]);
  }

  Uint8List finish() {
    _out.add(centralDirectory(_entries, _out.length));
    return _out.takeBytes();
  }

  /// Central directory plus end record for [entries], starting at byte
  /// [centralStart] of the archive.
  static Uint8List centralDirectory(List<ZipEntry> entries, int centralStart) {
    final out = BytesBuilder(copy: false);
    for (final e in entries) {
      final h = ByteData(46);
      h.setUint32(0, 0x02014b50, Endian.little);
      h.setUint16(4, 20, Endian.little);
      h.setUint16(6, 20, Endian.little);
      h.setUint16(8, 0x0800, Endian.little);
      h.setUint16(10, 0, Endian.little);
      h.setUint16(12, 0, Endian.little);
      h.setUint16(14, 0x21, Endian.little);
      h.setUint32(16, e.crc, Endian.little);
      h.setUint32(20, e.size, Endian.little);
      h.setUint32(24, e.size, Endian.little);
      h.setUint16(28, e.name.length, Endian.little);
      h.setUint32(42, e.offset, Endian.little);
      out.add(h.buffer.asUint8List());
      out.add(e.name);
    }
    final centralSize = out.length;
    final end = ByteData(22);
    end.setUint32(0, 0x06054b50, Endian.little);
    end.setUint16(8, entries.length, Endian.little);
    end.setUint16(10, entries.length, Endian.little);
    end.setUint32(12, centralSize, Endian.little);
    end.setUint32(16, centralStart, Endian.little);
    out.add(end.buffer.asUint8List());
    return out.takeBytes();
  }
}
