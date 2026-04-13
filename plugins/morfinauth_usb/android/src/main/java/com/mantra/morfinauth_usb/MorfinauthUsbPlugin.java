package com.mantra.morfinauth_usb;

import android.content.Context;
import androidx.annotation.NonNull;

import com.mantra.morfinauth.DeviceInfo;
import com.mantra.morfinauth.enums.DeviceDetection;
import com.mantra.morfinauth.enums.DeviceModel;
import com.mantra.morfinauth.enums.ImageFormat;
import com.mantra.morfinauth.enums.TemplateFormat;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MorfinauthUsbPlugin implements FlutterPlugin, MethodCallHandler, PluginCallBack {
  private MethodChannel channel;
  private CustomMethodChannel callBack_Channel;
  private MorfinAuthInitialization morfinAuthInitialization = null;
  private String CALLBACK_CHANNEL = "PassedCallBack";
  private String METHOD_COMPLETE = "complete";
  private String MORFIN_AUTH_INITIALIZATION = "initialize";

  // IMPORTANT: This was changed to match your new Dart plugin name
  private String METHOD_CHANNEL_NAME = "morfinauth_usb";

  private String GET_CONNECTED_DEVICES = "GetConnectedDevices";
  private String GET_SUPPORTED_DEVICES = "GetSupportedDevices";
  private String INIT = "Init";
  private String INIT_WITH_LOCK = "InitWithLock";
  private String UNINIT = "Uninit";
  private String GET_SDK_VERSION = "GetSDKVersion";
  private String IS_DEVICE_CONNECTED = "IsDeviceConnected";
  private String START_CAPTURE = "StartCapture";
  private String AUTO_CAPTURE = "AutoCapture";
  private String STOP_CAPTURE = "StopCapture";
  private String IS_CAPTURE_RUNNING = "IsCaptureRunning";
  private String GET_IMAGE = "GetImage";
  private String GET_TEMPLATE = "GetTemplate";
  private String MATCH_TEMPLATE = "MatchTemplate";
  private String GET_ERROR_MESSAGE = "GetErrorMessage";
  private String GET_DEVICE_INFO = "GetDeviceInfo";
  private String METHOD_GET_IMAGE_BASE64 = "GET_IMAGE_BASE64";
  private String GET_TEMPLATE_BASE64_COPY = "GET_TEMPLATE_BASE64_COPY";
  private String METHOD_GET_MATCH_SCORE = "GetMatchScore";
  private String METHOD_GET_TEMPLATE_BASE64 = "GET_TEMPLATE_BASE64";
  private String METHOD_GET_TEMPLATE_BASE64_COPY = "GET_TEMPLATE_BASE64_COPY";
  private String METHOD_GET_QUALITY_ARRAY = "GetQualityArrayElement";
  private String METHOD_GET_NFIQ_ARRAY = "GetNFIQArrayElement";
  private String METHOD_GET_IMAGE_ARRAY = "GetImageArrayElement";
  private String METHOD_DEVICE_DETECTION = "Device_Detection";
  private String METHOD_PREVIEW = "preview";
  private String SUPPORTED_DEVICES_LIST = "getSupportedDevicesList";
  private String SUPPORTED_DEVICES_COUNT = "getSupportedDevicesCount";

  private Context context;
  List<String> connectedDevices;
  int qualityElementValue = 0;
  int nfiqElementValue = 0;
  String base64ImageElementValue = null;
  String base64Image = null;
  String base64Template = null;
  String base64TemplateCopy = null;
  String Genratedclientkey = null;
  int matchScoreValue = 0;
  private List<String> supportedList;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
    channel.setMethodCallHandler(this);
    callBack_Channel = new CustomMethodChannel(flutterPluginBinding.getBinaryMessenger(), CALLBACK_CHANNEL);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals(MORFIN_AUTH_INITIALIZATION)) {
      morfinAuthInitialization = new MorfinAuthInitialization(context, this);
    } else if (call.method.equals(GET_SDK_VERSION)) {
      String sdkVersion =  GetSDKVersion();
      result.success(sdkVersion);
    } else if (call.method.equals(GET_SUPPORTED_DEVICES)) {
      List<String> supportedList = call.arguments();
      int ret = GetSupportedDevices(supportedList);
      result.success(ret);
    } else if (call.method.equals(SUPPORTED_DEVICES_COUNT)) {
      int count = GetSupportedDeviceListCount();
      result.success(count);
    } else if (call.method.equals(SUPPORTED_DEVICES_LIST)) {
      List<String> supportedList = GetSupportedDeviceList();
      result.success(supportedList);
    } else if (call.method.equals(GET_CONNECTED_DEVICES)) {
      int supportedList = GetConnectedDevices(connectedDevices);
      result.success(supportedList);
    } else if (call.method.equals(IS_DEVICE_CONNECTED)) {
      String devicename = call.arguments();
      if (devicename != null && !devicename.isEmpty()) {
        DeviceModel name = DeviceModel.valueFor(devicename);
        boolean isConnected = IsDeviceConnected(name);
        result.success(isConnected);
      }
    } else if (call.method.equals(GET_ERROR_MESSAGE)) {
      int ret = call.arguments();
      String Error = morfinAuthInitialization.GetErrorMessage(ret);
      result.success(Error);
    } else if (call.method.equals(INIT_WITH_LOCK)) {
      System.out.println("Entered in INIT_WITH_LOCK");
      String deviceName = call.argument("deviceName");
      String clientKey = call.argument("clientKey");
      DeviceModel name = DeviceModel.valueFor(deviceName);
      DeviceInfo deviceInfo = new DeviceInfo();
      System.out.println("Device Name :: "+name+" Client Key :: "+clientKey+" deviceInfo :: "+deviceInfo);
      int ret = InitWithLock(name ,clientKey,deviceInfo);
      if (ret != 0) {
        result.error("INIT ERROR", morfinAuthInitialization.GetErrorMessage(ret), null);
      } else {
        result.success(ret);
      }
    } else if (call.method.equals(GET_DEVICE_INFO)) {
      DeviceInfo deviceInfo = GetDeviceInfo();
      HashMap<String, Object> hashMap = new HashMap<>();
      hashMap.put("SerialNo", deviceInfo.SerialNo);
      hashMap.put("Make", deviceInfo.Make);
      hashMap.put("Model", deviceInfo.Model);
      hashMap.put("Width", deviceInfo.Width);
      hashMap.put("Height", deviceInfo.Height);
      hashMap.put("Firmware", deviceInfo.Firmware);
      hashMap.put("DPI", deviceInfo.DPI);
      result.success(new JSONObject(hashMap).toString());
    } else if (call.method.equals(UNINIT)) {
      result.success(Uninit());
    } else if (call.method.equals(STOP_CAPTURE)) {
      result.success(StopCapture());
    } else if (call.method.equals(IS_CAPTURE_RUNNING)) {
      boolean isCaptureRunning = IsCaptureRunning();
      result.success(isCaptureRunning);
    } else if (call.method.equals(START_CAPTURE)) {
      int timeout = call.argument("timeOut");
      int minQuality = call.argument("minQuality");
      int ret = StartCapture(minQuality, timeout);
      result.success(ret);
    } else if (call.method.equals(GET_TEMPLATE)) {
      int size = call.argument("size");
      int template = call.argument("format");
      byte[] bytearray = new byte[size];
      int[] tSize = new int[size];
      TemplateFormat templateValue;
      if (template == TemplateFormat.FMR_V2005.ordinal()) {
        templateValue = TemplateFormat.FMR_V2005;
      } else if (template == TemplateFormat.FMR_V2011.ordinal()) {
        templateValue = TemplateFormat.FMR_V2011;
      } else {
        templateValue = TemplateFormat.ANSI_V378;
      }
      System.out.println("=====size " + size);
      System.out.println("=====template " + template);
      System.out.println("=====template value asasasasas " + templateValue);
      int ret = GetTemplate(bytearray, tSize, templateValue);
      result.success(ret);
    } else if (call.method.equals(METHOD_GET_TEMPLATE_BASE64)) {
      result.success(GetTemplateBase64());
    } else if (call.method.equals(METHOD_GET_TEMPLATE_BASE64_COPY)) {
      result.success(GetTemplateBase64Copy());
    } else if (call.method.equals(AUTO_CAPTURE)) {
      int timeout = call.argument("timeOut");
      int minQuality = call.argument("minQuality");
      int[] qualityArray = new int[1];
      int[] NFIQ = new int[1];
      int ret = AutoCapture(minQuality, timeout, qualityArray, NFIQ);
      qualityElementValue = qualityArray[0];
      nfiqElementValue = NFIQ[0];
      base64ImageElementValue = ShowFinalFinger();
      result.success(ret);
    } else if (call.method.equals(METHOD_GET_QUALITY_ARRAY)) {
      int value = GetQualityAutoCapture();
      result.success(value);
    } else if (call.method.equals(METHOD_GET_NFIQ_ARRAY)) {
      int value = GetNFIQAutoCapture();
      result.success(value);
    } else if (call.method.equals(METHOD_GET_IMAGE_ARRAY)) {
      String value = GetImageAutoCapture();
      result.success(value);
    } else if (call.method.equals(MATCH_TEMPLATE)) {
      byte[] LastcapFingerData = call.argument("LastcapFingerData");
      byte[] verifyFingerData = call.argument("VerifyImage");
      int[] matchScore = new int[1];
      int templateType = call.argument("templateType");
      TemplateFormat templateFormat = null;
      if (templateType == TemplateFormat.FMR_V2011.ordinal()) {
        templateFormat = TemplateFormat.FMR_V2011;
      } else if (templateType == TemplateFormat.FMR_V2005.ordinal()) {
        templateFormat = TemplateFormat.FMR_V2005;
      } else if (templateType == TemplateFormat.ANSI_V378.ordinal()) {
        templateFormat = TemplateFormat.ANSI_V378;
      }
      int ret = MatchTemplate(LastcapFingerData, verifyFingerData, matchScore, templateFormat);
      result.success(ret);
    } else if (call.method.equals(GET_IMAGE)) {
      int size = call.argument("size");
      byte[] image = call.argument("bytearray");
      int compressionRatio = call.argument("compressionRatio");
      int format = call.argument("format");
      int[] intArray = new int[1];
      ImageFormat imageFormatEnum = null;
      if (format == ImageFormat.BMP.ordinal()) {
        imageFormatEnum = ImageFormat.BMP;
      } else if (format == ImageFormat.JPEG2000.ordinal()) {
        imageFormatEnum = ImageFormat.JPEG2000;
      } else if (format == ImageFormat.WSQ.ordinal()) {
        imageFormatEnum = ImageFormat.WSQ;
      } else if (format == ImageFormat.RAW.ordinal()) {
        imageFormatEnum = ImageFormat.RAW;
      } else if (format == ImageFormat.FIR_V2005.ordinal()) {
        imageFormatEnum = ImageFormat.FIR_V2005;
      } else if (format == ImageFormat.FIR_V2011.ordinal()) {
        imageFormatEnum = ImageFormat.FIR_V2011;
      } else if (format == ImageFormat.FIR_WSQ_V2005.ordinal()) {
        imageFormatEnum = ImageFormat.FIR_WSQ_V2005;
      } else if (format == ImageFormat.FIR_WSQ_V2011.ordinal()) {
        imageFormatEnum = ImageFormat.FIR_WSQ_V2011;
      } else if (format == ImageFormat.FIR_JPEG2000_V2005.ordinal()) {
        imageFormatEnum = ImageFormat.FIR_JPEG2000_V2005;
      } else if (format == ImageFormat.FIR_JPEG2000_V2011.ordinal()) {
        imageFormatEnum = ImageFormat.FIR_JPEG2000_V2011;
      } else {
        imageFormatEnum = ImageFormat.BMP;
      }
      int ret = GetImage(image, intArray, compressionRatio, imageFormatEnum);
      result.success(ret);
    } else if (call.method.equals(METHOD_GET_IMAGE_BASE64)) {
      result.success(GetImageBase64());
    } else if (call.method.equals(GET_TEMPLATE_BASE64_COPY)) {
      result.success(GetTemplateBase64Copy());
    } else if (call.method.equals(METHOD_GET_MATCH_SCORE)) {
      int score = GetMatchScore();
      result.success(score);
    } else {
      result.notImplemented();
      System.out.println("GetSDKVersion fail");
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  public String GetSDKVersion() {
    return morfinAuthInitialization.GetSDKVersion();
  }

  public int GetSupportedDevices(List<String> supportedList) {
    this.supportedList = supportedList;
    return morfinAuthInitialization != null ? morfinAuthInitialization.GetSupportedDevices(supportedList) : 0;
  }
  public int GetSupportedDeviceListCount() {
    return morfinAuthInitialization != null ? morfinAuthInitialization.GetSupportedDeviceListCount() : 0;
  }
  public List<String> GetSupportedDeviceList() {
    return morfinAuthInitialization != null ? morfinAuthInitialization.getSupportedDeviceList() : null;
  }
  public int GetConnectedDevices(List<String> connectedDevices) {
    return morfinAuthInitialization.GetConnectedDevices(connectedDevices);
  }
  public boolean IsDeviceConnected(DeviceModel name) {
    return morfinAuthInitialization != null && morfinAuthInitialization.IsDeviceConnected(name);
  }
  public int GetImage(
          byte[] image, int[] imageLen, int compressionRatio,ImageFormat format
  ) {
    int ret = morfinAuthInitialization.GetImage(image, imageLen, compressionRatio, format);
    byte[] bImage = new byte[imageLen[0]];
    System.arraycopy(image, 0, bImage, 0, imageLen[0]);
    base64Image = ByteToString(bImage);
    return ret;
  }

  public int GetQualityAutoCapture() {
    return qualityElementValue;
  }

  public int GetNFIQAutoCapture() {
    return nfiqElementValue;
  }

  public String GetImageAutoCapture() {
    return base64ImageElementValue;
  }

  public boolean IsCaptureRunning() {
    return morfinAuthInitialization.IsCaptureRunning();
  }

  public int GetTemplate(byte[] template, int[] templateLen, TemplateFormat templateData) {
    int ret = morfinAuthInitialization.GetTemplate(template, templateLen, templateData);
    byte[] bImage = new byte[templateLen[0]];
    System.arraycopy(template, 0, bImage, 0, templateLen[0]);
    base64Template = ByteToString(template);
    base64TemplateCopy = ByteToString(bImage);
    return ret;
  }

  public int MatchTemplate(byte[] lastCapFingerData, byte[] verifyImage, int[] matchScore, TemplateFormat templateType) {
    int[] matchScoreBlank = new int[1];
    int ret = morfinAuthInitialization.MatchTemplate(lastCapFingerData, verifyImage, matchScoreBlank, templateType);
    matchScoreValue = matchScoreBlank[0];
    return ret;
  }

  public int GetMatchScore() {
    return matchScoreValue;
  }

  public int AutoCapture(int minQuality, int timeOut, int[] qty, int[] nfiq) {
    return morfinAuthInitialization != null ? morfinAuthInitialization.AutoCapture(minQuality, timeOut, qty, nfiq) : 0;
  }

  public String GetTemplateBase64() {
    return base64Template;
  }

  public String GetTemplateBase64Copy() {
    return base64TemplateCopy;
  }

  public int InitWithLock(DeviceModel name, String clientKey, DeviceInfo deviceInfo) {
    System.out.println("ok init from morfinAuthplugin");
    int ret = morfinAuthInitialization.InitWithLock(name, clientKey, deviceInfo);
    return ret;
  }

  public DeviceInfo GetDeviceInfo() {
    return morfinAuthInitialization != null ? morfinAuthInitialization.GetDeviceInfo() : null;
  }

  public int Uninit() {
    return morfinAuthInitialization != null ? morfinAuthInitialization.Uninit() : 0;
  }

  public int StopCapture() {
    return morfinAuthInitialization != null ? morfinAuthInitialization.StopCapture() : 0;
  }

  public int StartCapture(int minQuality, int timeOut) {
    return morfinAuthInitialization.StartCapture(minQuality, timeOut);
  }

  public void OnPreview(int errorCode, int quality, byte[] image) {
    String byteString = ByteToString(image);
    String commaSeperated = errorCode + "," + quality + "," + byteString;
    if (callBack_Channel != null) {
      callBack_Channel.invokeMethod(METHOD_PREVIEW, commaSeperated);
    }
  }

  @Override
  public void OnFingerPosition(int var1, int var2) {
  }

  @Override
  public void OnComplete(int errorCode, int quality, int NFIQ) {
    String commaSeparated = errorCode + "," + quality + "," + NFIQ + "," + ShowFinalFinger();
    if (callBack_Channel != null) {
      callBack_Channel.invokeMethod(METHOD_COMPLETE, commaSeparated);
    }
  }

  private String ShowFinalFinger() {
    int Size = GetDeviceInfo().Width * GetDeviceInfo().Height + 1111;
    int[] iSize = new int[1];
    byte[] bImage1 = new byte[Size];
    int ret = morfinAuthInitialization.GetImage(bImage1, iSize, 1, ImageFormat.BMP);
    byte[] bImage = new byte[iSize[0]];
    System.arraycopy(bImage1, 0, bImage, 0, iSize[0]);
    return ByteToString(bImage);
  }

  @Override
  public void OnDeviceDetection(String deviceName, DeviceDetection deviceDetection) {
    String deviceDetect = deviceDetection.toString();
    System.out.println("==============>  " + deviceDetect);
    if (callBack_Channel != null) {
      callBack_Channel.invokeMethod(METHOD_DEVICE_DETECTION, deviceName + "," + deviceDetect);
    }
  }

  public static String ByteToString(byte[] b) {
    try {
      String temp = null;
      temp = android.util.Base64.encodeToString(b, android.util.Base64.DEFAULT);
      return temp;
    } catch (Exception e) {
      return null;
    }
  }

  public String GetImageBase64() {
    return base64Image;
  }
}