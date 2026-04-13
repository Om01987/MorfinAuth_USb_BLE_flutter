import 'package:flutter/cupertino.dart';

class DeviceInfoProvider extends ChangeNotifier {
  String deviceNameStatus = "";
  String deviceName = "";
  bool isDeviceConnected = false;

  String SerialNo = "";
  String Make = "";
  String Model = "";
  int Width = -1;
  int Height = -1;
  int DPI = -1;

  void setDeviceNameStatus(String deviceNameStatus) {
    this.deviceNameStatus = deviceNameStatus;
    //notifyListeners();
  }

  void setDeviceName(String deviceName) {
    this.deviceName = deviceName;
    //notifyListeners();
  }

  void setDeviceConnectedStatus(bool isDeviceConnected) {
    this.isDeviceConnected = isDeviceConnected;
    //notifyListeners();
  }

  void setSerialNo(String SerialNo) {
    this.SerialNo = SerialNo;
    //notifyListeners();
  }

  void setMake(String Make) {
    this.Make = Make;
    //notifyListeners();
  }

  void setModel(String Model) {
    this.Model = Model;
    //notifyListeners();
  }

  void setWidth(int Width) {
    this.Width = Width;
    //notifyListeners();
  }

  void setHeight(int Height) {
    this.Height = Height;
    //notifyListeners();
  }


  void setDPI(int DPI) {
    this.DPI = DPI;
    //notifyListeners();
  }
}
