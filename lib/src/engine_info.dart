import 'format.dart';

class EngineInfo {
  int playerStatus;
  Map<String, dynamic> backgroundSettings;
  bool completed;
  Player player;

  EngineInfo(
      {this.playerStatus,
      this.player,
      this.backgroundSettings,
      this.completed});

  factory EngineInfo.fromMap(Map map) => new EngineInfo(
        playerStatus: int.parse(map['playerstatus'].toString()),
        player: new Player.fromMap(map['player']),
        backgroundSettings: map['backgroundsettings'],
        completed: map['completed'] == 'true',
      );
}

class Player {
  String userId;

  /// The characters the player currently has selected.
  Map<int, int> selected;

  String playerText;

  Map<int, Character> characters;

  Player({this.userId, this.selected, this.playerText, this.characters});

  factory Player.fromMap(Map map) {
    return new Player(
        userId: map['user_id'],
        selected: map['selected'],
        playerText: map['playertext'],
        characters:
            map['character']?.keys?.fold<Map<int, Character>>({}, (out, m) {
          var v = map['character'][m];
          return out..[m] = v == null ? v : new Character.fromMap(v);
        }));
  }
}

class Character {
  final Map<int, Skill> skills = {};
  bool unlocked;
  int characterId;
  String name, description;

  Character(
      {this.unlocked,
      this.characterId,
      this.name,
      this.description,
      Map<int, Skill> skills: const {}}) {
    this.skills.addAll(skills ?? {});
  }

  factory Character.fromMap(Map map) {
    var c = new Character(
        unlocked: map['unlocked'],
        characterId: int.parse(map['character_id']),
        name: map['name'],
        description: map['description']);

    for (var k in map.keys) {
      if (k is int) {
        c.skills[k] = new Skill.fromMap(map[k]);
      }
    }

    return c;
  }
}

class Skill {
  int skillId, cooldown;
  String name, description;
  List<String> classes;
  Map<int, int> energy;

  Skill(
      {this.skillId,
      this.cooldown,
      this.name,
      this.description,
      this.classes,
      this.energy});

  factory Skill.fromMap(Map map) {
    return new Skill(
        name: map['name'],
        skillId: int.parse(map['skill_id']),
        cooldown: int.parse(map['cooldown']),
        description: map['description'],
        classes: map['classlist']?.split(',')?.map((s) => s.trim)?.toList(),
        energy: map['energy']);
  }
}
