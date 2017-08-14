library naruto_arena.src.client;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'engine_info.dart';
import 'format.dart';
part 'game.dart';

class ArenaClient {
  static const String _endpoint = 'http://game.naruto-arena.com';

  final _CookieContainer _cookies = new _CookieContainer();
  final HttpClient _client;

  EngineInfo _engineInfo;

  ArenaClient._(this._client);

  EngineInfo get engineInfo => _engineInfo;

  static String _timestamp() => new DateTime.now().toUtc().millisecondsSinceEpoch.toString();

  static Future<ArenaClient> login(String username, String password) async {
    var client = new HttpClient();
    var arena = new ArenaClient._(client);

    // Visit game.dart page, get session id, etc.
    var rq = await client.openUrl('GET', Uri.parse('$_endpoint/index.php'));
    var rs = await rq.close();
    arena._cookies.addAll(rs.cookies);

    // Now, log in.
    rq = await client.openUrl(
        'POST', Uri.parse('$_endpoint/newengine.php?type=selection&${_timestamp()}'));
    rq
      ..headers.contentType =
          new ContentType('application', 'x-www-form-urlencoded')
      ..cookies.addAll(arena._cookies._cookies)
      ..write('username=$username&password=$password&cookie=1');
    rs = await rq.close();
    arena._cookies.addAll(rs.cookies);

    if (rs.statusCode != HttpStatus.OK)
      throw new StateError('Failed to log into Naruto Arena.');

    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['login'] != '1') throw new StateError('Invalid login; response: $data');

    var engineInfo = {}..addAll(data);
    engineInfo['player'] = NarutoArenaFormat.parseMap(data['player']);
    engineInfo['backgroundsettings'] =
        NarutoArenaFormat.parseMap(data['backgroundsettings']);
    arena._engineInfo = new EngineInfo.fromMap(engineInfo);

    return arena;
  }

  Future close() {
    _client.close(force: true);
    return new Future.value();
  }

  Future<GameRequest> requestGame(String type,
      {int char0,
      int char1,
      int char2,
      String against,
      Duration pingInterval}) async {
    char0 ??= engineInfo.player.characters[0].characterId;
    char1 ??= engineInfo.player.characters[1].characterId;
    char2 ??= engineInfo.player.characters[2].characterId;
    pingInterval ??= const Duration(seconds: 5);

    var url =
        '$_endpoint/newengine.php?type=$type&char0=$char0&char1=$char1&char2=$char2';

    if (type == 'private') url += '&username=$against';

    url += '&${_timestamp()}';

    var rq = await _client.openUrl(
      'GET',
      Uri.parse(
        url,
      ),
    );
    rq.cookies.addAll(_cookies._cookies);
    var rs = await rq.close();
    var body = await rs.transform(UTF8.decoder).join();
    var data = NarutoArenaFormat.parseAmpersand(body);

    if (data['completed'] != 'true')
      throw new StateError('Failed to request a new game.');

    return new GameRequest._(this, pingInterval);
  }
}

class _CookieContainer {
  final List<Cookie> _cookies = [];

  void add(Cookie cookie) {
    _cookies.removeWhere((c) => c.name == cookie.name);
    _cookies.add(cookie);
  }

  void addAll(Iterable<Cookie> cookies) {
    cookies.forEach(add);
  }
}
