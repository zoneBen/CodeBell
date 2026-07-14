import 'package:uuid/uuid.dart';

class DeviceIdGenerator {
  static const Uuid _uuid = Uuid();

  static String generate() {
    final id = _uuid.v4().replaceAll('-', '');
    return id.substring(0, 16);
  }

  static bool isValid(String deviceId) {
    if (deviceId.length != 16) return false;
    final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumeric.hasMatch(deviceId);
  }
}
