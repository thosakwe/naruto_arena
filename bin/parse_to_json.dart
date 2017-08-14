import 'dart:convert';
import 'dart:io';
import 'package:naruto_arena/naruto_arena.dart';

main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('fatal error: no input file');
    exitCode = 1;
  } else {
    var contents = await new File(args[0]).readAsString();
    Map out;

    if (args.contains('--plain'))
      out = NARUTO_ARENA.decode(contents);
    else
      out = NarutoArenaFormat.parseAmpersandAll(contents);

    if (args.contains('--raw'))
      stdout.write(out);
    else {
      out = NarutoArenaFormat.normalizeMap(out);

      // Pretty-print JSON
      var json = const JsonEncoder.withIndent('  ').convert(out);

      stdout.write(json);
    }
  }
}
