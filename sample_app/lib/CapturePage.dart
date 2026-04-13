import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morfinauth_usb/morfinauth_usb.dart'; // UPDATED IMPORT
import 'package:provider/provider.dart';
import '../enums/ImageFormatType.dart';
import '../enums/TemplateFormatType.dart';
import '../helper/CommonWidget.dart';
import '../enums/DeviceDetection.dart';
import '../helper/Constants.dart';
import '../helper/DeviceInfo.dart';
import '../helper/SharePreferenceHelper.dart';
import '../provider/DeviceInfoProvider.dart';
import '../provider/SettingProvider.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'helper/BottomNavigationDialogListener.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CapturePageState();
}

enum ScannerAction { Capture, MatchISO, MatchAnsi }

class CapturePageState extends State<CapturePage> implements BottomDialogRefreshListener{
  final _focusNode = FocusNode();

  String deviceInfo = "Device Status: ";
  MethodChannel channel = const MethodChannel('PassedCallBack');

  static const String METHOD_PREVIEW = "preview";
  static const String METHOD_COMPLETE = "complete";
  final String title = "";

  int displayImage = 0;
  String image_path = "assets/images/img_white_image.png";
  late Uint8List byteImage;
  late SharePreferenceHelper sharePreferenceHelper;
  DeviceInfo? deviceInfoObject = null;
  bool isAutoCapture = false;

  String _selectedImageFormat = "BMP";
  String _selectedTemplateFormat = "FMR_V2005";

  int okCapture = 0;

  String messsageText = "";
  bool isMessageError = false;

  String FMR_V2005 = 'FMR V2005';
  String FMR_V2011 = 'FMR V2011';
  String ANSI_V378 = 'ANSI V378';

  List<String> imageFormatDropdown = ["BMP","JPEG2000","WSQ","RAW","FIRV_2005","FIRV_2011","FIRWSQ_V2005","FIRWSQ_V2011","FIRJPEG_V2005","FIRJPEG_V2011"];
  List<String> tenplateFormatDropdown = ['FMR V2005',"FMR V2011","ANSI V378"];

  final String TEMPLATE_FMR_V2005 = "FMR V2005";
  final String TEMPLATE_FMR_V2011 = "FMR V2011";

  final int DEVICE_NOT_INITIALIZED = - 5;
  final int CAPTURE_ALREADY_STARTED = -2023;
  bool isStopCapture = false;

  TextEditingController imageQualityController = TextEditingController();
  TextEditingController timeoutController = TextEditingController();

  String? selectedValue1 = 'BMP';
  String? selectedValue2 = 'FMR V2005';

  ScannerAction scannerAction = ScannerAction.Capture;

  int timeout = -1;
  int minQuality = 0;
  int templateType = 0;
  int imageType = 0;

  late Uint8List lastCapFingerData;

  String getDeviceStatusInfo() {
    String deviceName = Provider.of<DeviceInfoProvider>(context, listen: false).deviceNameStatus;
    if (deviceName == "") {
    } else {
      deviceInfo = deviceName;
    }
    return deviceInfo;
  }

  void getDeviceObject() {
    sharePreferenceHelper = SharePreferenceHelper();
    Future<DeviceInfo?> deviceinfo = GetDeviceInfo();
    deviceInfoObject = null;
    deviceinfo.then((value) {
      deviceInfoObject = value;
    });
  }

