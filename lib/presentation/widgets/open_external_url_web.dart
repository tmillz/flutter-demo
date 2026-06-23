import 'package:web/web.dart' as web;

Future<bool> openExternalUrlImpl(String url) async {
  return web.window.open(url, '_blank') != null;
}
