import 'dart:typed_data';
import 'package:flutter/services.dart';

class MorfinauthBle {
  final MethodChannel _channel = const MethodChannel('morfinauth_ble');

  // Define Event Channels for continuous asynchronous streams
  final EventChannel _discoveryChannel = const EventChannel('morfinauth_ble/discovery');
  final EventChannel _connectionChannel = const EventChannel('morfinauth_ble/connection');
  final EventChannel _notificationChannel = const EventChannel('morfinauth_ble/notifications');
  final EventChannel _imageChannel = const EventChannel('morfinauth_ble/image');

  // ==========================================
  // STREAMS (Listen to these in your UI)
  // ==========================================

  /// Stream of discovered devices (emits maps with 'name' and 'address')
  Stream<Map<String, dynamic>> get discoveredDevicesStream {
    return _discoveryChannel.receiveBroadcastStream().map(
            (dynamic event) => Map<String, dynamic>.from(event)
    );
  }

  /// Stream of connection status (emits 'CONNECTED', 'DISCONNECTED', etc.)
  Stream<String> get connectionStatusStream {
    return _connectionChannel.receiveBroadcastStream().map(
            (dynamic event) => event.toString()
    );
  }

  /// Stream of hardware notifications (emits 'Battery Low', etc.)
  Stream<String> get hardwareNotificationStream {
    return _notificationChannel.receiveBroadcastStream().map(
            (dynamic event) => event.toString()
    );
  }

  /// Stream for the captured fingerprint image bytes (to display in Image.memory)
  Stream<Uint8List> get imageStream {
    return _imageChannel.receiveBroadcastStream().map(
            (dynamic event) => event as Uint8List
    );
  }

  // ==========================================
  // FUTURE METHODS (Direct Commands)
  // ==========================================

  Future<int> discoverDevices() async {
    return await _channel.invokeMethod('discoverDevices');
  }

  Future<int> stopDiscover() async {
    return await _channel.invokeMethod('stopDiscover');
  }

  Future<int> connectDevice(String address) async {
    return await _channel.invokeMethod('connectDevice', {'address': address});
  }

  Future<int> disconnect() async {
    return await _channel.invokeMethod('disconnect');
  }

  Future<Map<String, dynamic>> initDevice(String clientKey) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('initDevice', {'clientKey': clientKey});
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  Future<int> unInitDevice() async {
    return await _channel.invokeMethod('unInitDevice');
  }

  /// Start Capture command. Real image data will come through [imageStream].
  Future<Map<String, dynamic>> startCapture(int format, int minQuality, int timeout) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('startCapture', {
      'format': format,
      'minQuality': minQuality,
      'timeout': timeout,
    });
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  Future<int> stopCapture() async {
    return await _channel.invokeMethod('stopCapture');
  }

  Future<Map<String, dynamic>> getBatteryInformation() async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getBatteryInformation');
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  Future<Map<String, dynamic>> getDeviceTimerValues() async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getDeviceTimerValues');
    return result != null ? Map<String, dynamic>.from(result) : {};
  }

  Future<int> setDeviceTimerValues(int sleepMode, int offMode, int advertisement) async {
    return await _channel.invokeMethod('setDeviceTimerValues', {
      'sleepMode': sleepMode,
      'offMode': offMode,
      'advertisement': advertisement,
    });
  }
}