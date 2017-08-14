class EngineInfo {
  int playerStatus;
  Map<String, dynamic> backgroundSettings;
  bool completed;
  CharacterSelection characterSelection;

  EngineInfo(
      {this.playerStatus,
      this.characterSelection,
      this.backgroundSettings,
      this.completed});

  factory EngineInfo.fromMap(Map map) => new EngineInfo(
        playerStatus: int.parse(map['playerstatus'].toString()),
        characterSelection: new CharacterSelection.fromMap(map['player']),
        backgroundSettings: map['backgroundsettings'],
        completed: map['completed'] == 'true',
      );
}

class CharacterSelection {
  String userId;

  /// The characters the player currently has selected.
  Map<int, int> selected;

  String playerText;

  Map<int, Character> characters;

  CharacterSelection(
      {this.userId, this.selected, this.playerText, this.characters});

  factory CharacterSelection.fromMap(Map map) {
    return new CharacterSelection(
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
  static const String physical = 'Physical',
      melee = 'Melee',
      instant = 'Instant',
      chakra = 'Chakra',
      mental = 'Mental',
      unique = 'Unique',
      ranged = 'Ranged';

  int skillId, cooldown, maxHealth;
  String name, description;
  List<String> classes;
  Map<int, int> energy;

  Skill(
      {this.skillId,
      this.cooldown,
      this.maxHealth,
      this.name,
      this.description,
      this.classes,
      this.energy});

  factory Skill.fromMap(Map map) {
    return new Skill(
        name: map['name'],
        skillId: int.parse(map['skill_id']),
        cooldown:
            map.containsKey('cooldown') ? int.parse(map['cooldown']) : null,
        maxHealth:
            map.containsKey('maxhealth') ? int.parse(map['maxhealth']) : null,
        description: map['description'],
        classes: map['classlist']?.split(',')?.map((s) => s.trim())?.toList(),
        energy: map['energy']);
  }
}
