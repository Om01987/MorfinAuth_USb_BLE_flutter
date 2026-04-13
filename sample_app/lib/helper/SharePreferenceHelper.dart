import 'package:shared_preferences/shared_preferences.dart';

class SharePreferenceHelper {
  SharedPreferences? prefs = null;

  SharePreferenceHelper() {
    // Obtain shared preferences.
  }

  void setDeviceInfo(String deviceInfo) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deviceInfo', deviceInfo);
  }

  Future<String?> getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await(prefs);
    String? value = prefs.getString('deviceInfo');
    return value;
  }
}
