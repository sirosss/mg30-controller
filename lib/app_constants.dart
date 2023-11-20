import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static String appName = '';
  static String version = '';

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    appName = info.appName;
    version = info.version;
  }
}
