import 'dart:convert';
import 'dart:io';
import 'package:naruto_arena/naruto_arena.dart';

main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('fatal error: no input file');
    exitCode = 1;
  } else {
    var contents = await new File(args[0]).readAsString();
    var ampersand = NarutoArenaFormat.parseAmpersand(contents);
    var out = ampersand.keys.fold<Map<String, dynamic>>({}, (out, k) {
      var v = ampersand[k];

      if (v is! String)
        return out..[k] = v;

      try {
        return out..[k] = NarutoArenaFormat.parseMap(v);
      } catch (_) {
        return out..[k] = v;
      }
    });

    out = _friendlyMap(out);

    // Pretty-print JSON
    var json = const JsonEncoder.withIndent('  ').convert(out);

    stdout.write(json);
  }
}

_friendlyMap(Map map) {
  return map.keys.fold<Map>({}, (out, k) {
    var v = map[k];
    if (v is Map) v = _friendlyMap(v);

    if (k is int)
      return out..[k.toString()] = v;
    else return out..[k] = v;
  });
}