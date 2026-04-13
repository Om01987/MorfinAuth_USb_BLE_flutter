import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:morfinauth_usb/morfinauth_usb.dart'; // UPDATED IMPORT
import 'provider/DeviceInfoProvider.dart'; // FIXED LOCAL IMPORT
import 'provider/SettingProvider.dart'; // FIXED LOCAL IMPORT
import 'provider/clientKeyProvider.dart'; // FIXED LOCAL IMPORT
import 'CapturePage.dart';
import 'enums/DeviceDetection.dart';
import 'helper/BottomNavigationDialogListener.dart';
import 'helper/CommonWidget.dart';
import 'helper/SharePreferenceHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'helper/DeviceInfo.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart' as pc;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: DeviceInfoProvider(),
        ),
        ChangeNotifierProvider.value(
          value: SettingProvider(),
        ),
        ChangeNotifierProvider.value(
          value: clientKeyProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Morfin Auth',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyApp(),
      )));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements BottomDialogRefreshListener {
  String deviceInfo = "Device Status: ";
  String? deviceInit = "Check Device";

  TextEditingController getKeyController = TextEditingController();
  TextEditingController setKeyController = TextEditingController();
  String clientKey = "";

  //for getSDKVersion()
  String _platformVersion = 'Unknown';
  String GET_SDK_VERSION = "SDK Version: ";
  String GET_Supported_Device_List = "Supported Devices : \n";

  late SharePreferenceHelper sharePreferenceHelper;
  MethodChannel channel = const MethodChannel('PassedCallBack');

  DeviceInfo? deviceInfoObject;
  String deviceConnectionStatus = "";

  @override
  void initState() {
    sharePreferenceHelper = SharePreferenceHelper();
    sharePreferenceHelper.setDeviceInfo("");
    callBackRegister();
    methodInitialize();
    GetSDKVersion();
    GetSupportedDevices();
    getDeviceObject();
    super.initState();
  }

  void  getDeviceObject() {
    sharePreferenceHelper = SharePreferenceHelper();
    Future<DeviceInfo?> deviceinfo = GetDeviceInfo();
    deviceInfoObject = null;
    deviceinfo.then((value) {
      deviceInfoObject = value;
    });

  }

  Future<DeviceInfo?> GetDeviceInfo() async {
    Future<String?> value = sharePreferenceHelper.getDeviceInfo();
    print("deviceValue :: $value");
    String deviceInfo = "";
    value.then((result) {
      if (result != "") {
        deviceInfo = result!;
      }
    });
    await (value);
    String deviceValue = deviceInfo;
    if (deviceValue == "") {
      return null;
    }
    DeviceInfo deviceInfoObject =
    CommonWidget.convertStringToDeviceInfo(deviceValue);
    await (deviceInfoObject);
    return deviceInfoObject;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void methodInitialize() async {
    await MorfinauthUsb.GetFingerInitialize();
  }

  String getDeviceStatusInfo() {
    String deviceName = Provider.of<DeviceInfoProvider>(context, listen: false)
        .deviceNameStatus;
    if (deviceName != "") {
      deviceInfo = deviceName;
    }
    return deviceInfo;
  }

  String METHOD_DEVICE_DETECTION = "Device_Detection";

  void callBackRegister() {
    channel.setMethodCallHandler((call) {
      if (call.method == METHOD_DEVICE_DETECTION) {
        print("Device Detection : >>>>${call.arguments}");
        final splitNames = call.arguments.split(',');
        String deviceName = splitNames[0];
        String detection = splitNames[1];
        clientKey = setKeyController.text;
        connectDisConnectView(deviceName,detection);
      }
      return Future.value("");
    });
  }

  void _reload() {
    callBackRegister();
    String name = getDeviceStatusInfo();
    setState(() {
      deviceInfo = name;
    });
  }

  Future<String> genClientKey(String clientKey) async {
    // Public key PEM
    const String pubKeyPem = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAr1Q1NkfC780XfHDMUR86
L8lOTdwS13BDMy/wv4GOFDaqpbJG5a9pb2dZyFSOpfG+u4MXFnqhm765ahMguCsM
zRYxyuHWx7oTg9HCLfym1ZFNL0nLunPP6wKmJo28ZuDsFCTF70JmNxso2Yn4eImE
N6m5Sy6ilfwgFuhCvneY3/1ASoSWej7jPH2eloNfCclf8MjjzlKL8/QIAj8UWj0E
NJwYXqEIVxO1DIWj44GO9Xlk8UrqQYTwkz9Gy/svU4zxD8aCEwTUpczvnq4/GZD6
d4SN7l3+Vthj9tjIImqJSSx7NnidQabF5PfbnDTjEXrb70TEb7PH6xG/ykPRsPr6
3QIDAQAB
-----END PUBLIC KEY-----
""";

    try {
      // Clean PEM
      final cleanPem = pubKeyPem
          .replaceAll("-----BEGIN PUBLIC KEY-----", "")
          .replaceAll("-----END PUBLIC KEY-----", "")
          .replaceAll(RegExp(r"\s+"), "");
      final derBytes = base64.decode(cleanPem);

      // Parse ASN.1 to get modulus & exponent
      final asn1Parser = ASN1Parser(derBytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
      final publicKeySeq =
      ASN1Parser(publicKeyBitString.contentBytes()!).nextObject()
      as ASN1Sequence;

      final modulus =
          (publicKeySeq.elements[0] as ASN1Integer).valueAsBigInteger;
      final exponent =
          (publicKeySeq.elements[1] as ASN1Integer).valueAsBigInteger;

      final rsaPublicKey = pc.RSAPublicKey(modulus!, exponent!);

      // --- Force OAEP-SHA256 ---
      final rsaEngine = pc.OAEPEncoding.withSHA256(pc.RSAEngine());
      rsaEngine.init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(rsaPublicKey));

      // Prepare message
      final epochSeconds =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final finalKey = utf8.encode(epochSeconds + clientKey);

      // Encrypt
      final encryptedBytes = rsaEngine.process(Uint8List.fromList(finalKey));

      // Base64 encode
      return base64.encode(encryptedBytes);
    } catch (e) {
      print("Error while generating client key: $e");
      rethrow;
    }
  }

  Future<void> GetSDKVersion() async {
    String platformVersion;

    try {
      platformVersion = await MorfinauthUsb.GetSDKVersion ?? 'Unknown SDK version';
    } on PlatformException catch (e) {
      platformVersion = await MorfinauthUsb.GetSDKVersion ?? 'Unknown SDK version';
    }

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> GetSupportedDevices() async {
    List<String> supportedList = [];
    int ret = await MorfinauthUsb.GetSupportedDevices(supportedList);
    await (ret);
    if (ret == 0) {
      int count = await MorfinauthUsb.GetSupportedDevicesCount();
      if (count > 0) {
        supportedList = await MorfinauthUsb.GetSupportedDevicesList(supportedList);
        String commaSeperated = "";
        for (int i = 0; i < supportedList.length; i++) {
          commaSeperated = "$commaSeperated${supportedList[i]}, ";
        }
        if (commaSeperated != null && commaSeperated.isNotEmpty) {
          commaSeperated =
              commaSeperated.substring(0, commaSeperated.length - 2);
        }
        GET_Supported_Device_List = "";
        setState(() {
          GET_Supported_Device_List = "Supported Device: $commaSeperated";
        });
        setLogs("Supported Devices: $commaSeperated", false);
      } else {
        setLogs("Supported Devices Not Found", true);
      }
    } else {
      String errorMessage = await MorfinauthUsb.GetErrorMessage(ret);
      await (errorMessage);
      setLogs("Supported Devices Error:  ($errorMessage)", true);
    }
  }

  void connectDisConnectView(String deviceName, String detection) async {
    if (DeviceDetection.CONNECTED.name == detection) {
      setLogs("Device connected", false);
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceConnectedStatus(true);
      deviceConnectionStatus = "Device Status: Connected - $deviceName";
      setState(() {
        deviceInfo = deviceConnectionStatus;
      });
      Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceNameStatus(deviceConnectionStatus);
      Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceName(deviceName);
      await MorfinauthUsb.IsDeviceConnected(deviceName);
    } else {
      setLogs("Device Not Connected", true);
      sharePreferenceHelper.setDeviceInfo(""); // clear deviceConnectionStatus info

      Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceConnectedStatus(false);
      deviceConnectionStatus = "Device Status: Device Not Connected";
      setState(() {
        deviceInfo = deviceConnectionStatus;
      });
      Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceNameStatus(deviceConnectionStatus);
      Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceName(deviceName);
      await MorfinauthUsb.IsDeviceConnected(deviceName);
    }
  }


  void setLogs(String errorMessage, bool isError) {
    if (isError) {
      print("Error====>$errorMessage");
    } else {
      print("Message====>$errorMessage");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorfinAuth_1.0'),
      ),
      bottomNavigationBar:
      CommonWidget.getBottomNavigationWidget(context, deviceInfo, this),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue), // Set the border color here
                ),
                child: Container(// Set the background color here
                  child: Text(
                    "SDK Version: $_platformVersion\n\n$GET_Supported_Device_List\n",
                    style: const TextStyle(color: Colors.black),
                    textAlign: TextAlign.center, // Align the text to the center
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              // Get key
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: getKeyController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Get Key for (click here)',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: 'Get Key',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  // Save button → call plugin
                  IconButton(
                    onPressed: () async {
                      String inputKey = getKeyController.text.trim();

                      if (inputKey.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a key")),
                        );
                        return;
                      }

                      try {
                        // Call your plugin method
                        String clientKey = await genClientKey(inputKey);
                        print("clientKey ====>$clientKey");
                        // ✅ Paste returned clientKey into Set Key field
                        setKeyController.text = clientKey;

                        // Feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Client Key generated: $clientKey")),
                        );
                      } catch (e) {
                        debugPrint("Error while getting client key: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                  ),
                  // Clear button
                  IconButton(
                    onPressed: () {
                      getKeyController.clear();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),
              // Set key
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: setKeyController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Set Key for (click here)',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: 'Set Key',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Provider.of<clientKeyProvider>(context, listen: false)
                          .updateStoredValue(setKeyController.text);
                    },
                    icon: const Icon(Icons.save),
                  ),
                  IconButton(
                    onPressed: () {
                      setKeyController.clear();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1, // 60%
                    child: getCardView(false),
                  ),
                ],
              ),

              const SizedBox(height: 30.0),
              Image.asset('assets/images/company_logo.png',
                  width: 250.0, height: 100.0),
              const Text(
                "Mantra Softtech India PVT LTD © 2023",
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCardView(bool isSdk) {
    return SizedBox(
      height: 200,
      child: InkWell(
        onTap: () {
          String DEVICE_STATUS;
          bool isConnect = Provider.of<DeviceInfoProvider>(context, listen: false).isDeviceConnected;
          if (isConnect) {
            DEVICE_STATUS = "Connected";
            print("DEVICE_STATUS 1 :: $DEVICE_STATUS");
          } else {
            DEVICE_STATUS = "Disconnected";
            print("DEVICE_STATUS 2:: $DEVICE_STATUS");
          }

          if (DEVICE_STATUS == "Connected") {
            print("DEVICE_STATUS 3 :: $DEVICE_STATUS");
            if (deviceInfoObject == null) {
              Fluttertoast.showToast(
                msg: "Please initialize the device first",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.blue,
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CapturePage()),
              ).then((res) => _reload());
            }
          }
          else {
            Fluttertoast.showToast(
              msg: "Please connect device first",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.blue,
            );
          }
        },
        child: Card(
          elevation: 5,
          borderOnForeground: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
            side: const BorderSide(color: Colors.blue, width: 3.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: getDynamicViewSDKCapture(isSdk),
            ),
          ),
        ),
      ),
    );
  }


  List<Widget> getDynamicViewSDKCapture(bool isSdk) {
    return getCaptureWidget();
  }

  List<Widget> getCaptureWidget() {
    return <Widget>[
      Container(
        padding: const EdgeInsets.all(0), // Adjust the padding as needed
        child: Lottie.asset(
          'assets/animations/fingerprint.json',
          width: 150,
          height: 150 ,
          fit: BoxFit.cover,
        ),
      ),

      const Text("Capture Test"),
    ];
  }

  @override
  void BottomDialogRefresh(bool isRefresh) {
    if (isRefresh) {
      _reload();
      getDeviceObject();
    }
  }
}