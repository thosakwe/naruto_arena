library naruto_arena.src.bots;

import 'dart:async';
import 'client.dart';

part 'auto_surrender.dart';

/// A mechanism to automatically play Naruto-Arena games.
abstract class Bot {
  const Bot();

  /// Plays a game automatically.
  Future<bool> playGame(Game game) {
    var c = new Completer<bool>();

    game.onStatusCheck.listen(
      (status) {
        if (status.battleStatus == BattleStatus.winner)
          c.complete(true);
        else if (status.battleStatus == BattleStatus.loser)
          c.complete(false);
        else if (status.battleStatus == BattleStatus.noBattle)
          c.completeError(new StateError('You are not in a battle.'));
        else {
          new Future.sync(() => onStatusCheck(status)).then((_) {
            if (status.battleStatus == BattleStatus.playerTurn)
              return takeTurn(status, game);
          }).catchError(c.completeError);
        }
      },
      onError: c.completeError,
      onDone: () {
        if (!c.isCompleted)
          c.completeError(new StateError(
              'The server never told the bot whether it won or lost.'));
      },
    );

    return c.future;
  }

  /// Take an optional action on a status check.
  onStatusCheck(BattleStatus status) {}

  /// Makes a decision of what moves to make within a single turn.
  Future takeTurn(BattleStatus status, Game game);
}
