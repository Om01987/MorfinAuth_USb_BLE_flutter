package com.mantra.morfinauth_usb;

import com.mantra.morfinauth.enums.DeviceDetection;

public interface PluginCallBack {
    void OnComplete(int errorCode, int quality, int NFIQ);

    void OnDeviceDetection(String deviceName, DeviceDetection deviceDetection);

    void OnPreview(int errorCode, int quality, byte[] image);

    void OnFingerPosition(int var1, int var2);
}