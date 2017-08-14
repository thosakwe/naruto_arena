part of naruto_arena.src.bots;

/// A bot that automatically surrenders after a designated number of turns.
class AutoSurrenderBot extends Bot {
  /// The number of turns to wait before surrendering.
  final int turns;

  int _turns = 0;

  AutoSurrenderBot(this.turns);

  @override
  Future takeTurn(BattleStatus status, Game game) async {
    print('Taking turn #$_turns...');

    if (_turns++ >= turns) {
      var opponent =
          await game.getOpponentIndex().timeout(const Duration(seconds: 10));
      print('Surrendering... Opponent index is $opponent');
      return await game.surrender();
    }

    // Do nothing
    return await game.turn(
        status.energy
          ..[Energy.random] = status.energy.values.reduce((a, b) => a + b),
        {});
  }
}
