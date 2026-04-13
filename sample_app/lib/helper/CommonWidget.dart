
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:gson/gson.dart';
import '../DeviceInfoDialog.dart';
import 'BottomNavigationDialogListener.dart';
import 'DeviceInfo.dart';

class CommonWidget {
  static Future<bool?> getToast(String message) {
    return Fluttertoast.showToast(
        msg: message, // message
        toastLength: Toast.LENGTH_SHORT, // length
        gravity: ToastGravity.CENTER, // location
        timeInSecForIosWeb: 1 // duration
        );
  }

  static void showLoaderDialog(BuildContext context, String message) {
    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.white,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                margin: const EdgeInsets.only(left: 7),
                child: Text(
                  message,
                  maxLines: 5,
                )),
          ],
        ),
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static DeviceInfo  convertStringToDeviceInfo(String device) {
    DeviceInfo deviceInfo = DeviceInfo.fromJson(jsonDecode(device));
    return deviceInfo;
  }

  static String convertDeviceInfoToString(DeviceInfo deviceInfo) {
    String p = gson.encode(deviceInfo);
    return p;
  }

  String clientKey = "";
  static Widget getBottomNavigationWidget(
      BuildContext context,
      String deviceInfo,
      BottomDialogRefreshListener bottomDialogRefreshListener) {
    return BottomAppBar(
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const DeviceInfoDialog(),
            ).then((value) =>
                bottomDialogRefreshListener.BottomDialogRefresh(true));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(5.0)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(deviceInfo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      )),
                ),
              ),
              Container(
                  margin: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 0.0),
                  child: Image.asset(
                    'assets/images/ic_device_update.png',
                    width: 30,
                    height: 30,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
