import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> launchZoomUrl(String urlStr) async {
    if (urlStr.trim().isEmpty) return;

    String cleanUrl = urlStr.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    final Uri uri = Uri.parse(cleanUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        print('URL başlatma hatası: $e');
      }
    }
  }
}
