package com.mantra.morfinauth_ble;

import android.content.Context;
import androidx.annotation.NonNull;

import com.mantra.morfinauth.DeviceInfo;
import com.mantra.morfinauth.MorfinAuthBLE;
import com.mantra.morfinauth.ble.MorfinAuthBLE_Callback;
import com.mantra.morfinauth.ble.enums.CaptureFormat;
import com.mantra.morfinauth.ble.enums.MorfinBleState;
import com.mantra.morfinauth.ble.enums.MorfinNotifications;
import com.mantra.morfinauth.ble.model.MorfinBleDevice;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MorfinauthBlePlugin implements FlutterPlugin, MethodCallHandler, MorfinAuthBLE_Callback {
  private MethodChannel methodChannel;
  private EventChannel eventChannel;
  private EventChannel.EventSink eventSink;

  private Context context;
  private MorfinAuthBLE morfinAuthBLE;
  private MorfinBleDevice currentDevice;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();

    // Setup Method Channel for Dart -> Java commands
    methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble/commands");
    methodChannel.setMethodCallHandler(this);

    // Setup Event Channel for Java -> Dart continuous data
    eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "morfinauth_ble/events");
    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
      }

      @Override
      public void onCancel(Object arguments) {
        eventSink = null;
      }
    });

    // Initialize the Mantra SDK Wrapper
    try {
      morfinAuthBLE = new MorfinAuthBLE(context, this);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (morfinAuthBLE == null) {
      result.error("UNAVAILABLE", "MorfinAuthBLE not initialized", null);
      return;
    }

    switch (call.method) {
      case "discoverDevices":
        int discoverRet = morfinAuthBLE.DiscoverDevices();
        result.success(discoverRet);
        break;

      case "stopDiscover":
        int stopDiscRet = morfinAuthBLE.StopDiscover();
        result.success(stopDiscRet);
        break;

      case "connectDevice":
        String macAddress = call.argument("macAddress");
        currentDevice = new MorfinBleDevice();
        currentDevice.macAddress = macAddress; // macAddress
        int connectRet = morfinAuthBLE.ConnectDevice(currentDevice);
        result.success(connectRet);
        break;

      case "disconnectDevice":
        int disconnectRet = morfinAuthBLE.Disconnect();
        result.success(disconnectRet);
        break;

      case "initDevice":
        DeviceInfo info = new DeviceInfo();
        int initRet = morfinAuthBLE.InitDevice("", info);
        result.success(initRet);
        break;

      case "startCapture":
        Integer quality = call.argument("quality");
        Integer timeout = call.argument("timeout");
        int[] qty = new int[1];
        int[] nfiq = new int[1];
        int captureRet = morfinAuthBLE.StartCapture(CaptureFormat.FIR_2005, quality != null ? quality : 60, timeout != null ? timeout : 10000, qty, nfiq);
        result.success(captureRet);
        break;

      case "stopCapture":
        int stopCapRet = morfinAuthBLE.StopCapture();
        result.success(stopCapRet);
        break;

      default:
        result.notImplemented();
        break;
    }
  }


  // MorfinAuthBLE_Callback Implementations

  @Override
  public void OnDeviceDiscovered(MorfinBleDevice device) {
    if (eventSink != null && device != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("event", "OnDeviceDiscovered");
      data.put("name", device.name);
      data.put("macAddress", device.macAddress); // macAddress
      eventSink.success(data);
    }
  }

  @Override
  public void OnDeviceConnectionStatus(MorfinBleDevice device, MorfinBleState state) {
    if (eventSink != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("event", "OnDeviceConnectionStatus");
      data.put("state", state.name()); // "CONNECTED", "DISCONNECTED", etc.
      eventSink.success(data);
    }
  }

  @Override
  public void MorfinDeviceStatusNotification(MorfinNotifications notification) {
    if (eventSink != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("event", "MorfinDeviceStatusNotification");
      data.put("notification", notification.name());
      eventSink.success(data);
    }
  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
    if (morfinAuthBLE != null) {
      morfinAuthBLE.Disconnect();
      morfinAuthBLE.UnInitDevice();
    }
  }
}