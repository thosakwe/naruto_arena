part of naruto_arena.src.client;

class BattleStatus {
  static const String loser = 'loser',
      winner = 'winner',
      playerTurn = 'playerTurn',
      opponentTurn = 'opponentTurn',
      noBattle = 'nobattle',
      finished = 'finished';

  final String battleStatus;

  final bool completed;

  // TODO: Find effects...
  final Map<int, Map<int, Map>> effects;

  final Map<int, Map<int, num>> healths;

  final Map<int, Map<int, Map<String, Map<int, int>>>> targets;

  // TODO: Find what queue is
  final Map queue;

  final Map<int, int> energy;

  final Player player0, player1;

  BattleStatus(
      {this.battleStatus,
      this.completed,
      this.effects,
      this.healths,
      this.targets,
      this.queue,
      this.energy,
      this.player0,
      this.player1});

  factory BattleStatus.fromMap(Map map) {
    return new BattleStatus(
      battleStatus: map['battlestatus'],
      completed: map['completed'] == 'true' || map['completed'] == true,
      effects: map['effects'],
      healths: map['healths'],
      targets: map['targets'],
      queue: map['queue'],
      energy: map['energy']?.keys?.fold<Map<int, int>>(
          {}, (out, k) => out..[k] = int.parse(map['energy'][k].toString())),
      player0: map.containsKey('player')
          ? new Player.fromMap(map['player'][0])
          : null,
      player1: map.containsKey('player')
          ? new Player.fromMap(map['player'][1])
          : null,
    );
  }
}

class Player {
  final Map<int, Character> characters = {};

  final String userId, username, rank, playerText;
  final int ladderRank, rankNumber, points, wins, losses, level;

  Player(
      {this.userId,
      this.username,
      this.rank,
      this.playerText,
      this.ladderRank,
      this.rankNumber,
      this.points,
      this.wins,
      this.losses,
      this.level});

  factory Player.fromMap(Map map) {
    var p = new Player(
      userId: map['user_id'],
      username: map['username'],
      rank: map['rank'],
      playerText: map['playertext'],
      ladderRank: map['ladderank'],
      rankNumber: map['ranknumber'],
      points: int.parse(map['points'].toString()),
      wins: int.parse(map['wins'].toString()),
      losses: int.parse(map['losses'].toString()),
      level: map['level'],
    );

    map.forEach((k, v) {
      if (k is int) p.characters[k] = new Character.fromMap(v);
    });

    return p;
  }
}

/// Utilities for Naruto-Arena energy (chakra).
abstract class Energy {
  static const int taijutsu = 0,
      bloodline = 1,
      ninjutsu = 2,
      genjutsu = 3,
      random = 4;

  /// Returns a `Map` suitable for using the given amounts of energy on a single turn.
  static Map<int, int> turn(
      {int taijutsu, int bloodline, int genjutsu, int any}) {
    return {
      Energy.random: any ?? 0,
      Energy.genjutsu: genjutsu ?? 0,
      Energy.ninjutsu: ninjutsu ?? 0,
      Energy.bloodline: bloodline ?? 0,
      Energy.taijutsu: taijutsu ?? 0,
    };
  }
}

abstract class Attack {
  /// Returns a map representing attack information against the other player.
  static Map<int, Map<String, int>> turn({
    @required int opponentPlayerIndex,
    @required int targetCharacterIndex,
    @required int skillIndex,
    @required int type,
  }) {
    return {
      opponentPlayerIndex: {
        // TODO: Figure out wtf 't' is
        't': type,
        'a': null,
        's': skillIndex,
        'c': targetCharacterIndex
      }
    };
  }
}

abstract class AttackType {
  static const int allEnemies = 10, oneEnemy = 12, useOnSelf = 2;
}
