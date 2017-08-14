import 'package:string_scanner/string_scanner.dart';
import 'package:tuple/tuple.dart';

void dumpMap(Map map) {
  map.forEach((k, v) {
    print('$k: $v\n');
  });
}

abstract class NarutoArenaFormat {
  static final RegExp _kvPair = new RegExp(r'([^=]+)=([^&\n]+)');
  static final RegExp _string = new RegExp(r'"(((\\")|([^"\n]))*)"');
  static final RegExp _type = new RegExp(r'([a-z]):([0-9]+):?');

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
        return _parseString(sz.item2, state, scanner);
      case 'a':
        return _parseMap(sz.item2, '$state(object:${sz.item2})', scanner);
      case 'i':
        return sz.item2;
      case 'b':
        return sz.item2 == 1;
      default:
        throw new FormatException(
            'Unrecognized data type: "${sz.item1}:${sz.item2}"');
    }
  }

  static Tuple2<String, int> _parseType(String state, StringScanner scanner) {
    scanner.expect(_type,
        name: 'data type within $state, found "${_following(scanner)}"');
    return new Tuple2(scanner.lastMatch[1], int.parse(scanner.lastMatch[2]));
  }

  static String _parseString(int length, String state, StringScanner scanner) {
    scanner.expect(_string, name: 'string');
    var s = scanner.lastMatch[1];
    /*
    if (s.length != length)
      throw new FormatException(
          'Expected string of length $length in $state, found "$s" (length: ${s.length}) instead');
    */
    return s;
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