  @override
  void initState(){
    callBackReqister();
    super.initState();
    getDeviceObject();
    displayImage = 0;

    imageQualityController.text = '60';
    timeoutController.text = '10000';

    minQuality = Provider.of<SettingProvider>(context, listen: false).getQuality();
    timeout = Provider.of<SettingProvider>(context, listen: false).getTimeOut();
    imageType = Provider.of<SettingProvider>(context, listen: false).getImageType();
    templateType = Provider.of<SettingProvider>(context, listen: false).getTemplateType();

    setLogs("initState() templateType :: $templateType", false);

    timeout = Provider.of<SettingProvider>(context, listen: false).getTimeOut();
    if (timeout == null || timeout == -1) {
      timeout = 10000;
    }
    timeoutController = TextEditingController(text: timeout.toString());

    int quality = Provider.of<SettingProvider>(context, listen: false).getQuality();
    if (quality == -1) {
      quality = 60;
    }
    imageQualityController = TextEditingController(text: '$quality');

    if (templateType != -1) {
      if (templateType == TemplateFormatType.FMR_V2005.index) {
        _selectedTemplateFormat = FMR_V2005;
      } else if (templateType == TemplateFormatType.FMR_V2011.index) {
        _selectedTemplateFormat = FMR_V2011;
      } else if (templateType == TemplateFormatType.ANSI_V378.index) {
        _selectedTemplateFormat = ANSI_V378;
      }
    }

    imageType = Provider.of<SettingProvider>(context, listen: false).getImageType();

    if (imageType != -1) {
      if (imageType == ImageFormatType.BMP.index) {
        _selectedImageFormat = "BMP";
      } else if (imageType == ImageFormatType.JPEG2000.index) {
        _selectedImageFormat = "JPEG2000";
      } else if (imageType == ImageFormatType.WSQ.index) {
        _selectedImageFormat = "WSQ";
      } else if (imageType == ImageFormatType.RAW.index) {
        _selectedImageFormat = "RAW";
      } else if (imageType == ImageFormatType.FIR_V2005.index) {
        _selectedImageFormat = "FIRV_2005";
      } else if (imageType == ImageFormatType.FIR_V2011.index) {
        _selectedImageFormat = "FIRV_2011";
      } else if (imageType == ImageFormatType.FIRWSQ_V2011.index) {
        _selectedImageFormat = "FIRWSQV_2005";
      } else if (imageType == ImageFormatType.FIRWSQ_V2011.index) {
        _selectedImageFormat = "FIRWSQV_2011";
      } else if (imageType == ImageFormatType.FIRJPEG_V2005.index) {
        _selectedImageFormat = "FIRJPEGV_2005";
      } else if (imageType == ImageFormatType.FIRJPEG_V2011.index) {
        _selectedImageFormat = "FIRJPEGV_2011";
      }
    }
  }

