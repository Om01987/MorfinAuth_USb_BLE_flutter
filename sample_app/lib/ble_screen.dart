import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// Make sure this imports your new plugin file
import 'package:morfinauth_ble/morfinauth_ble.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({Key? key}) : super(key: key);

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  // Subscriptions for our 3 continuous streams
  StreamSubscription? _discoverySub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _notificationSub;

  bool _isScanning = false;
  bool _isCapturing = false;
  String _connectionStatus = "DISCONNECTED";
  List<Map<String, dynamic>> _discoveredDevices = [];

  Uint8List? _finalTemplateBytes;
  int _currentQuality = 0;
  int _currentNfiq = 0;

  @override
  void initState() {
    super.initState();
    _listenToBleStreams();
  }

  // --- NATIVE BRIDGE COMMUNICATION --- //

  void _listenToBleStreams() {
    // 1. Listen to Discovered Devices
    _discoverySub = MorfinauthBle.discoveredDevicesStream.listen((device) {
      setState(() {
        bool exists = _discoveredDevices.any((d) => d['address'] == device['address']);
        if (!exists) {
          _discoveredDevices.add(device);
        }
      });
    });

    // 2. Listen to Connection Status (CONNECTED, DISCONNECTED, etc.)
    _connectionSub = MorfinauthBle.connectionStatusStream.listen((status) {
      setState(() {
        _connectionStatus = status;
        if (_connectionStatus == "CONNECTED") {
          _isScanning = false;
          _discoveredDevices.clear(); // Clean up list
        }
      });
    });

    // 3. Listen to Hardware Notifications (e.g. "Battery Low")
    _notificationSub = MorfinauthBle.hardwareNotificationStream.listen((notification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner Alert: $notification')),
        );
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    await MorfinauthBle.discoverDevices();

    // Auto-stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isScanning) {
        setState(() => _isScanning = false);
        MorfinauthBle.stopDiscover();
      }
    });
  }

  Future<void> _connectToDevice(String macAddress) async {
    await MorfinauthBle.stopDiscover();
    setState(() => _isScanning = false);
    await MorfinauthBle.connectDevice(macAddress);
  }

  Future<void> _startCaptureFlow() async {
    setState(() {
      _isCapturing = true;
      _finalTemplateBytes = null;
      _currentQuality = 0;
    });

    try {
      // format: 1 (e.g. ISO_2005), minQuality: 60, timeout: 10000ms
      final result = await MorfinauthBle.startCapture(1, 60, 10000);

      setState(() {
        _isCapturing = false;
        if (result['status'] == 0) {
          _currentQuality = result['quality'] ?? 0;
          _currentNfiq = result['nfiq'] ?? 0;
          if (result.containsKey('templateData')) {
            _finalTemplateBytes = result['templateData'] as Uint8List;
          }
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capture Success!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture Failed/Timeout. Status: ${result['status']}')));
        }
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- UI RENDERING --- //

  @override
  Widget build(BuildContext context) {
    bool isConnected = _connectionStatus == "CONNECTED";

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        backgroundColor: isConnected ? Colors.green : Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Header
            Text("Status: $_connectionStatus",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- NOT CONNECTED: Show Scanner --- //
            if (!isConnected) ...[
              ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                child: Text(_isScanning ? 'Scanning...' : 'Scan for BLE Scanners'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device['name'] ?? 'Unknown Device'),
                      subtitle: Text(device['address'] ?? ''),
                      trailing: ElevatedButton(
                        child: const Text('Connect'),
                        onPressed: () => _connectToDevice(device['address']),
                      ),
                    );
                  },
                ),
              )
            ],

            // --- CONNECTED: Show Fingerprint Capture UI --- //
            if (isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Note: Usually you pass an encrypted ClientKey here
                      await MorfinauthBle.initDevice("");
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device Initialized')));
                    },
                    child: const Text('Init Device'),
                  ),
                  ElevatedButton(
                    onPressed: _isCapturing ? null : _startCaptureFlow,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: Text(_isCapturing ? 'Capturing...' : 'Sync Capture'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // The Fingerprint Status Container
              Container(
                height: 250,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  color: Colors.grey[200],
                ),
                child: Center(
                  child: _isCapturing
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Place Finger on Scanner")
                    ],
                  )
                      : _finalTemplateBytes != null
                      ? const Icon(Icons.fingerprint, size: 100, color: Colors.green)
                      : const Text("Ready to Capture"),
                ),
              ),
              const SizedBox(height: 10),

              if (_finalTemplateBytes != null) ...[
                Text("Capture Quality: $_currentQuality%", style: const TextStyle(fontSize: 16)),
                Text("NFIQ Score: $_currentNfiq", style: const TextStyle(fontSize: 16)),
                Text("Template Size: ${_finalTemplateBytes!.length} bytes", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],

              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await MorfinauthBle.unInitDevice();
                  await MorfinauthBle.disconnect();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Disconnect'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    _connectionSub?.cancel();
    _notificationSub?.cancel();
    MorfinauthBle.disconnect();
    super.dispose();
  }
}