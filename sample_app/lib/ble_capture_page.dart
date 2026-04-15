import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:morfinauth_ble/morfinauth_ble.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../provider/DeviceInfoProvider.dart';
import '../helper/CommonWidget.dart';
import 'helper/BottomNavigationDialogListener.dart';

class BleCapturePage extends StatefulWidget {
  const BleCapturePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BleCapturePageState();
}

class BleCapturePageState extends State<BleCapturePage> implements BottomDialogRefreshListener {
  final MorfinauthBle _morfinauthBlePlugin = MorfinauthBle();
  final _focusNode = FocusNode();

  String deviceInfo = "Device Status: Connected (BLE)";
  String messsageText = "Ready to Capture";
  bool isMessageError = false;

  // Image Display States: 0 = Lottie Animation, 1 = Raw Bytes
  int displayImage = 0;
  Uint8List? byteImage;
  StreamSubscription? _imageStreamSub;

  TextEditingController imageQualityController = TextEditingController(text: '60');
  TextEditingController timeoutController = TextEditingController(text: '10000');

  @override
  void initState() {
    super.initState();
    _setupBleImageStream();

    // Fetch initial device name from provider
    String deviceName = Provider.of<DeviceInfoProvider>(context, listen: false).deviceNameStatus;
    if (deviceName.isNotEmpty) {
      deviceInfo = deviceName;
    }
  }

  void _setupBleImageStream() {
    // Listen for the live image coming from the Native BLE Plugin
    _imageStreamSub = _morfinauthBlePlugin.imageStream.listen((Uint8List incomingImageBytes) {
      if (mounted) {
        setState(() {
          displayImage = 1;
          byteImage = incomingImageBytes;
          setLogs("Image Received Successfully!", false);
        });
      }
    }, onError: (error) {
      setLogs("Image Stream Error: $error", true);
    });
  }

  void StartCapture() async {
    FocusScope.of(context).requestFocus(_focusNode);
    setState(() {
      displayImage = 0;
      byteImage = null;
    });

    int quality = int.tryParse(imageQualityController.text) ?? 60;
    int timeout = int.tryParse(timeoutController.text) ?? 10000;

    setLogs("Starting Capture... Please place finger on scanner.", false);

    try {
      // Format 1 is generally standard (FIR_2005)
      Map<String, dynamic> result = await _morfinauthBlePlugin.startCapture(1, quality, timeout);

      if (result['status'] == 0) {
        setLogs("Capture Complete. Quality: ${result['quality']} | NFIQ: ${result['nfiq']}", false);
      } else {
        setLogs("Capture Failed or Timed Out (Status: ${result['status']})", true);
      }
    } catch (e) {
      setLogs("Error starting capture: $e", true);
    }
  }

  void StopCapture() async {
    FocusScope.of(context).requestFocus(_focusNode);
    try {
      await _morfinauthBlePlugin.stopCapture();
      setLogs("Capture Stopped.", false);
    } catch (e) {
      setLogs("Error stopping capture.", true);
    }
  }

  void setLogs(String errorMessage, bool isError) {
    if (mounted) {
      setState(() {
        messsageText = errorMessage;
        isMessageError = isError;
        print(isError ? "Error====>$errorMessage" : "Message====>$errorMessage");
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    imageQualityController.dispose();
    timeoutController.dispose();
    _imageStreamSub?.cancel(); // Important: Prevent memory leaks
    super.dispose();
  }

  @override
  void BottomDialogRefresh(bool isRefresh) {
    if (isRefresh) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("BLE Capture Page")),
      bottomNavigationBar: CommonWidget.getBottomNavigationWidget(context, deviceInfo, this),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configurations
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: imageQualityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Quality [1-100]',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: timeoutController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'TIMEOUT (ms)',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Buttons
            const Text('Perform Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: StartCapture,
                    child: const Text('Start Capture'),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: StopCapture,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: const Text('Stop Capture'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // Fingerprint Display
            const Text('Fingerprint Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Expanded(child: getCardView()),
          ],
        ),
      ),
    );
  }

  Widget getCardView() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
        side: const BorderSide(color: Colors.blue, width: 3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              messsageText,
              style: TextStyle(color: isMessageError ? Colors.red : Colors.blue, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(child: onImageDynamic()),
          ],
        ),
      ),
    );
  }

  Widget onImageDynamic() {
    if (displayImage == 0 || byteImage == null) {
      return Lottie.asset(
        'assets/animations/fingerprint.json',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      );
    } else {
      return Image.memory(byteImage!, fit: BoxFit.contain);
    }
  }
}