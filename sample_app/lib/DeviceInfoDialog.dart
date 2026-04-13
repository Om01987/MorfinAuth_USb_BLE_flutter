import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morfinauth_usb/morfinauth_usb.dart'; // UPDATED IMPORT
import 'provider/clientKeyProvider.dart'; // FIXED IMPORT
import 'package:provider/provider.dart';
import 'helper/CommonWidget.dart';
import 'enums/DeviceDetection.dart';
import 'helper/DeviceInfo.dart';
import 'helper/SharePreferenceHelper.dart';
import 'provider/DeviceInfoProvider.dart'; // FIXED IMPORT

class DeviceInfoDialog extends StatefulWidget {
  const DeviceInfoDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DeviceInfoDialogState();
}

class DeviceInfoDialogState extends State<DeviceInfoDialog> {
  String DEVICE_STATUS = "";
  String INIT_STATUS = "";
  String MAKE = "";
  String MODEL = "";
  String SERIAL = "";
  String WH = "";

  MethodChannel channel = const MethodChannel('PassedCallBack');

  late SharePreferenceHelper sharePreferenceHelper;

  Future<DeviceInfo?> GetDeviceInfo() async {
    final value = await sharePreferenceHelper.getDeviceInfo();
    String deviceInfo = value ?? "";
    String deviceValue = deviceInfo;
    if (deviceValue == "") {
      return null;
    }
    DeviceInfo deviceInfoObject =
    CommonWidget.convertStringToDeviceInfo(deviceValue);
    return deviceInfoObject;
  }

  DeviceInfo? deviceInfoObject;

  @override
  void initState() {
    super.initState();
    sharePreferenceHelper = SharePreferenceHelper();
    deviceInfoObject = null;
    GetDeviceInfo().then((value) {
      deviceInfoObject = value;
      if (mounted) {
        setState(() {
          try{
            if (deviceInfoObject != null) {
              INIT_STATUS = "Init Success";
              MODEL = deviceInfoObject!.Model;
              MAKE = deviceInfoObject!.Make;
              SERIAL = deviceInfoObject!.SerialNo;

              String width = deviceInfoObject!.Width.toString();
              String height = deviceInfoObject!.Height.toString();
              if (width != "-1" && height != "-1") {
                WH = "$width / $height";
              }
            } else {
              INIT_STATUS = "Initialization Failed";
            }
          }
          catch(e){
            INIT_STATUS = "Initialization Failed ($e)";
          }
        });
      }
    });

    callBackReqister();
    bool isConnect =
        Provider.of<DeviceInfoProvider>(context, listen: false).isDeviceConnected;
    DEVICE_STATUS = isConnect ? "Connected" : "Disconnected";

    checkDeviceConnection();
  }

  void checkDeviceConnection() async {
    final deviceName =
        Provider.of<DeviceInfoProvider>(context, listen: false).deviceName;
    final bool ret = await MorfinauthUsb.IsDeviceConnected(deviceName); // UPDATED

    if (mounted) {
      setState(() {
        DEVICE_STATUS = ret ? "Device Connected" : "Device Not Connected";
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void callBackReqister() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'Device_Detection') {
        final splitNames = call.arguments.split(',');
        String deviceName = splitNames[0];
        String detection = splitNames[1];

        String device = "";
        if (DeviceDetection.CONNECTED.name == detection) {
          device = "Device Status: Connected - $deviceName";
          setLogs("Device connected", false);
          Provider.of<DeviceInfoProvider>(context, listen: false)
              .setDeviceConnectedStatus(true);
          Provider.of<DeviceInfoProvider>(context, listen: false)
              .setDeviceNameStatus(device);
          Provider.of<DeviceInfoProvider>(context, listen: false)
              .setDeviceName(deviceName);
          if (mounted) {
            setState(() {
              DEVICE_STATUS = "Device Connected";
              INIT_STATUS = "";
            });
          }
          bool ret = await MorfinauthUsb.IsDeviceConnected(deviceName); // UPDATED
        } else {
          device = "Device Status: Device Not Connected";
          setLogs("Device Not Connected", true);
          sharePreferenceHelper.setDeviceInfo("");
          Provider.of<DeviceInfoProvider>(context, listen: false)
              .setDeviceConnectedStatus(false);
          device = "Device Status: Device Not Connected";
          Provider.of<DeviceInfoProvider>(context, listen: false)
              .setDeviceNameStatus(device);
          Provider.of<DeviceInfoProvider>(context, listen: false)
              .setDeviceName(deviceName);
          if (mounted) {
            setState(() {
              DEVICE_STATUS = "Device Not Connected";
              INIT_STATUS = "";
              setClearDeviceInfo();
            });
          }
        }
      }
      return Future.value("");
    });
  }

  getClientKey(){
    final myData = Provider.of<clientKeyProvider>(context,listen: false);
    var clientKey = myData.storedValue;
    setLogs("clientKey ::: $clientKey", false);
    return clientKey;
  }

  dialogContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // To make the card compact
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Flexible(
                  flex: 4,
                  child: Text("Device Status:  "),
                ),
                Flexible(
                  flex: 6,
                  child: Text(DEVICE_STATUS),
                )
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Flexible(
                  flex: 4,
                  child: Text("Init Status:        "),
                ),
                Flexible(
                  flex: 6,
                  child: Text(INIT_STATUS),
                )
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Flexible(
                  flex: 4,
                  child: Text("MAKE:               "),
                ),
                Flexible(
                  flex: 6,
                  child: Text(MAKE),
                )
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Flexible(
                  flex: 4,
                  child: Text("MODEL:             "),
                ),
                Flexible(
                  flex: 6,
                  child: Text(MODEL),
                )
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Flexible(
                  flex: 4,
                  child: Text("SERIAL NO:       "),
                ),
                Flexible(
                  flex: 6,
                  child: Text(SERIAL),
                )
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Flexible(
                  flex: 4,
                  child: Text("W/H:                  "),
                ),
                Flexible(
                  flex: 6,
                  child: Text(WH),
                )
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: MaterialButton(
                    padding: const EdgeInsets.all(2.0),
                    elevation: 8.0,
                    color: Colors.blue,
                    splashColor: Colors.blueAccent,
                    onPressed: checkDeviceConnection,
                    child: const Text('Check Device'),
                  ),
                ),
                const SizedBox(width: 5.0),
                Expanded(
                  child: MaterialButton(
                    padding: const EdgeInsets.all(2.0),
                    elevation: 8.0,
                    color: Colors.blue,
                    splashColor: Colors.blueAccent,
                    onPressed: Init,
                    child: const Text('Init'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: MaterialButton(
                    padding: const EdgeInsets.all(2.0),
                    elevation: 8.0,
                    color: Colors.blue,
                    splashColor: Colors.blueAccent,
                    onPressed: Uninit,
                    child: const Text('UnInit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void Init() async {
    String clientKey = getClientKey();

    String deviceName = Provider.of<DeviceInfoProvider>(context, listen: false).deviceName;
    setLogs("deviceName :: $deviceName", false);

    if(clientKey.toString() !=""){
      clientKey = clientKey.toString();
      setLogs("clientKey :: $clientKey", false);
    }else{
      clientKey = "";
      setLogs("clientKey else :: $clientKey", false);
    }

    try {
      int ret = await MorfinauthUsb.InitWithLock(deviceName,clientKey); // UPDATED
      setLogs("ret form flutter device info dialog:: $ret", false);

      if (ret != 0) {
        String errorMessage = await MorfinauthUsb.GetErrorMessage(ret); // UPDATED
        setLogs("Init: $ret ($errorMessage)", true);
      } else {
        String device = await MorfinauthUsb.GetDeviceInfo(); // UPDATED
        sharePreferenceHelper.setDeviceInfo(device);
        DeviceInfo deviceInfo = CommonWidget.convertStringToDeviceInfo(device);
        if (mounted) {
          setState(() {
            INIT_STATUS = "Init Success";
            MAKE = deviceInfo.Make;
            MODEL = deviceInfo.Model;
            SERIAL = deviceInfo.SerialNo;

            String width = deviceInfo.Width.toString();
            String height = deviceInfo.Height.toString();
            if (width != "-1" && height != "-1") {
              WH = "$width / $height";
            }
          });
        }
        setLogs(INIT_STATUS, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          INIT_STATUS = "Device not found";
        });
      }
      INIT_STATUS = e.toString();
      setLogs(INIT_STATUS, false);
    }
  }

  Future<void> Uninit() async {
    String displayStatus = "";
    try {
      int ret = await MorfinauthUsb.Uninit(); // UPDATED
      await (ret);
      if (ret == 0) {
        displayStatus = "UnInit Success";
        setLogs(displayStatus, false);
      } else {
        String error = await MorfinauthUsb.GetErrorMessage(ret); // UPDATED
        await (error);
        displayStatus = "UnInit: $ret ($error)";
        setLogs(displayStatus, true);
      }
      sharePreferenceHelper.setDeviceInfo("");
    } catch (e) {
      displayStatus = "Device not found";
      setLogs("Device not found", true);
    }
    setState(() {
      INIT_STATUS = displayStatus;
      setClearDeviceInfo();
    });
  }

  void setLogs(String errorMessage, bool isError) {
    if (isError) {
      print("Error====>$errorMessage");
    } else {
      print("Message====>$errorMessage");
    }
  }

  void setClearDeviceInfo() {
    Provider.of<DeviceInfoProvider>(context, listen: false).setSerialNo("");
    Provider.of<DeviceInfoProvider>(context, listen: false).setMake("");
    Provider.of<DeviceInfoProvider>(context, listen: false).setModel("");

    MAKE = "";
    MODEL = "";
    SERIAL = "";
    WH = "";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }
}