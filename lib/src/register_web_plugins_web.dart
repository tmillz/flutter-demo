// Web implementation — registers the iframe WebView platform so that
// YoutubePlayerController can create its NavigationDelegate without crashing.
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:youtube_player_iframe_web/src/web_youtube_player_iframe_platform.dart';

void registerWebPlugins() {
  WebViewPlatform.instance ??= WebYoutubePlayerIframePlatform();
}
