import 'open_external_url_io.dart'
    if (dart.library.html) 'open_external_url_web.dart';

Future<bool> openExternalUrl(String url) => openExternalUrlImpl(url);
