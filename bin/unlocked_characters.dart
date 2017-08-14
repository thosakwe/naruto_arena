import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:naruto_arena/naruto_arena.dart';

main() async {
  dotenv.load();
  String username = dotenv.env['NA_USERNAME'], password = dotenv.env['NA_PASSWORD'];
  var arena = await ArenaClient.login(username, password);
  arena.close();

  var unlocked = arena.engineInfo.player.characters.values.where((c) => c.unlocked);

  print('Unlocked characters (${unlocked.length}):');

  for (var c in unlocked)
    print('  * ${c.name} (${c.skills.values.map((s) => s.name).join(', ')})');
}