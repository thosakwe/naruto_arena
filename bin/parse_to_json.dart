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
      out = NarutoArenaFormat.normalizeMap(NARUTO_ARENA.decode(contents));
    else
      out = NarutoArenaFormat
          .normalizeMap(NarutoArenaFormat.parseAmpersandAll(contents));

    // Pretty-print JSON
    var json = const JsonEncoder.withIndent('  ').convert(out);

    stdout.write(json);
  }
}
