part of naruto_arena.src.bots;

/// A bot that automatically surrenders after a designated number of turns.
class AutoSurrenderBot extends Bot {
  /// The number of turns to wait before surrendering.
  final int turns;

  int _turns = 0;

  AutoSurrenderBot(this.turns);

  @override
  Future takeTurn(BattleStatus status, Game game) {
    print('Taking turn #$_turns...');
    if (_turns++ >= turns) return game.surrender();
    return game.turn(Energy.turn(), {});
  }
}
