import 'dart:convert';
import 'package:string_scanner/string_scanner.dart';
import 'package:tuple/tuple.dart';

void dumpMap(Map map) {
  map.forEach((k, v) {
    print('$k: $v\n');
  });
}

const NarutoArenaFormatCodec NARUTO_ARENA = const NarutoArenaFormatCodec._();

class NarutoArenaFormatCodec extends Codec<dynamic, String> {
  const NarutoArenaFormatCodec._();

  @override
  final Converter<dynamic, String> encoder = const _NAEncoder();

  @override
  final Converter<String, dynamic> decoder = const _NADecoder();
}

class _NAEncoder extends Converter<dynamic, String> {
  const _NAEncoder();

  @override
  String convert(input) => NarutoArenaFormat.encode(input);
}

class _NADecoder extends Converter<String, dynamic> {
  const _NADecoder();

  @override
  convert(String input) {
    return NarutoArenaFormat.parseMap(input);
  }
}

abstract class NarutoArenaFormat {
  static final RegExp _kvPair = new RegExp(r'([^=]+)=([^&\n]+)');
  static final RegExp _string = new RegExp(r'"(((\\")|([^"\n]))*)"');
  static final RegExp _type = new RegExp(r'([a-z]):(([0-9]+)(\.[0-9]+)?):?');

  static String _normalizeString(String str) => str
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t')
      .replaceAll('"', '\\"');

  static String encode(value) {
    if (value is int) return 'i:$value';

    if (value is double) return 'd:$value';

    if (value is String)
      return 's:${value.length}:"${_normalizeString(value)}"';

    if (value is bool) return 'b:' + (value ? '1' : '0');

    if (value is Map) {
      var buf = new StringBuffer('a:${value.length}:{');

      for (int i = 0; i < value.keys.length; i++) {
        var k = value.keys.elementAt(i);
        buf.write(encode(k));
        buf.write(';');
        buf.write(encode(value[k]));
        buf.write(';');
      }

      buf.write('}');
      return buf.toString();
    }

    if (value is List) return encode(value.asMap());

    if (value == null) return 'N';

    throw new UnsupportedError('Cannot serialize ${value.runtimeType}');
  }

  static Map<K, V> normalizeMap<K, V>(Map<K, V> map) {
    return map.keys.fold<Map>({}, (out, k) {
      dynamic v = map[k];
      if (v is Map) v = normalizeMap(v);

      if (k is int)
        return out..[k.toString()] = v;
      else
        return out..[k] = v;
    });
  }

  static Map<String, dynamic> parseAmpersandAll(String str) {
    var ampersand = parseAmpersand(str);
    return ampersand.keys.fold<Map<String, dynamic>>({}, (out, k) {
      var v = ampersand[k];

      if (v is! String) return out..[k] = v;

      try {
        return out..[k] = NarutoArenaFormat.parseMap(v);
      } catch (_) {
        return out..[k] = v;
      }
    });
  }

  static Map<String, String> parseAmpersand(String str) {
    var split = str.split('&').map((s) => s.trim()).where((s) => s.isNotEmpty);
    var out = {};

    for (var s in split) {
      var m = _kvPair.firstMatch(s);

      if (m == null)
        out[s] = s;
      else {
        var k = m[1], v = m[2];
        out[k] = v;
      }
    }

    return out;
  }

  static Map<String, dynamic> parseMap(String str) {
    var scanner = new StringScanner(str);
    return _parseExpression('document root', scanner);
  }

  static _following(StringScanner scanner) {
    try {
      return new String.fromCharCode(scanner.peekChar());
    } catch (_) {
      return 'end-of-file';
    }
  }

  static _parseExpression(String state, StringScanner scanner) {
    var sz = _parseType(state, scanner);

    switch (sz.item1) {
      case 's':
        return _parseString(sz.item2.toInt(), state, scanner);
      case 'a':
        return _parseMap(sz.item2.toInt(), '$state(object:${sz.item2})', scanner);
      case 'i':
        return sz.item2.toInt();
      case 'd':
        return sz.item2;
      case 'b':
        return sz.item2 == 1;
      case 'N':
        return null;
      default:
        throw new FormatException(
            'Unrecognized data type: "${sz.item1}:${sz.item2}"');
    }
  }

  static Tuple2<String, double> _parseType(String state, StringScanner scanner) {
    if (scanner.scan('N')) {
      return new Tuple2('N', double.NAN);
    }

    scanner.expect(_type,
        name: 'data type within $state, found "${_following(scanner)}"');
    return new Tuple2(scanner.lastMatch[1], double.parse(scanner.lastMatch[2]));
  }

  static String _parseString(int length, String state, StringScanner scanner) {
    scanner.expect(_string, name: 'string');
    var s = scanner.lastMatch[1];
    /*
    if (s.length != length)
      throw new FormatException(
          'Expected string of length $length in $state, found "$s" (length: ${s.length}) instead');
    */
    return s
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAll('\\"', '"');
  }

  static Map<String, dynamic> _parseMap(
      int length, String state, StringScanner scanner) {
    var out = {};
    scanner.expect('{');

    for (int i = 0; i < length; i++) {
      var kv = _parseKeyValuePair(state, scanner);
      //print('${kv.item1} => ${kv.item2}');
      out[kv.item1] = kv.item2;
      scanner.scan(';');
      //scanner.expect(';', name: 'semicolon after ${kv.item1}=${kv.item2} in $state, found "${_following(scanner)}"');
    }

    scanner.expect('}');

    return out;
  }

  static Tuple2 _parseKeyValuePair(String state, StringScanner scanner) {
    var k = _parseExpression(state, scanner);
    scanner.expect(';',
        name:
            'semicolon after value of key $k in $state, found "${_following(scanner)}"');
    var v = _parseExpression('$state->$k', scanner);
    return new Tuple2(k, v);
  }
}
