import 'dart:convert';
import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:html/parser.dart';
import 'package:recase/recase.dart';
import 'package:tuple/tuple.dart';

final RegExp _img = new RegExp(r'([0-9]+)/medium.jpg');

main() async {
  Map<int, Tuple2<String, String>> characters = {};
  var client = new HttpClient();
  var rq = await client.openUrl(
      'GET', Uri.parse('http://naruto-arena.com/characters-and-skills/'));
  var rs = await rq.close();
  client.close(force: true);
  var body = await rs.transform(UTF8.decoder).join();
  var $document = parse(body);

  for (var $description in $document.querySelectorAll('.description')) {
    var $img = $description.querySelector('.chardescr img');
    var $h2 = $description.querySelector('h2');

    var characterId =
        int.parse(_img.firstMatch($img.attributes['src']).group(1));
    var rawName = $h2.text.trim();
    var rc = new ReCase(rawName
        .replaceAll('(', '')
        .replaceAll(')', '')
        .split(' ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .join('_'));
    characters[characterId] = new Tuple2(rc.camelCase, rawName);
  }

  var buf = new StringBuffer();
  buf
    ..writeln('/// The various characters on Naruto-Arena.')
    ..writeln('abstract class Characters {');

  characters.forEach((k, v) {
    buf
      ..writeln('/// ${v.item2}')
      ..writeln('static const int ${v.item1} = $k;');
  });

  buf.writeln('}');
  var dart = new DartFormatter().format(buf.toString());

  await new File('lib/src/character_id.dart').writeAsString(dart);
}