  void onPreview(int ErrorCode, int quality, Uint8List Image) async {
    try {
      if (ErrorCode == 0 && Image.isNotEmpty) {
        setState(() {
          displayImage = 2;
          byteImage = Image;
        });
        setLogs("Preview Quality: $quality", false);
      } else {
        String Error = "Preview Error Code: $ErrorCode (${await MorfinauthUsb.GetErrorMessage(ErrorCode)})"; // UPDATED
        setLogs(Error, true);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void onComplete(int errorCode, int quality, int NFIQ, Uint8List Image) async {
    try {
      if (!isStopCapture) {
        if (errorCode == 0) {
          String log = "Capture Success";
          String qualityNFIQ = "Quality: $quality NFIQ: $NFIQ";
          setLogs("$log  $qualityNFIQ", false);
          setState(() {
            displayImage = 2;
            byteImage = Image;
          });
          Navigator.pop(context);

          if (scannerAction == ScannerAction.Capture) {
            int? width = deviceInfoObject?.Width;
            int? Height = deviceInfoObject?.Height;
            int size = (width! * Height!) + 1111;
            Uint8List bImage = Uint8List(size);
            int ret = await MorfinauthUsb.GetTemplate(bImage, size, templateType); // UPDATED
            if (ret == 0) {
              lastCapFingerData = Uint8List(size);
              String Base64 = await MorfinauthUsb.GetTemplateBase64(); // UPDATED
              bImage = Constants.convertBase64StringToByteArray(Base64);
              List.copyRange(lastCapFingerData, 0, bImage, 0, bImage.length);
            } else {
              setLogs(await MorfinauthUsb.GetErrorMessage(ret), true); // UPDATED
            }
          }
        }
      } else {
        setState(() {
          displayImage = 2;
        });
        setLogs(
            "CaptureComplete: $errorCode (${await MorfinauthUsb.GetErrorMessage(errorCode)})", // UPDATED
            true);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void callBackReqister() {
    channel.setMethodCallHandler((call) {
      if (call.method == 'Device_Detection') {
        print("call.arguments ===> ${call.arguments}");
        final splitNames = call.arguments.split(',');
        String deviceName = splitNames[0];
        String detection = splitNames[1];
        connectDisConnectView(deviceName, detection);
      } else if (call.method == METHOD_COMPLETE) {
        final splitNames = call.arguments.split(',');
        int errorCode = int.parse(splitNames[0]);
        int quality = int.parse(splitNames[1]);
        int NFIQ = int.parse(splitNames[2]);
        String base64String = splitNames[3];
        Uint8List Image = const Base64Codec()
            .decode(base64String.replaceAll(RegExp(r'\s+'), ''));
        onComplete(errorCode, quality, NFIQ,Image);
      } else if (call.method == METHOD_PREVIEW) {
        final splitNames = call.arguments.split(',');
        int errorCode = int.parse(splitNames[0]);
        int quality = int.parse(splitNames[1]);
        String base64String = splitNames[2];
        print("Base 64 String ======>   $base64String");
        Uint8List Image = const Base64Codec()
            .decode(base64String.replaceAll(RegExp(r'\s+'), ''));
        onPreview(errorCode, quality, Image);
      }
      return Future.value("");
    });
  }

  void connectDisConnectView(String deviceName, String detection) async {
    String device = "";
    if (DeviceDetection.CONNECTED.name == detection) {
      setLogs("Device connected", false);
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceConnectedStatus(true);
      device = "Device Status: Connected - $deviceName";
      setState(() {
        deviceInfo = device;
      });
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceNameStatus(device);
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceName(deviceName);
      bool ret = (await MorfinauthUsb.IsDeviceConnected(deviceName)); // UPDATED
    } else {
      setLogs("Device Not Connected", true);
      sharePreferenceHelper.setDeviceInfo("");
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceConnectedStatus(false);
      device = "Device Status: Device Not Connected";
      setState(() {
        deviceInfo = device;
      });
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceNameStatus(device);
      Provider.of<DeviceInfoProvider>(context, listen: false)
          .setDeviceName(deviceName);
    }
  }

  @override
  void didChangeDependencies() {
    getDeviceStatusInfo();
    super.didChangeDependencies();
  }

  Future<void> AutoCapture() async {
    okCapture = 1;
    bool isCaptureRunning = await MorfinauthUsb.IsCaptureRunning(); // UPDATED
    if (deviceInfoObject == null) {
      setLogs("Please run device init first", true);
      setState(() {
        displayImage = 0;
      });
      Navigator.pop(context);
      return;
    } else if (isCaptureRunning) {
      int dfff = CAPTURE_ALREADY_STARTED;
      String errorMessage = "StartCapture Ret: $dfff (Capture Already Started)";
      setLogs(errorMessage, true);
      setState(() {
        displayImage = 0;
      });
      Navigator.pop(context);
      return;
    } else {
      displayBlankData();
      setLogs("Auto capture started", false);
      scannerAction = ScannerAction.Capture;
      isAutoCapture = true;
      isStopCapture = false;
      StartSyncCapture();
    }
  }

  Future<void> StartSyncCapture() async {
    try {
      List<int> qty = [];
      List<int> nfiq = [];
      setLogs("Auto capture started", false);
      int ret = await MorfinauthUsb.AutoCapture(minQuality, timeout, qty, nfiq); // UPDATED
      Navigator.pop(context);
      await (ret);
      if (ret != -1) {
        if (ret != 0) {
          setState(() {
            displayImage = 1;
          });
          String error = await MorfinauthUsb.GetErrorMessage(ret); // UPDATED
          setLogs(
              "Start Sync Capture Ret: $ret ($error)",
              true);
        } else {
          String log = "Capture Success ";
          int quality = await MorfinauthUsb.GetQualityAutoCapture(); // UPDATED
          int nfiq = await MorfinauthUsb.GetNFIQAutoCapture(); // UPDATED
          String ImageString = await MorfinauthUsb.GetIMAGEAutoCapture(); // UPDATED
          Uint8List Image = const Base64Codec()
              .decode(ImageString.replaceAll(RegExp(r'\s+'), ''));
          setState(() {
            displayImage = 2;
            byteImage = Image;
          });
          String message = "Quality: $quality NFIQ: $nfiq";
          setLogs("$log $message", false);
          if (scannerAction == ScannerAction.Capture) {
            int? width = deviceInfoObject?.Width;
            int? Height = deviceInfoObject?.Height;
            int size = (width! * Height!) + 1111;
            Uint8List bImage = Uint8List(size);
            int ret = await MorfinauthUsb.GetTemplate(bImage, size, templateType); // UPDATED
            if (ret == 0) {
              lastCapFingerData = Uint8List(size);
              String Base64 = await MorfinauthUsb.GetTemplateBase64(); // UPDATED
              bImage = Constants.convertBase64StringToByteArray(Base64);
              List.copyRange(lastCapFingerData, 0, bImage, 0, bImage.length);
            } else {
              setLogs(await MorfinauthUsb.GetErrorMessage(ret), true); // UPDATED
            }
          } else {
            matchData();
          }
        }
      }
    } catch (e) {
      setLogs("Error", true);
    }
  }

  Future<void> matchData() async {
    try {
      if (scannerAction == ScannerAction.MatchISO ||
          scannerAction == ScannerAction.MatchAnsi) {
        if (lastCapFingerData == null) {
          return;
        }
        int? width = deviceInfoObject?.Width;
        int? Height = deviceInfoObject?.Height;
        int size = (width! * Height!) + 1111;
        Uint8List bImage = Uint8List(size);
        int ret =
        await MorfinauthUsb.GetTemplate(bImage, size, templateType); // UPDATED
        await (ret);
        if (ret == 0) {
          Uint8List Verify_Template = Uint8List(size);
          String Base64 = await MorfinauthUsb.GetTemplateBase64(); // UPDATED

          bImage = Constants.convertBase64StringToByteArray(Base64);

          List.copyRange(Verify_Template, 0, bImage, 0, bImage.length);
          List<int> matchScore = [];
          int ret = await MorfinauthUsb.MatchTemplate( // UPDATED
              lastCapFingerData, Verify_Template, matchScore, templateType);
          if (ret < 0) {
            setLogs(
                "Error: $ret(${await MorfinauthUsb.GetErrorMessage(ret)})", // UPDATED
                true);
          } else {
            int matchScoreValue = await MorfinauthUsb.GetMatchScore(); // UPDATED
            if (matchScoreValue >= 96) {
              setLogs(
                  "Finger matched with score: $matchScoreValue",
                  false);
            } else {
              setLogs(
                  "Finger not matched, score: $matchScoreValue",
                  false);
            }
          }
        } else {
          setLogs(
              "Error: $ret(${await MorfinauthUsb.GetErrorMessage(ret)})", // UPDATED
              true);
        }
      }
    } catch (e) {
      setLogs("Error", true);
    }
  }

  Future<void> displayBlankData() async {
    setLogs("", false);
    setState(() {
      displayImage = 1;
      setLogs("Auto Capture Started", false);
    });
  }

  bool isProgressBar = false;

  @override
  Widget build(BuildContext context) {
    Provider.of<DeviceInfoProvider>(context, listen: false)
        .setDeviceNameStatus(deviceInfo);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
      ),
      bottomNavigationBar:
      CommonWidget.getBottomNavigationWidget(context, deviceInfo, this),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        kBottomNavigationBarHeight,
                  ),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: imageQualityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Quality [1-100]',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: timeoutController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'TIMEOUT (Milliseconds)',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Image Format',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.blue, // Border color
                                          width: 2.0, // Border width
                                        ),
                                        borderRadius: BorderRadius.circular(8.0), // Border radius
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedValue1,
                                        onChanged: (newValue) {
                                          setState(() {
                                            selectedValue1 = newValue!;

                                            if(selectedValue1 == "BMP"){
                                              imageType =  ImageFormatType.BMP.index;
                                            }else if (selectedValue1 == "JPEG2000"){
                                              imageType =  ImageFormatType.JPEG2000.index;
                                            }else if (selectedValue1 == "WSQ"){
                                              imageType =  ImageFormatType.WSQ.index;
                                            }else if (selectedValue1 == "RAW"){
                                              imageType =  ImageFormatType.RAW.index;
                                            }else if (selectedValue1 == "FIRV_2005"){
                                              imageType =  ImageFormatType.FIR_V2005.index;
                                            }else if (selectedValue1 == "FIRV_2011"){
                                              imageType =  ImageFormatType.FIR_V2011.index;
                                            }else if (selectedValue1 == "FIRWSQ_V2005"){
                                              imageType =  ImageFormatType.FIRWSQ_V2005.index;
                                            }else if (selectedValue1 == "FIRWSQ_V2011"){
                                              imageType =  ImageFormatType.FIRWSQ_V2011.index;
                                            }else if (selectedValue1 == "FIRJPEG_V2005"){
                                              imageType =  ImageFormatType.FIRJPEG_V2005.index;
                                            }else if (selectedValue1 == "FIRJPEG_V2011"){
                                              imageType =  ImageFormatType.FIRJPEG_V2011.index;
                                            }

                                            setLogs("selectedValue1 :::::: $selectedValue1", false);
                                            setLogs("imageType :::::: $imageType", false);
                                          });
                                        },
                                        style: const TextStyle(
                                          color: Colors.blue, // Blue font color
                                        ),
                                        dropdownColor: Colors.white, // Blue background color for dropdown menu
                                        items: imageFormatDropdown.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: const TextStyle(
                                                color: Colors.blue, // White font color
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Template Format',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.blue, // Border color
                                          width: 2.0, // Border width
                                        ),
                                        borderRadius: BorderRadius.circular(8.0), // Border radius
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedValue2,
                                        onChanged: (newValue) {
                                          setState(() {
                                            selectedValue2 = newValue!;

                                            if(selectedValue2 == FMR_V2005){
                                              templateType =  TemplateFormatType.FMR_V2005.index;
                                            }else if (selectedValue2 == FMR_V2011){
                                              templateType =  TemplateFormatType.FMR_V2011.index;
                                            }else if (selectedValue2 == ANSI_V378){
                                              templateType =  TemplateFormatType.ANSI_V378.index;
                                            }

                                            setLogs("selectedValue2 :::::: $selectedValue2", false);
                                            setLogs("templateType :::::: $templateType", false);
                                          });
                                        },
                                        style: const TextStyle(
                                          color: Colors.blue, // Blue font color
                                        ),
                                        dropdownColor: Colors.white, // Blue background color for dropdown menu
                                        items: tenplateFormatDropdown.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: const TextStyle(
                                                color: Colors.blue, // White font color
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),

                      const SizedBox(height: 15.0),
                      const Text(
                        'Perform Operations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      _buildButtonRow(
                        'Start Capture',
                            () {
                          FocusScope.of(context).requestFocus(_focusNode);
                          CommonWidget.showLoaderDialog(
                            context,
                            'Please put finger on scanner',
                          );
                          Future.delayed(
                            const Duration(milliseconds: 200),
                                () => StartCapture(),
                          );
                        },
                        'Auto Capture',
                            () {
                          FocusScope.of(context).requestFocus(_focusNode);
                          CommonWidget.showLoaderDialog(
                            context,
                            'Please put finger on scanner',
                          );
                          Future.delayed(
                            const Duration(milliseconds: 200),
                                () => AutoCapture(),
                          );
                        },
                      ),
                      const SizedBox(height: 5.0),
                      _buildButtonRow(
                        'Stop Capture',
                            () => StopCature(),
                        'Match Finger',
                            () {
                          FocusScope.of(context).requestFocus(_focusNode);
                          if(okCapture != 0){
                            CommonWidget.showLoaderDialog(
                              context,
                              'Please put finger on scanner',
                            );
                          }
                          Future.delayed(
                            const Duration(milliseconds: 200),
                                () => MatchFinger(),
                          );
                        },
                      ),

                      const SizedBox(height: 5.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => SaveImageAndTemplate(),
                              child: const Text('Save Image and Template'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15.0),
                      const Text(
                        'Fingerprint Preview',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: getCardView(),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(
      String buttonText1,
      VoidCallback onPressed1,
      String buttonText2,
      VoidCallback onPressed2,
      ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ElevatedButton(
            onPressed: onPressed1,
            child: Text(buttonText1),
          ),
        ),
        const SizedBox(width: 5.0),
        Expanded(
          child: ElevatedButton(
            onPressed: onPressed2,
            child: Text(buttonText2),
          ),
        ),
      ],
    );
  }

  Widget getCardView() {
    return SizedBox(
      height: 250,
      child: InkWell(
        onTap: () {},
        child: Card(
          elevation: 5,
          borderOnForeground: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
            side: const BorderSide(color: Colors.blue, width: 3.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child:  SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: getCaptureWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> getCaptureWidget() {
    return <Widget>[
      Container(
          margin: const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 0.0),
          child: Text(
            messsageText,
            style: TextStyle(
              color: isMessageError ? Colors.red : Colors.blue,
            ),
          )),
      onImageDynamic(),
    ];
  }

  Widget onImageDynamic() {
    if (displayImage == 0) {
      return Container(
        padding: const EdgeInsets.all(0), // Adjust the padding as needed
        child: Lottie.asset(
          'assets/animations/fingerprint.json',
          width: 200,
          height: 200 ,
          fit: BoxFit.cover,
        ),
      );
    } else if (displayImage == 1) {
      return Image.asset('assets/images/img_white_image.png',
          width: 250.0, height: 200.0);
    } else if (displayImage == 2) {
      return Image.memory(byteImage, width: 250.0, height: 200.0);
    } else {
      return Image.asset(image_path, width: 250.0, height: 200.0);
    }
  }

  Future<DeviceInfo?> GetDeviceInfo() async {
    Future<String?> value = sharePreferenceHelper.getDeviceInfo();
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

  void MatchFinger() {
    FocusScope.of(context).requestFocus(_focusNode);
    if(okCapture != 0) {
      if (deviceInfoObject == null) {
        setLogs("Please run device init first", true);
        Navigator.pop(context);
        return;
      } else if (lastCapFingerData == null) {
        setLogs("Please run start or auto capture first!", true);
        Navigator.pop(context);
        return;
      } else {
        displayBlankData();
        scannerAction = ScannerAction.MatchISO;
        StartSyncCapture();
      }
    }
    else{
      setLogs("Please run start capture or auto capture first", true);
    }
  }

  void SaveImageAndTemplate() {
    FocusScope.of(context).requestFocus(_focusNode);
    if (deviceInfoObject == null) {
      setLogs("Please run device init first", true);
      return;
    } else if (lastCapFingerData == null) {
      setLogs("Please run start or auto capture first!", true);
      return;
    } else {
      saveData();
    }
  }

  void saveData() async {
    try {
      int? width = deviceInfoObject?.Width;
      int? Height = deviceInfoObject?.Height;
      int size = (width! * Height!) + 1111;
      Uint8List bImage = Uint8List(size);
      int ret = await  MorfinauthUsb.GetImage(bImage, size, 10, imageType); // UPDATED
      String Base64 = await MorfinauthUsb.GetImageBase64(); // UPDATED

      bImage = Constants.convertBase64StringToByteArray(Base64);

      if (ret == 0) {
        Uint8List bImageCopy = Uint8List(size);
        bImageCopy = bImage;

        setLogs("**********************************", false);
        setLogs("Image type is :: $imageType", false);
        setLogs("**********************************", false);

        if (imageType == ImageFormatType.BMP.index) {
          WriteImageFile("Bitmap.bmp", bImageCopy);
        } else if (imageType == ImageFormatType.JPEG2000.index) {
          WriteImageFile("JPEG2000.jp2", bImageCopy);
        } else if (imageType == ImageFormatType.WSQ.index) {
          WriteImageFile("WSQ.wsq", bImageCopy);
        } else if (imageType == ImageFormatType.RAW.index) {
          WriteImageFile("Raw.raw", bImageCopy);
        }  else if (imageType == ImageFormatType.FIR_V2005.index) {
          WriteImageFile("FIR_2005.iso", bImageCopy);
        } else if (imageType == ImageFormatType.FIR_V2011.index) {
          WriteImageFile("FIR_2011.iso", bImageCopy);
        } else if (imageType == ImageFormatType.FIRWSQ_V2005.index) {
          WriteImageFile("FIR_WSQ_2005.iso", bImageCopy);
        } else if (imageType == ImageFormatType.FIRWSQ_V2011.index) {
          WriteImageFile("FIR_WSQ_2011.iso", bImageCopy);
        } else if (imageType == ImageFormatType.FIRJPEG_V2005.index) {
          WriteImageFile("FIR_JPEG2000_2005.iso", bImageCopy);
        } else if (imageType == ImageFormatType.FIRJPEG_V2011.index) {
          WriteImageFile("FIR_JPEG2000_2011.iso", bImageCopy);
        }
        try {
          int ret = 0;
          Uint8List bTemplate = Uint8List(size);
          int result = await MorfinauthUsb.GetTemplate( // UPDATED
              bTemplate, size, templateType);
          String Base64 = await MorfinauthUsb.GetTemplateBase64(); // UPDATED

          bTemplate = Constants.convertBase64StringToByteArray(Base64);

          Uint8List bTemplateCopy = Uint8List(size);

          bTemplateCopy = bTemplate;

          if (result == 0) {
            if (templateType == TemplateFormatType.FMR_V2005.index) {
              WriteTemplateFile("ISOTemplate_2005.iso", bTemplateCopy);
            } else if (templateType == TemplateFormatType.FMR_V2011.index) {
              WriteTemplateFile("ISOTemplate_2011.iso", bTemplateCopy);
            } else if (templateType == TemplateFormatType.ANSI_V378.index) {
              WriteTemplateFile("ANSI_378.iso", bTemplateCopy);
            }
          } else {
            setLogs(
                "Save Template Ret: " +
                    ret.toString() +
                    " (" + await MorfinauthUsb.GetErrorMessage(ret) + ")", // UPDATED
                true);
          }
        } catch (e) {
          setLogs(e.toString(), true);
          setLogs("Error Saving Template.", true);
        }
      } else {
        setLogs(
            "Save Image Ret: " +
                ret.toString() +
                " (" + await MorfinauthUsb.GetErrorMessage(ret) + ")", // UPDATED
            true);
      }
    } catch (e) {
      setLogs(e.toString(), true);
      saveData();
      setLogs("Error Saving Image.", true);
    }
  }

  bool isImageSaved = false;

  void WriteImageFile(String filename, Uint8List byte) async {
    try {
      final directory = await getExternalStorageDirectory();
      final dirPath = '${directory?.path}/FingerData/Image/$filename';
      File file = File(dirPath);
      bool isExist = false;
      file.exists().then((result) => isExist = result);
      file.create(recursive: true);
      var myFile = File('$dirPath');
      var sink = myFile.openWrite();
      myFile.writeAsBytes(byte);
      await sink.flush();
      await sink.close();
      setLogs("Image Saved", false);
      isImageSaved = true;
    } catch (e) {
      print(e.toString());
      WriteImageFile(filename, byte);
    }
  }

  void WriteTemplateFile(String filename, Uint8List byte) async {
    try {
      final directory = await getExternalStorageDirectory();
      final dirPath = '${directory?.path}/FingerData/Template/$filename';
      File file = File(dirPath);
      bool isExist = false;
      file.exists().then((result) => isExist = result);
      file.create(recursive: true);
      var myFile = File(dirPath);
      var sink = myFile.openWrite();
      myFile.writeAsBytes(byte);
      await sink.flush();
      await sink.close();
      if (isImageSaved) {
        setLogs("Image & Template Saved", false);
      } else {
        setLogs("Template Saved", false);
      }
    } catch (e) {
      print(e.toString());
      WriteTemplateFile(filename, byte);
    }
  }

  void StopCature() async {
    try {
      FocusScope.of(context).requestFocus(_focusNode);
      int ret = await MorfinauthUsb.StopCature(); // UPDATED
      String error = await MorfinauthUsb.GetErrorMessage(ret); // UPDATED
      isStopCapture = true;
      setLogs("StopCapture: $ret ($error)", false);
      okCapture = 0;
    } catch (e) {
      setLogs("Error", true);
    }
  }

  void StartCapture() async {
    okCapture = 1;

    validateValues();
    qualitySaved();
    timeoutValueSaved();

    try {
      if (deviceInfoObject == null) {
        setLogs("Please run device init first", true);
        setState(() {
          displayImage = 0;
        });
        Navigator.pop(context);
        return;
      } else if (await MorfinauthUsb.IsCaptureRunning()) { // UPDATED
        setLogs("${"StartCapture Ret: $CAPTURE_ALREADY_STARTED ""(${await MorfinauthUsb // UPDATED
            .GetErrorMessage(CAPTURE_ALREADY_STARTED)}"})",
            true);
        return;
      } else {
        setState(() {
          displayImage = 1;
          image_path = "assets/images/img_white_image.png";
        });
        scannerAction = ScannerAction.Capture;
        isAutoCapture = false;
        setLogs("", false);
        int   ret = await MorfinauthUsb.StartCapture(timeout, minQuality); // UPDATED
        await (ret);
        String error = await MorfinauthUsb.GetErrorMessage(ret); // UPDATED
        await (error);
        isStopCapture = false;
        setLogs("StartCapture Ret: $ret ($error)", ret == 0 ? false : true);
      }
    } catch (e) {
      okCapture = 0;
      setLogs(e.toString(), true);
    }
  }

  void setLogs(String errorMessage, bool isError) {
    setState(() {
      messsageText = errorMessage;
      if (isError) {
        isMessageError = true;
        print("Error====>$errorMessage");
      } else {
        isMessageError = false;
        print("Message====>$errorMessage");
      }
    });
  }

  void validateValues() {
    int? imageQuality = int.tryParse(imageQualityController.text);
    int? timeout = int.tryParse(timeoutController.text);

    if (imageQuality == null || imageQuality < 1 || imageQuality > 100) {
      imageQualityController.text = '60';
    }

    if (timeout == null || timeout < 10000) {
      timeoutController.text = '10000';
    }
  }

  void qualitySaved() {
    int quality = int.parse(imageQualityController.text.toString().trim());
    Provider.of<SettingProvider>(context, listen: false).setQuality(quality);
  }

  void timeoutValueSaved() {
    if (timeoutController.text.toString().trim().isNotEmpty) {
      int tValue = int.parse(timeoutController.text.toString().trim());
      Provider.of<SettingProvider>(context, listen: false).settimeOut(tValue);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    imageQualityController.dispose();
    timeoutController.dispose();
    super.dispose();
  }

  void refreshPage() {
    callBackReqister();
    getDeviceObject();
    String name = getDeviceStatusInfo();
    setState(() {
      deviceInfo = name;
    });
  }

  @override
  void BottomDialogRefresh(bool isRefresh) {
    refreshPage();
  }
}