import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'DeviceInfo.dart';

class Constants {
  static String DEVICE_INFO = "device_status_info";

  static Uint8List convertBase64StringToByteArray(String Base64) {
   return const Base64Codec().decode(Base64.replaceAll(RegExp(r'\s+'), ''));
  }

  static String convertByteArrayToBase64(Uint8List bImage) {
    return base64.encode(bImage);
  }

  static progressDialog(bool isLoading, BuildContext context) {
    AlertDialog dialog = AlertDialog(
      content:  SizedBox(
          height: 40.0,
          child:  Center(
            child:  Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const <Widget>[
                 CircularProgressIndicator(),
                Padding(padding: EdgeInsets.only(left: 15.0)),
                 Text("Please wait")
              ],
            ),
          )),
      contentPadding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
    );
    if (!isLoading) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
        useRootNavigator: true,
      );
    }
  }

}
