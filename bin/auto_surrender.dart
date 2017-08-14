import 'dart:async';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:naruto_arena/naruto_arena.dart';

main() async {
  dotenv.load();
  String username = dotenv.env['NA_USERNAME'], password = dotenv.env['NA_PASSWORD'], username2 = dotenv.env['NA_USERNAME2'];
  var arena = await ArenaClient.login(username, password);

  print('Trying to start private game against $username2...');
  var gameRequest = await arena.requestGame('private', against: username2);
  var game = await gameRequest.onComplete.timeout(const Duration(minutes: 10));

  print('Game started. Surrendering in 10 seconds...');
  await new Future.delayed(const Duration(seconds: 10));
  await game.surrender();

  print('Surrendered to $username2!!!');

  arena.close();
}