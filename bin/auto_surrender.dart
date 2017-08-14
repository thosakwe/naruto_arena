import 'dart:async';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:naruto_arena/naruto_arena.dart';

const Duration pingInterval = const Duration(seconds: 1),
    timeout = const Duration(minutes: 3),
    surrenderWait = const Duration(seconds: 7);

/// This bot will quit after *completing* two turns.
main() async {
  dotenv.load();
  String username = dotenv.env['NA_USERNAME'],
      password = dotenv.env['NA_PASSWORD'],
      username2 = dotenv.env['NA_USERNAME2'];
  var arena = await ArenaClient.login(username, password);
  Game game;

  if (arena.engineInfo.playerStatus == PlayerStatus.selectionScreen) {
    print('Trying to start private game against $username2...');
    var gameRequest = await arena.requestGame(
      'private',
      against: username2,
      char0: Characters.rockLee,
      char1: Characters.inuzukaKiba,
      char2: Characters.naraShikaku,
      pingInterval: pingInterval,
    );

    game = await gameRequest.onComplete.timeout(timeout);
  } else if (arena.engineInfo.playerStatus == PlayerStatus.inGame) {
    print('Resuming current game...');
    game = await arena.reEnterCurrentGame(pingInterval).timeout(timeout);
  }

  print(
      'Game started. Starting auto-surrender bot in ${surrenderWait.inSeconds} second(s)...');
  await new Future.delayed(surrenderWait);

  print('Auto-surrender bot started.');
  var bot = new AutoSurrenderBot(3);

  try {
    if (!await bot.playGame(game).timeout(timeout))
      print('Surrendered to $username2!!!');
    else
      print('... You won...? Perhaps the other user surrendered.');
  } finally {
    var notes = await arena.getGameStats();
    print('Stats: $notes');
    arena.close();
  }
}
