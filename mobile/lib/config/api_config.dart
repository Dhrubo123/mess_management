import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Automatically uses 10.0.2.2 on Android Emulator and 127.0.0.1 on Web/Windows/macOS.
  /// Uses port 8090 to avoid conflicts with Docker/other Laravel apps on port 8000.
  /// For a physical Android phone on Wi-Fi, replace with your PC's LAN IP (e.g. http://192.168.0.105:8090).
  static String get origin {
    if (kIsWeb) {
      return 'http://127.0.0.1:8090';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8090';
    }
    return 'http://127.0.0.1:8090';
  }

  static String get baseUrl => '$origin/api';

  static String resolveMediaUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$origin${path.startsWith('/') ? path : '/$path'}';
  }
}
