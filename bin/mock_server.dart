import 'dart:io';
import '../test/mock_server.dart';

main() async {
  var app = await createMockServer();
  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  print('Mock Naruto-Arena server listening at http://${server.address.address}:${server.port}');
}