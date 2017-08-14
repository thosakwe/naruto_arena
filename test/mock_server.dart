import 'dart:async';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:naruto_arena/naruto_arena.dart';



/// Builds a mock Naruto-Arena server.
Future<Angel> createMockServer() async {
  var app = new Angel()..lazyParseBodies = true;

  // Add serializer
  app.before.add((ResponseContext res) {
    res.serializer = (value) {
      res.contentType = ContentType.HTML;
      return NARUTO_ARENA.encode(value);
    };

    return true;
  });

  app.get('/hello', () => {'hello': 'world'});

  app.all('/newengine.php', (RequestContext req, ResponseContext res) async {
    if (!req.query.containsKey('type'))
      throw new AngelHttpException.badRequest(message: 'Expected "type"');

  });

  app.fatalErrorStream.listen((e) {
    stderr.writeln('Fatal: ${e.error} ${e.stack}');
    e.request.response
      ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
      ..writeln('${e.error}\n\n${e.stack}')
      ..close();
  });

  return app;
}
