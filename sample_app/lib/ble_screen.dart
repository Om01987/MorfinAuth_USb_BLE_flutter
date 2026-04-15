import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:morfinauth_ble/morfinauth_ble.dart'; // Phase 1 & 2 Plugin
import 'package:permission_handler/permission_handler.dart'; // Phase 4 Permissions

import 'ble_capture_page.dart';

import 'provider/DeviceInfoProvider.dart';
import 'provider/SettingProvider.dart';
import 'provider/clientKeyProvider.dart';
import 'CapturePage.dart';
import 'helper/BottomNavigationDialogListener.dart';
import 'helper/CommonWidget.dart';
import 'helper/SharePreferenceHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'helper/DeviceInfo.dart';
import 'dart:convert';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart' as pc;

class BleScreen extends StatefulWidget {
  const BleScreen({Key? key}) : super(key: key);

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> implements BottomDialogRefreshListener {
  final MorfinauthBle _morfinauthBlePlugin = MorfinauthBle();

  // Streams
  StreamSubscription? _discoverySub;
  StreamSubscription? _connectionSub;

  List<Map<String, dynamic>> _discoveredDevices = [];
  bool _isScanning = false;

  String deviceInfo = "Device Status: Not Connected";
  String _platformVersion = 'Unknown';
  String GET_SDK_VERSION = "SDK Version: ";

  TextEditingController getKeyController = TextEditingController();
  TextEditingController setKeyController = TextEditingController();

  late SharePreferenceHelper sharePreferenceHelper;
  DeviceInfo? deviceInfoObject;

  @override
  void initState() {
    super.initState();
    sharePreferenceHelper = SharePreferenceHelper();
    sharePreferenceHelper.setDeviceInfo("");

    // 1. Request OS Permissions first (Phase 4)
    requestBlePermissions().then((_) {
      // 2. Setup BLE Listeners
      _listenToBleStreams();
      // 3. Mock or fetch SDK versions
      GetSDKVersion();
    });
  }

  // ==========================================
  // PHASE 4: PERMISSIONS
  // ==========================================
  Future<void> requestBlePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted) {
      Fluttertoast.showToast(msg: "BLE Scan Permission required!");
    }
  }

  // ==========================================
  // PHASE 3: BLE LOGIC & STREAMS
  // ==========================================
  void _listenToBleStreams() {
    // Listen for devices popping up during a scan
    _discoverySub = _morfinauthBlePlugin.discoveredDevicesStream.listen((device) {
      setState(() {
        bool exists = _discoveredDevices.any((d) => d['address'] == device['address']);
        if (!exists) {
          _discoveredDevices.add(device);
        }
      });
    });

    // Listen for successful connections/disconnections
    _connectionSub = _morfinauthBlePlugin.connectionStatusStream.listen((status) async {
      if (status == "CONNECTED") {
        setState(() {
          _isScanning = false;
          deviceInfo = "Device Status: Connected (BLE)";
        });

        // Sync with your Provider so CapturePage.dart knows it's allowed to run
        Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceConnectedStatus(true);
        Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceNameStatus(deviceInfo);

        // Initialize the device after connecting
        /*String currentClientKey = Provider.of<clientKeyProvider>(context, listen: false).clientKey ?? "";
        await _morfinauthBlePlugin.initDevice(currentClientKey);*/

        String currentClientKey = setKeyController.text.trim();
        await _morfinauthBlePlugin.initDevice(currentClientKey);

        Fluttertoast.showToast(msg: "BLE Device Connected & Initialized");
      } else if (status == "DISCONNECTED") {
        setState(() {
          deviceInfo = "Device Status: Disconnected";
        });
        Provider.of<DeviceInfoProvider>(context, listen: false).setDeviceConnectedStatus(false);
      }
    });
  }

  void _showBleScanDialog() {
    setState(() {
      _discoveredDevices.clear();
      _isScanning = true;
    });

    _morfinauthBlePlugin.discoverDevices();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select BLE Device'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              // We use a Future.delayed loop here to force the dialog to rebuild as the main state updates the list
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _isScanning) dialogSetState(() {});
              });

              return SizedBox(
                width: double.maxFinite,
                height: 300,
                child: _discoveredDevices.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(device['name'] ?? 'Unknown'),
                      subtitle: Text(device['address'] ?? ''),
                      onTap: () {
                        _morfinauthBlePlugin.stopDiscover();
                        _morfinauthBlePlugin.connectDevice(device['address']);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel / Stop'),
              onPressed: () {
                _morfinauthBlePlugin.stopDiscover();
                setState(() => _isScanning = false);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      _morfinauthBlePlugin.stopDiscover();
      setState(() => _isScanning = false);
    });
  }

  // ==========================================
  // USB UI PARITY METHODS
  // ==========================================
  Future<void> GetSDKVersion() async {
    // Replace with real BLE SDK call if implemented in native wrapper
    setState(() {
      _platformVersion = "Morfin Auth SDK 2.0.0.8";
    });
  }

  Future<String> genClientKey(String clientKey) async {
    // Identical RSA logic from USB Screen
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
      final cleanPem = pubKeyPem.replaceAll(RegExp(r"-----(BEGIN|END) PUBLIC KEY-----|\s+"), "");
      final derBytes = base64.decode(cleanPem);
      final asn1Parser = ASN1Parser(derBytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
      final publicKeySeq = ASN1Parser(publicKeyBitString.contentBytes()!).nextObject() as ASN1Sequence;

      final modulus = (publicKeySeq.elements[0] as ASN1Integer).valueAsBigInteger;
      final exponent = (publicKeySeq.elements[1] as ASN1Integer).valueAsBigInteger;

      final rsaPublicKey = pc.RSAPublicKey(modulus!, exponent!);
      final rsaEngine = pc.OAEPEncoding.withSHA256(pc.RSAEngine());
      rsaEngine.init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(rsaPublicKey));

      final epochSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final finalKey = utf8.encode(epochSeconds + clientKey);
      final encryptedBytes = rsaEngine.process(Uint8List.fromList(finalKey));

      return base64.encode(encryptedBytes);
    } catch (e) {
      rethrow;
    }
  }

  void _reload() {
    setState(() {});
  }

  @override
  void BottomDialogRefresh(bool isRefresh) {
    if (isRefresh) _reload();
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    _connectionSub?.cancel();
    _morfinauthBlePlugin.disconnect();
    super.dispose();
  }

  // ==========================================
  // UI RENDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Dashboard'),
      ),
      bottomNavigationBar: CommonWidget.getBottomNavigationWidget(context, deviceInfo, this),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // 1. Scan & Connect Button (Unique to BLE)
              ElevatedButton.icon(
                onPressed: _showBleScanDialog,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text("Scan & Connect BLE Scanner"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 15.0),

              // 2. SDK Info Box
              Container(
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "SDK Version: $_platformVersion\n\n$deviceInfo\n",
                  style: const TextStyle(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20.0),

              // 3. Get Key
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: getKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Get Key for (click here)',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        hintText: 'Get Key',
                      ),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      if (getKeyController.text.trim().isEmpty) return;
                      try {
                        String key = await genClientKey(getKeyController.text.trim());
                        setKeyController.text = key;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Key Generated")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => getKeyController.clear(),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // 4. Set Key
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: setKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Set Key for (click here)',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        hintText: 'Set Key',
                      ),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      Provider.of<clientKeyProvider>(context, listen: false).updateStoredValue(setKeyController.text);
                      Fluttertoast.showToast(msg: "Key Saved to Provider");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setKeyController.clear(),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // 5. Capture Card
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: getCardView(),
                  ),
                ],
              ),
              const SizedBox(height: 30.0),

              // 6. Footer
              Image.asset('assets/images/company_logo.png', width: 250.0, height: 100.0),
              const Text("Mantra Softtech India PVT LTD © 2023", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCardView() {
    return SizedBox(
      height: 200,
      child: InkWell(
        onTap: () {
          bool isConnect = Provider.of<DeviceInfoProvider>(context, listen: false).isDeviceConnected;
          if (isConnect) {
            Navigator.push(
              context,
              //MaterialPageRoute(builder: (context) => const CapturePage()),
              MaterialPageRoute(builder: (context) => const BleCapturePage()),
            ).then((res) => _reload());
          } else {
            Fluttertoast.showToast(
              msg: "Please connect a BLE device first",
              toastLength: Toast.LENGTH_SHORT,
              backgroundColor: Colors.blue,
            );
          }
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
            side: const BorderSide(color: Colors.blue, width: 3.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/animations/fingerprint.json', width: 150, height: 150, fit: BoxFit.cover),
              const Text("Capture Test (BLE)"),
            ],
          ),
        ),
      ),
    );
  }
}