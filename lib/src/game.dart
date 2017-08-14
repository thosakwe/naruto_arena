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

        var battleIdCookie = rs.cookies
            .firstWhere((c) => c.name == 'battle_id', orElse: () => null);

        if (battleIdCookie == null) {
          c.completeError(new StateError(
              'The server did not send a battle_id, and instead sent: $data'));
        }

        if (!c.isCompleted) c.complete(battleIdCookie.value);
      } else if (data['startmatch'] != '1') {
        timer.cancel();
        if (!c.isCompleted)
          c.completeError(new StateError(
              'Server returned invalid response when starting match: $data'));
      }
    });

    return c.future;
  }

  /// Finds a match to play against. You will likely not use this.
  Future<Game> start() async {
    var battleId = await findMatch();

    int index;
    StreamController<BattleStatus> _onStatusCheck;
    Game game;

    _onStatusCheck = new StreamController<BattleStatus>(onListen: () {
      // Don't start polling until someone is listening...
      print('Trying to start match with battle id $battleId...');
      new Timer.periodic(_interval, (timer) async {
        try {
          if (index != null) {
            timer.cancel();
            game._playerIndex = index;

            while (game._index.isNotEmpty) {
              game._index.removeFirst().complete(index);
            }

            game._start();
            return;
          }

          var rq = await _arena._client.openUrl(
            'GET',
            Uri.parse(
              '${_arena._endpoint}/newengine.php?type=startgame&${ArenaClient
                  ._timestamp()}',
            ),
          );
          rq.cookies.addAll(_arena._cookies._cookies);
          var rs = await rq.close();
          var body = await rs.transform(UTF8.decoder).join();
          var data = NarutoArenaFormat.parseAmpersand(body);

          if (data['startmatch'] != '0' && data['startmatch'] != '1') {
            timer.cancel();

            while (game._index.isNotEmpty) {
              game._index.removeFirst().completeError(new StateError(
                  'The server denied our request to start a game, with response: $data'));
            }
          } else {
            index = int.parse(data['startmatch']);
          }
        } catch (e, st) {
          _onStatusCheck.addError(e, st);
        }
      });
    });

    return game = new Game._(_arena, _interval, _onStatusCheck);
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
  final Queue<Completer<int>> _index = new Queue();
  final ArenaClient _arena;
  final Duration _interval;
  final StreamController<BattleStatus> _onStatusCheck;

  int _playerIndex;
  bool _pregame = true;
  Timer _timer;

  Game._(this._arena, this._interval, this._onStatusCheck);

  /// Fires periodically, when the status of the game is checked.
  Stream<BattleStatus> get onStatusCheck => _onStatusCheck.stream;

  void _close(String reason) {
    print('closing: $reason');
    _timer?.cancel();
    _onStatusCheck.close();

    while (_index.isNotEmpty)
      _index.removeFirst().completeError(
          new StateError('Game was closed before player index was resolved.'));
  }

  Future _ping() async {
    try {
      var rq = await _arena._client.openUrl(
        'GET',
        Uri.parse(
          '${_arena
              ._endpoint}/newengine.php?type=waiting&load=true&${ArenaClient
              ._timestamp()}',
        ),
      );
      rq.cookies.addAll(_arena._cookies._cookies);
      var rs = await rq.close();
      var body = await rs.transform(UTF8.decoder).join();
      var data = NarutoArenaFormat.parseAmpersandAll(body);

      if (data['completed'] != 'true') {
        _close('Invalid battle status: $data');
        throw new StateError('Failed to check battle status; response: $data');
      }

      var bs = new BattleStatus.fromMap(data);
      if (_pregame) _pregame = bs.battleStatus == BattleStatus.noBattle;
      if (!_pregame) {
        _onStatusCheck.add(bs);

        if (bs.battleStatus == BattleStatus.winner ||
            bs.battleStatus == BattleStatus.loser ||
            bs.battleStatus == BattleStatus.finished ||
            bs.battleStatus == BattleStatus.noBattle)
          _close('Game over; status: ${bs.battleStatus}');
      }
    } catch (e, st) {
      _onStatusCheck.addError(e, st);
    }
  }

  void _start() {
    _ping();
    _timer = new Timer.periodic(_interval, (_) => _ping());
  }

  /// The index corresponding to which player you are (`0` or `1`).
  Future<int> getPlayerIndex() {
    if (!_onStatusCheck.hasListener)
      throw new StateError(
          'Cannot fetch playerIndex until you listen to onStatusCheck.');
    if (_playerIndex != null) return new Future<int>.value(_playerIndex);
    var c = new Completer<int>();
    _index.addLast(c);
    return c.future;
  }

  /// The index of the opponent.
  Future<int> getOpponentIndex() {
    return getPlayerIndex().then((i) => i == 0 ? 1 : 0);
  }

  /// Take a turn, with the given remaining amounts of energy, and perfoming given attacks.
  Future<BattleStatus> turn(
      Map<int, int> remainingEnergy, Map<int, Map<String, int>> attack) async {
    var k = remainingEnergy.keys.toList()..sort((a, b) => b.compareTo(a));
    var energy = k.fold({}, (out, k) => out..[k] = remainingEnergy[k]);

    var rq = await _arena._client.openUrl(
      'POST',
      Uri.parse(
          '${_arena._endpoint}/newengine.php?type=calculate&load=true&${ArenaClient._timestamp()}'),
    );
    rq.headers.contentType = new ContentType('application', 'x-www-form-urlencoded');
    rq.cookies.addAll(_arena._cookies._cookies);

    var fields = {
      'e': NARUTO_ARENA.encode(energy),
      'q': NARUTO_ARENA.encode(attack)
    };

    //print(fields);

    int i = 0;
    fields.forEach((k, v) {
      if (i++ > 0) rq.add([$ampersand]);
      rq.add('$k=${Uri.encodeComponent(v)}'.codeUnits);
    });

    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersandAll(body);

    if (data['completed'] != 'true' || body.contains('badEnergyTotal')) {
      _close('Failed to take turn');
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
