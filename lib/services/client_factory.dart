import 'package:http/http.dart' as http;
import 'client_factory_stub.dart'
    if (dart.library.js_util) 'client_factory_web.dart'
    if (dart.library.io) 'client_factory_non_web.dart';

class ClientFactory {
  static http.Client createClient() => getClient();
}
