package com.mantra.morfinauth_ble;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.mantra.morfinauth.DeviceInfo;
import com.mantra.morfinauth.MorfinAuthBLE;
import com.mantra.morfinauth.ble.MorfinAuthBLE_Callback;
import com.mantra.morfinauth.ble.enums.CaptureFormat;
import com.mantra.morfinauth.ble.enums.MorfinBleState;
import com.mantra.morfinauth.ble.enums.MorfinNotifications;
import com.mantra.morfinauth.ble.model.BatteryInformation;
import com.mantra.morfinauth.ble.model.MorfinBleDevice;

import com.mantra.morfinauth.enums.ImageFormat;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MorfinauthBlePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, MorfinAuthBLE_Callback {
  private MethodChannel methodChannel;

  // Event Channels
  private EventChannel discoveryChannel;
  private EventChannel connectionChannel;
  private EventChannel notificationChannel;
  private EventChannel imageChannel;

  // Event Sinks
  private EventChannel.EventSink discoverySink;
  private EventChannel.EventSink connectionSink;
  private EventChannel.EventSink notificationSink;
  private EventChannel.EventSink imageSink;

  private Context context;
  private MorfinAuthBLE morfinAuthBLE;

  // Handler to safely push background hardware events to the Flutter Main UI Thread
  private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());

  // Cache to hold discovered devices by MAC address
  private final HashMap<String, MorfinBleDevice> discoveredDevicesCache = new HashMap<>();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();

    try {
      morfinAuthBLE = new MorfinAuthBLE(context, this);
    } catch (Exception e) {
      e.printStackTrace();
    }

    // Setup Method Channel
    methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble");
    methodChannel.setMethodCallHandler(this);

    // Setup Event Channels for Streams
    discoveryChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble/discovery");
    discoveryChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override public void onListen(Object arguments, EventChannel.EventSink events) { discoverySink = events; }
      @Override public void onCancel(Object arguments) { discoverySink = null; }
    });

    connectionChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble/connection");
    connectionChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override public void onListen(Object arguments, EventChannel.EventSink events) { connectionSink = events; }
      @Override public void onCancel(Object arguments) { connectionSink = null; }
    });

    notificationChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble/notifications");
    notificationChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override public void onListen(Object arguments, EventChannel.EventSink events) { notificationSink = events; }
      @Override public void onCancel(Object arguments) { notificationSink = null; }
    });

    imageChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble/image");
    imageChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override public void onListen(Object arguments, EventChannel.EventSink events) { imageSink = events; }
      @Override public void onCancel(Object arguments) { imageSink = null; }
    });
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (morfinAuthBLE == null) {
      result.error("UNAVAILABLE", "MorfinAuthBLE not initialized", null);
      return;
    }

    switch (call.method) {
      case "discoverDevices":
        discoveredDevicesCache.clear();
        result.success(morfinAuthBLE.DiscoverDevices());
        break;

      case "stopDiscover":
        result.success(morfinAuthBLE.StopDiscover());
        break;

      case "connectDevice":
        String address = call.argument("address");
        MorfinBleDevice device = discoveredDevicesCache.get(address);

        // Fallback: If device wasn't discovered in this session but user has the MAC address
        if (device == null && address != null) {
          device = new MorfinBleDevice();
          device.macAddress = address;
        }

        if (device != null) {
          result.success(morfinAuthBLE.ConnectDevice(device));
        } else {
          result.error("DEVICE_NOT_FOUND", "MAC Address is null", null);
        }
        break;

      case "disconnect":
        result.success(morfinAuthBLE.Disconnect());
        break;

      case "initDevice":
        String clientKey = call.argument("clientKey");
        if (clientKey == null) clientKey = "";

        DeviceInfo info = new DeviceInfo();
        int initRet = morfinAuthBLE.InitDevice(clientKey, info);

        Map<String, Object> infoMap = new HashMap<>();
        infoMap.put("status", initRet);
        if (initRet == 0) {
          infoMap.put("make", info.Make);
          infoMap.put("model", info.Model);
          infoMap.put("serialNo", info.SerialNo);
        }
        result.success(infoMap);
        break;

      case "unInitDevice":
        result.success(morfinAuthBLE.UnInitDevice());
        break;

      case "startCapture":
        // Run heavy capture process on a background thread
        new Thread(() -> {
          Integer minQuality = call.argument("minQuality");
          Integer timeout = call.argument("timeout");

          int q = (minQuality != null) ? minQuality : 60;
          int t = (timeout != null) ? timeout : 10000;

          int[] quality = new int[1];
          int[] nfiq = new int[1];

          // Call SDK StartCapture - This blocks until the finger is scanned or timeout is reached
          int capRet = morfinAuthBLE.StartCapture(CaptureFormat.FIR_2005, q, t, quality, nfiq);

          Map<String, Object> capResult = new HashMap<>();
          capResult.put("status", capRet);
          capResult.put("quality", quality[0]);
          capResult.put("nfiq", nfiq[0]);

          // If capture is successful, manually fetch the image and push to Dart Stream
          if (capRet == 0) {
            try {
              int[] imgSize = new int[1];
              byte[] imgBuffer = new byte[256 * 360 + 1111];

              // FIX APPLIED HERE: Added ImageFormat.BMP as the first argument
              int imgRet = morfinAuthBLE.GetImage(ImageFormat.BMP, imgBuffer, imgSize);

              if (imgRet == 0 && imgSize[0] > 0 && imageSink != null) {
                byte[] finalImage = new byte[imgSize[0]];
                System.arraycopy(imgBuffer, 0, finalImage, 0, imgSize[0]);

                uiThreadHandler.post(() -> {
                  if (imageSink != null) {
                    imageSink.success(finalImage);
                  }
                });
              }
            } catch (Exception e) {
              e.printStackTrace();
            }
          }

          // Return final status map
          uiThreadHandler.post(() -> result.success(capResult));
        }).start();
        break;

      case "stopCapture":
        result.success(morfinAuthBLE.StopCapture());
        break;

      case "getBatteryInformation":
        BatteryInformation batInfo = new BatteryInformation();
        int batRet = morfinAuthBLE.GetBatteryInformation(batInfo);
        Map<String, Object> batMap = new HashMap<>();
        batMap.put("status", batRet);

        if (batRet == 0) {
          batMap.put("percentage", batInfo.batteryChargePercentage);
          batMap.put("health", batInfo.batteryHealthPercentage);
          batMap.put("temperature", batInfo.batteryTemperature);
          batMap.put("chargerConnected", batInfo.chargerConnected);
        }
        result.success(batMap);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  // ==========================================
  // SDK CALLBACKS
  // ==========================================

  @Override
  public void OnDeviceDiscovered(MorfinBleDevice morfinBleDevice) {
    if (discoverySink != null && morfinBleDevice != null) {
      discoveredDevicesCache.put(morfinBleDevice.macAddress, morfinBleDevice);

      Map<String, String> deviceData = new HashMap<>();
      deviceData.put("name", morfinBleDevice.name != null ? morfinBleDevice.name : "Unknown Device");
      deviceData.put("address", morfinBleDevice.macAddress);

      uiThreadHandler.post(() -> {
        if (discoverySink != null) discoverySink.success(deviceData);
      });
    }
  }

  @Override
  public void OnDeviceConnectionStatus(MorfinBleDevice morfinBleDevice, MorfinBleState morfinBleState) {
    if (connectionSink != null && morfinBleState != null) {
      uiThreadHandler.post(() -> {
        if (connectionSink != null) connectionSink.success(morfinBleState.name());
      });
    }
  }

  @Override
  public void MorfinDeviceStatusNotification(MorfinNotifications morfinNotifications) {
    if (notificationSink != null && morfinNotifications != null) {
      uiThreadHandler.post(() -> {
        if (notificationSink != null) notificationSink.success(morfinNotifications.name());
      });
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
    if (morfinAuthBLE != null) {
      morfinAuthBLE.Disconnect();
      morfinAuthBLE.UnInitDevice();
      morfinAuthBLE = null;
    }
  }
}