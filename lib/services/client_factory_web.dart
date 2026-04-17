import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as browser;

http.Client getClient() {
  return browser.BrowserClient()..withCredentials = true;
}
