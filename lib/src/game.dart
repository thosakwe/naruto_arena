part of naruto_arena.src.client;

/// A request to start a Naruto-Arena game.
class GameRequest {
  final ArenaClient _arena;
  final Duration _interval;
  Completer<Game> _onComplete = new Completer<Game>();

  GameRequest._(this._arena, this._interval) {
    scheduleMicrotask(() {
      _onComplete.complete(start());
    });
  }

  /// Completes once a match has made, and a game has begun.
  Future<Game> get onComplete => _onComplete.future;

  /// Finds a player to play against, and returns the `battle_id` returned from the server.
  Future<String> findMatch() {
    var c = new Completer<String>();

    new Timer.periodic(_interval, (timer) async {
      var rq = await _arena._client.openUrl(
          'GET',
          Uri.parse(
              '${_arena._endpoint}/newengine.php?type=search&${ArenaClient._timestamp()}'));
      rq.cookies.addAll(_arena._cookies._cookies);
      var rs = await rq.close();
      _arena._cookies.addAll(rs.cookies);
      var body = await rs.transform(UTF8.decoder).join();
      var data = NarutoArenaFormat.parseAmpersand(body);

      if (data['startmatch'] == '2') {
        timer.cancel();
        if (!c.isCompleted)
          c.complete(rs.cookies.firstWhere((c) => c.name == 'battle_id').value);
      }
    });

    return c.future;
  }

  /// Finds a match to play against. You will likely not use this.
  Future<Game> start() async {
    await findMatch();

    var rq = await _arena._client.openUrl(
      'GET',
      Uri.parse(
        '${_arena._endpoint}/newengine.php?type=startgame&${ArenaClient._timestamp()}',
      ),
    );
    rq.cookies.addAll(_arena._cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['startmatch'] != '0' && data['startmatch'] != '1')
      throw new StateError(
          'The server denied our request to start a game, with response: $data');

    return new Game._(int.parse(data['startmatch']), _arena, _interval);
  }

  /// Cancels the game request.
  Future cancel() async {
    var rq = await _arena._client.openUrl(
      'GET',
      Uri.parse(
        '${_arena._endpoint}/newengine.php?type=cancel&${ArenaClient._timestamp()}',
      ),
    );
    rq.cookies.addAll(_arena._cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['completed'] != 'true')
      throw new StateError('Failed to cancel game request; response: $data');
  }
}

/// Represents a Naruto-Arena game.
class Game {
  final StreamController<BattleStatus> _onStatusCheck =
      new StreamController<BattleStatus>();
  final ArenaClient _arena;
  final Duration _interval;

  /// The index corresponding to which player you are (`0` or `1`).
  final int playerIndex;

  Timer _timer;

  Game._(this.playerIndex, this._arena, this._interval) {
    _start();
  }

  /// Fires periodically, when the status of the game is checked.
  Stream<BattleStatus> get onStatusCheck => _onStatusCheck.stream;

  void _close() {
    _onStatusCheck.close();
    _timer?.cancel();
  }

  void _start() {
    _timer = new Timer.periodic(_interval, (_) async {
      var rq = await _arena._client.openUrl(
        'GET',
        Uri.parse(
          '${_arena._endpoint}/newengine.php?type=waiting&load=true&${ArenaClient._timestamp()}',
        ),
      );
      rq.cookies.addAll(_arena._cookies._cookies);
      var rs = await rq.close();
      var body = await rs.transform(UTF8.decoder).join();
      var data = NarutoArenaFormat.parseAmpersandAll(body);

      if (data['completed'] != 'true') {
        _close();
        throw new StateError('Failed to check battle status; response: $data');
      }

      try {
        var bs = new BattleStatus.fromMap(data);
        _onStatusCheck.add(bs);

        if (bs.battleStatus == BattleStatus.winner ||
            bs.battleStatus == BattleStatus.loser ||
            bs.battleStatus == BattleStatus.noBattle) _close();
      } catch (e) {
        print('Server sent invalid data when polling: $data');
      }
    });
  }

  /// Take a turn, spending the designated amounts of energy, and perfoming given attacks.
  Future<BattleStatus> turn(Map<int, int> energy, Map<int, Map<String, int>> attack) async {
    var timestamp = ArenaClient._timestamp();

    var queryParameters = {
      'type': 'calculate',
      'load': 'true',
      timestamp: timestamp,
      'e': NARUTO_ARENA.encode(energy),
      'q': NARUTO_ARENA.encode(attack)
    };

    var rq = await _arena._client.openUrl(
      'GET',
      Uri
          .parse(_arena._endpoint)
          .replace(path: 'newengine.php', queryParameters: queryParameters),
    );
    rq.cookies.addAll(_arena._cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersandAll(body);

    if (data['completed'] != 'true') {
      _close();
      throw new StateError('Failed to take turn; response: $data');
    }

    if (data['healths'] is String)
      data['healths'] = NARUTO_ARENA.decode(data['healths']);

    return new BattleStatus.fromMap(data);
  }

  /// Surrenders this match to the other player.
  Future surrender() async {
    var rq = await _arena._client.openUrl(
      'GET',
      Uri.parse(
        '${_arena._endpoint}/newengine.php?type=surrender&${ArenaClient._timestamp()}',
      ),
    );
    rq.cookies.addAll(_arena._cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['battlestatus'] != 'loser')
      throw new StateError('Failed to surrender game; response: $data');
  }
}
