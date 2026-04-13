package com.mantra.morfinauth_usb;

import android.content.Context;
import androidx.annotation.Nullable;
import com.mantra.morfinauth.DeviceInfo;
import com.mantra.morfinauth.MorfinAuth;
import com.mantra.morfinauth.MorfinAuth_Callback;
import com.mantra.morfinauth.enums.DeviceDetection;
import com.mantra.morfinauth.enums.DeviceModel;
import com.mantra.morfinauth.enums.ImageFormat;
import com.mantra.morfinauth.enums.TemplateFormat;

import java.util.ArrayList;
import java.util.List;

public class MorfinAuthInitialization implements MorfinAuth_Callback {
    private Context mContext;
    private PluginCallBack MorfinAuthCustomCallBack;
    private MorfinAuth morfinAuth;
    private DeviceInfo lastDeviceInfo;
    private List<String> supportedList;

    public MorfinAuthInitialization(Context context, PluginCallBack pluginCallBack) {
        mContext = context;
        MorfinAuthCustomCallBack = pluginCallBack;
        morfinAuth = new MorfinAuth(mContext, this);
        supportedList = new ArrayList<String>();
    }

    public Boolean IsDeviceConnected(DeviceModel name) {
        return morfinAuth.IsDeviceConnected(name);
    }

    public int InitWithLock(DeviceModel name, String clientKey, DeviceInfo deviceInfo) {
        System.out.println("ok InitWithLock from morfinAuthInitilization");
        int ret = morfinAuth != null ? morfinAuth.Init(name, clientKey, deviceInfo) : -1;
        lastDeviceInfo = deviceInfo;
        return ret;
    }


    public String GetErrorMessage(int ret) {
        return morfinAuth.GetErrorMessage(ret);
    }
    public DeviceInfo GetDeviceInfo() {
        return lastDeviceInfo;
    }
    public int Uninit() {
        return morfinAuth.Uninit();
    }

    public int StopCapture() {
        return morfinAuth.StopCapture();
    }
    public String GetSDKVersion() {
        return morfinAuth.GetSDKVersion();
    }

    public int GetSupportedDevices(List<String> supportedList) {
        this.supportedList = supportedList;
        return morfinAuth != null ? morfinAuth.GetSupportedDevices(supportedList) : 0;
    }
    public int GetSupportedDeviceListCount() {
        return supportedList != null ? supportedList.size() : 0;
    }
    public List<String> getSupportedDeviceList() {
        return supportedList != null ? supportedList : new ArrayList<String>();
    }
    public int GetConnectedDevices(List<String> connectedDevices) {
        return morfinAuth.GetConnectedDevices(connectedDevices);
    }

    public int StartCapture(int minQuality, int timeOut) {
        return morfinAuth.StartCapture(minQuality, timeOut);
    }

    public boolean IsCaptureRunning() {
        return morfinAuth.IsCaptureRunning();
    }

    public int GetTemplate(byte[] template, int[] templateLen, TemplateFormat templateData) {
        return morfinAuth.GetTemplate(template, templateLen, templateData);
    }

    public int GetImage(byte[] image, int[] imageLen, int compressionRatio, ImageFormat format) {
        return morfinAuth.GetImage(image, imageLen, compressionRatio, format);
    }

    public int MatchTemplate(byte[] lastCapFingerData, byte[] verifyImage, int[] matchScore, TemplateFormat templateType) {
        return morfinAuth.MatchTemplate(lastCapFingerData, verifyImage, matchScore, templateType);
    }

    public int AutoCapture(int minQuality, int timeOut, int[] qty, int[] nfiq) {
        return morfinAuth.AutoCapture(minQuality, timeOut, qty, nfiq);
    }

    @Override
    public void OnDeviceDetection(@Nullable String deviceName, @Nullable DeviceDetection detection) {
        MorfinAuthCustomCallBack.OnDeviceDetection(deviceName, detection);
    }

    @Override
    public void OnPreview(int errorCode, int quality, @Nullable byte[] image) {
        MorfinAuthCustomCallBack.OnPreview(errorCode, quality, image);
    }

    @Override
    public void OnComplete(int errorCode, int Quality, int NFIQ) {
        MorfinAuthCustomCallBack.OnComplete(errorCode, Quality, NFIQ);
    }

    @Override
    public void OnFingerPosition(int arg1, int arg2) {
        // Your implementation here
    }
}
