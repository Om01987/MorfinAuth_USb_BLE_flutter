import 'package:flutter/services.dart';

class MorfinauthUsb {
  static const MethodChannel _channel = MethodChannel('morfinauth_usb');

  static const String MORFIN_AUTH_INITIALIZATION = "initialize";
  static const String IS_DEVICE_CONNECTED = "IsDeviceConnected";
  static const String GET_ERROR_MESSAGE = "GetErrorMessage";
  static const String INIT = "Init";
  static const String INIT_WITH_LOCK = "InitWithLock";
  static const String GET_DEVICE_INFO = "GetDeviceInfo";
  static const String UNINIT = "Uninit";
  static const String GET_SDK_VERSION = 'GetSDKVersion';
  static const String SUPPORTED_DEVICES = "GetSupportedDevices";
  static const String SUPPORTED_DEVICES_COUNT = "getSupportedDevicesCount";
  static const String SUPPORTED_DEVICES_LIST = "getSupportedDevicesList";
  static const String STOP_CAPTURE = "StopCapture";
  static const String START_CAPTURE = "StartCapture";
  static const String GET_TEMPLATE = "GetTemplate";
  static const String GET_IMAGE = "GetImage";
  static const String GET_IMAGE_BASE64 = "GET_IMAGE_BASE64";
  static const String GET_IMAGE_BASE64_COPY = "GET_IMAGE_BASE64COPY";
  static const String MATCH_TEMPLATE = "MatchTemplate";
  static const String IS_CAPTURE_RUNNING = "IsCaptureRunning";
  static const String GET_TEMPLATE_BASE64_COPY = "GET_TEMPLATE_BASE64_COPY";
  static const String GET_TEMPLATE_BASE64 = "GET_TEMPLATE_BASE64";
  static const String AUTO_CAPTURE = "AutoCapture";
  static const String GET_QUALITY_ARRAY = "GetQualityArrayElement";
  static const String GET_NFIQ_ARRAY = "GetNFIQArrayElement";
  static const String GET_MATCH_SCORE = "GetMatchScore";
  static const String GET_IMAGE_ARRAY = "GetImageArrayElement";
  static const String GETGENCLIENTKEY = "getclientkey";

  static Future<void> GetFingerInitialize() async {
    return await _channel.invokeMethod(MORFIN_AUTH_INITIALIZATION);
  }

  static Future<bool> IsDeviceConnected(String deviceName) async {
    final bool deviceStatus = await _channel.invokeMethod(IS_DEVICE_CONNECTED, deviceName);
    return deviceStatus;
  }

  static Future<int> InitWithLock(String deviceName, String clientKey) async {
    final int ret = await _channel.invokeMethod(INIT_WITH_LOCK, {
      "deviceName": deviceName,
      "clientKey": clientKey,
    });
    return ret;
  }

  static Future<String> GetErrorMessage(int ret) async {
    return await _channel.invokeMethod(GET_ERROR_MESSAGE, ret);
  }

  static Future<String> GetClientKey(String clientKey) async {
    return await _channel.invokeMethod(GETGENCLIENTKEY, clientKey);
  }

  static Future<String> GetDeviceInfo() async {
    return await _channel.invokeMethod(GET_DEVICE_INFO);
  }

  static Future<int> Init(String deviceName) async {
    final int ret = await _channel.invokeMethod(INIT, deviceName);
    return ret;
  }

  static Future<int> Uninit() async {
    return await _channel.invokeMethod(UNINIT);
  }

  static Future<String> get GetSDKVersion async {
    final String version = await _channel.invokeMethod(GET_SDK_VERSION);
    return version;
  }

  static Future<int> GetSupportedDevices(List<String> supportedDevice) async {
    int ret = await _channel.invokeMethod(SUPPORTED_DEVICES, supportedDevice);
    return ret;
  }

  static Future<int> GetSupportedDevicesCount() async {
    int count = await _channel.invokeMethod(SUPPORTED_DEVICES_COUNT);
    return count;
  }

  static Future<List<String>> GetSupportedDevicesList(List<String> supportedDevice) async {
    List<dynamic> list = (await _channel.invokeMethod(SUPPORTED_DEVICES_LIST, supportedDevice));
    List<String> convert = [];
    for (int i = 0; i < list.length; i++) {
      convert.add(list[i] as String);
    }
    return convert;
  }

  static Future<int> StopCature() async {
    return await _channel.invokeMethod(STOP_CAPTURE);
  }

  static Future<bool> IsCaptureRunning() async {
    final bool iscaptureRunning = await _channel.invokeMethod(IS_CAPTURE_RUNNING);
    return iscaptureRunning;
  }

  static Future<int> StartCapture(int timeOut, int minQuality) async {
    return await _channel.invokeMethod(START_CAPTURE, <String, dynamic>{
      'timeOut': timeOut,
      'minQuality': minQuality,
    });
  }

  static Future<int> GetImage(Uint8List bImage, int size, int compressionRatio, int imageType) async {
    return await _channel.invokeMethod(GET_IMAGE, <String, dynamic>{
      'bytearray': bImage,
      'size': size,
      'compressionRatio': compressionRatio,
      'format': imageType,
    });
  }

  static Future<String> GetImageBase64() async {
    return await _channel.invokeMethod(GET_IMAGE_BASE64);
  }

  static Future<int> GetTemplate(Uint8List bImage, int size, int templateType) async {
    return await _channel.invokeMethod(GET_TEMPLATE, <String, dynamic>{
      'bytearray': bImage,
      'size': size,
      'format': templateType,
    });
  }

  static Future<int> MatchTemplate(Uint8List lastCapFingerData, Uint8List verifyImage, List<int> matchScore, int templateType) async {
    return await _channel.invokeMethod(MATCH_TEMPLATE, <String, dynamic>{
      'LastcapFingerData': lastCapFingerData,
      'VerifyImage': verifyImage,
      'matchScore': matchScore,
      'templateType': templateType,
    });
  }

  static Future<int> GetMatchScore() async {
    return await _channel.invokeMethod(GET_MATCH_SCORE);
  }

  static Future<String> GetTemplateBase64() async {
    return await _channel.invokeMethod(GET_TEMPLATE_BASE64);
  }

  static Future<int> AutoCapture(int minQuality, int timeOut, List<int> qty, List<int> nfiq) async {
    return await _channel.invokeMethod(AUTO_CAPTURE, <String, dynamic>{
      'timeOut': timeOut,
      'minQuality': minQuality,
      'qty': qty,
      'nfiq': nfiq,
    });
  }

  static Future<int> GetQualityAutoCapture() async {
    return await _channel.invokeMethod(GET_QUALITY_ARRAY);
  }

  static Future<int> GetNFIQAutoCapture() async {
    return await _channel.invokeMethod(GET_NFIQ_ARRAY);
  }

  static Future<String> GetIMAGEAutoCapture() async {
    return await _channel.invokeMethod(GET_IMAGE_ARRAY);
  }
}