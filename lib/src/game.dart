part of naruto_arena.src.client;

class GameRequest {
  final ArenaClient _arena;
  final Duration _interval;
  Completer<Game> _onComplete = new Completer<Game>();

  GameRequest._(this._arena, this._interval) {
    scheduleMicrotask(() {
      _onComplete.complete(start());
    });
  }

  Future<Game> get onComplete => _onComplete.future;

  Future<String> findMatch() {
    var c = new Completer<String>();

    new Timer.periodic(_interval, (timer) async {
      var rq = await _arena._client.openUrl('GET',
          Uri.parse('${ArenaClient._endpoint}/newengine.php?type=search&${ArenaClient._timestamp()}'));
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

  Future<Game> start() async {
    await findMatch();

    var rq = await _arena._client.openUrl(
      'GET',
      Uri.parse(
        '${ArenaClient._endpoint}/newengine.php?type=startgame&${ArenaClient._timestamp()}',
      ),
    );
    rq.cookies.addAll(_arena._cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['startmatch'] != '0' &&  data['startmatch'] != '1')
      throw new StateError('The server denied our request to start a game, with response: $data');

    return new Game._(_arena, _interval);
  }

  Future cancel() async {
    var rq = await _arena._client.openUrl(
      'GET',
      Uri.parse(
        '${ArenaClient._endpoint}/newengine.php?type=cancel&${ArenaClient._timestamp()}',
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

class Game {
  final StreamController<GameStatus> _onStatusCheck = new StreamController<GameStatus>();
  final ArenaClient _arena;
  final Duration _interval;
  Timer _timer;

  Game._(this._arena, this._interval) {
    scheduleMicrotask(_start);
  }

  Stream<GameStatus> get onStatusCheck => _onStatusCheck.stream;

  void _close() {
    _onStatusCheck.close();
    _timer?.cancel();
  }

  void _start() {
    _timer = new Timer.periodic(_interval, (_) {
      
    });
  }

  Future surrender() async {
    var rq = await _arena._client.openUrl(
      'GET',
      Uri.parse(
        '${ArenaClient._endpoint}/newengine.php?type=surrender&${ArenaClient._timestamp()}',
      ),
    );
    rq.cookies.addAll(_arena._cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['battlestatus'] != 'loser')
      throw new StateError('Failed to surrender game; response: $data');

    _close();
  }
}

class GameStatus {
  bool _won = false, _lost = false;

  bool get won => _won;

  bool get lost => _lost;
}
