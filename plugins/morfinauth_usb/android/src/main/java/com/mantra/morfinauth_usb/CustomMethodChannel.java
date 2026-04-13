package com.mantra.morfinauth_usb;

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCodec;

public class CustomMethodChannel extends MethodChannel {

    private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());

    public CustomMethodChannel(BinaryMessenger messenger, String name) {
        super(messenger, name);
    }

    public CustomMethodChannel(BinaryMessenger messenger, String name, MethodCodec codec) {
        super(messenger, name, codec);
    }

    public CustomMethodChannel(BinaryMessenger messenger, String name, MethodCodec codec, BinaryMessenger.TaskQueue taskQueue) {
        super(messenger, name, codec, taskQueue);
    }

    @Override
    public void invokeMethod(String method, Object arguments, MethodChannel.Result result) {
        uiThreadHandler.post(() -> super.invokeMethod(method, arguments, result));
    }
}
