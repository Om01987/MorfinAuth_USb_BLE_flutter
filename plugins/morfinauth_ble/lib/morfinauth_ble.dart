import 'package:flutter/services.dart';

class MorfinauthBle {
  static const MethodChannel _channel = MethodChannel('morfinauth_ble');

  // Define Event Channels for continuous asynchronous streams
  static const EventChannel _discoveryChannel = EventChannel('morfinauth_ble/discovery');
  static const EventChannel _connectionChannel = EventChannel('morfinauth_ble/connection');
  static const EventChannel _notificationChannel = EventChannel('morfinauth_ble/notifications');

  // ==========================================
  // STREAMS (Listen to these in your UI)
  // ==========================================

  /// Stream of discovered devices (emits maps with 'name' and 'address')
  static Stream<Map<String, dynamic>> get discoveredDevicesStream {
    return _discoveryChannel.receiveBroadcastStream().map(
            (dynamic event) => Map<String, dynamic>.from(event)
    );
  }

  /// Stream of connection status (emits 'CONNECTED', 'DISCONNECTED', etc.)
  static Stream<String> get connectionStatusStream {
    return _connectionChannel.receiveBroadcastStream().map(
            (dynamic event) => event.toString()
    );
  }

  /// Stream of hardware notifications (emits 'Battery Low', 'Charger Plugged', etc.)
  static Stream<String> get hardwareNotificationStream {
    return _notificationChannel.receiveBroadcastStream().map(
            (dynamic event) => event.toString()
    );
  }

  // ==========================================
  // FUTURE METHODS (Direct Commands)
  // ==========================================

  static Future<int> discoverDevices() async {
    return await _channel.invokeMethod('discoverDevices');
  }

  static Future<int> stopDiscover() async {
    return await _channel.invokeMethod('stopDiscover');
  }

  static Future<int> connectDevice(String address) async {
    return await _channel.invokeMethod('connectDevice', {'address': address});
  }

  static Future<int> disconnect() async {
    return await _channel.invokeMethod('disconnect');
  }

  static Future<Map<String, dynamic>> initDevice(String clientKey) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('initDevice', {'clientKey': clientKey});
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  static Future<int> unInitDevice() async {
    return await _channel.invokeMethod('unInitDevice');
  }

  /// Start Capture returns a map containing status, image byte array, quality, and NFIQ
  static Future<Map<String, dynamic>> startCapture(int format, int minQuality, int timeout) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('startCapture', {
      'format': format,
      'minQuality': minQuality,
      'timeout': timeout,
    });
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  static Future<int> stopCapture() async {
    return await _channel.invokeMethod('stopCapture');
  }

  static Future<Map<String, dynamic>> getBatteryInformation() async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getBatteryInformation');
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  static Future<Map<String, dynamic>> getDeviceTimerValues() async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getDeviceTimerValues');
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  static Future<int> setDeviceTimerValues(int sleepMode, int offMode, int advertisement) async {
    return await _channel.invokeMethod('setDeviceTimerValues', {
      'sleepMode': sleepMode,
      'offMode': offMode,
      'advertisement': advertisement,
    });
  }
}