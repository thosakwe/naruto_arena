import 'dart:io';
import 'package:naruto_arena/naruto_arena.dart';
import 'package:test/test.dart';

main() {
  Map data;

  setUp(() async {
    var contents = await new File('responses/waiting.txt').readAsString();
    data = NarutoArenaFormat.parseAmpersandAll(contents);
  });

  test('parse battle status', () {
    var bs = new BattleStatus.fromMap(data);

    expect(bs.battleStatus, BattleStatus.playerTurn);
    expect(bs.completed, isTrue);
    expect(bs.effects.keys.toList(), [0, 1]);
    expect(
      [bs.effects[0], bs.effects[1]],
      everyElement(
        equals({
          0: {},
          1: {},
          2: {},
        }),
      ),
    );

    expect(bs.healths.keys.toList(), allOf(contains(0), contains(1)));
    expect(
      [bs.healths[0], bs.healths[1]],
      everyElement(
        equals({
          0: 100,
          1: 100,
          2: 100,
        }),
      ),
    );

    expect(bs.energy.keys.toList(), [0, 1, 2, 3]);
    expect(bs.energy[Energy.taijutsu], 0);
    expect(bs.energy[Energy.bloodline], 0);
    expect(bs.energy[Energy.ninjutsu], 0);
    expect(bs.energy[Energy.genjutsu], 1);
    expect(bs.energy[Energy.random], null);

    expect(bs.targets.keys.toList(), [0, 1, 2]);

    bs.targets.forEach((k, v) {
      expect(bs.targets.keys.toList(), [0, 1, 2]);

      v.forEach((k, v) {
        expect(v.keys.toList(), ['targets', 'choice']);
      });
    });

    expect(bs.queue, {});

    var shinya = bs.player1;
    expect(shinya.username, 'shinya_yamane');
    expect(shinya.rank, 'Academy Student');
    expect(shinya.characters[1].characterId, Characters.harunoSakura);
    expect(shinya.characters[1].name, 'Haruno Sakura');
    expect(shinya.characters[1].skills[0].name, 'KO Punch');
    expect(shinya.characters[1].skills[0].classes, [
      Skill.physical,
      Skill.melee,
      Skill.instant,
    ]);
  });
}
