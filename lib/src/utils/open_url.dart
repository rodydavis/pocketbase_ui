import 'package:platform_info/platform_info.dart';
import 'package:url_launcher/url_launcher.dart' hide launch;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

Future<void> openUrl(Uri url) async {
  if (platform.isMobile) {
    await launch(url.toString());
  } else {
    await launchUrl(url);
  }
}
