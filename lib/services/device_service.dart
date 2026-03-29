import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Mendapatkan Device ID dan Name berdasarkan Platform
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id, // Unique ID hardware Android
          'deviceName': '${androidInfo.brand} ${androidInfo.model}', // Contoh: Samsung SM-G998B
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'Unknown', // Unique ID iOS
          'deviceName': iosInfo.name, // Contoh: iPhone 14 Pro Max
        };
      } else {
        // Fallback kalo dicoba di Web atau Desktop saat debugging
        return {
          'deviceId': 'Unknown_Device_ID',
          'deviceName': 'Unknown_Device_Name',
        };
      }
    } catch (e) {
      return {
        'deviceId': 'Error',
        'deviceName': e.toString(),
      };
    }
  }
}
