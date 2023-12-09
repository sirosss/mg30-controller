import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static String appName = '';
  static String version = '';

  static const int minTempoBPM = 40;
  static const int maxTempoBPM = 480;
  static const int minTempoMS = 1500;
  static const int maxTempoMS = 125;

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    appName = info.appName;
    version = info.version;
  }
}
