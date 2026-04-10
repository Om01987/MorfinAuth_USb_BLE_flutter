import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:morfinauth_ble/morfinauth_ble.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({super.key});

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  final MorfinauthBle _blePlugin = MorfinauthBle();
  StreamSubscription? _bleSubscription;

  bool _isScanning = false;
  String _connectionStatus = "DISCONNECTED";
  List<Map<String, dynamic>> _discoveredDevices = [];

  Uint8List? _previewImageBytes; // Holds the live fingerprint image
  int _currentQuality = 0;

  @override
  void initState() {
    super.initState();
    _listenToBleEvents();
  }

  // --- NATIVE BRIDGE COMMUNICATION --- //

  void _listenToBleEvents() {
    // Listen to the EventChannel we created in Java
    _bleSubscription = _blePlugin.bleEventStream.listen((event) {
      final Map<dynamic, dynamic> data = event as Map;
      final String eventType = data['event'];

      setState(() {
        if (eventType == 'OnDeviceDiscovered') {
          // Check if device already exists in list before adding
          bool exists = _discoveredDevices.any((d) => d['macAddress'] == data['macAddress']);
          if (!exists) {
            _discoveredDevices.add({
              'name': data['name'] ?? 'Unknown Device',
              'macAddress': data['macAddress']
            });
          }
        }
        else if (eventType == 'OnDeviceConnectionStatus') {
          _connectionStatus = data['state'];
          if (_connectionStatus == "CONNECTED") {
            _discoveredDevices.clear(); // Hide scan list once connected
          }
        }
        else if (eventType == 'OnPreview') {
          // Render the live fingerprint array from Java!
          _currentQuality = data['quality'];
          _previewImageBytes = data['image'];
        }
      });
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });
    await _blePlugin.discoverDevices();

    // Stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _isScanning = false);
        _blePlugin.stopDiscover();
      }
    });
  }

  Future<void> _connectToDevice(String macAddress) async {
    await _blePlugin.stopDiscover();
    setState(() => _isScanning = false);
    await _blePlugin.connectDevice(macAddress);
  }

  // --- UI RENDERING --- //

  @override
  Widget build(BuildContext context) {
    bool isConnected = _connectionStatus == "CONNECTED";

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        backgroundColor: isConnected ? Colors.green : Colors.blue,
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
                child: Text(_isScanning ? 'Scanning...' : 'Scan for Fingerprint Scanners'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device['name']),
                      subtitle: Text(device['macAddress']),
                      trailing: ElevatedButton(
                        child: const Text('Connect'),
                        onPressed: () => _connectToDevice(device['macAddress']),
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
                    onPressed: () => _blePlugin.initDevice(),
                    child: const Text('Init Device'),
                  ),
                  ElevatedButton(
                    onPressed: () => _blePlugin.startCapture(60, 10000), // Quality 60, 10 sec timeout
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Start Capture'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // The Fingerprint Image Container
              Container(
                height: 250,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  color: Colors.grey[200],
                ),
                child: _previewImageBytes != null
                    ? Image.memory(_previewImageBytes!, fit: BoxFit.contain, gaplessPlayback: true)
                    : const Center(child: Text("Place Finger")),
              ),
              const SizedBox(height: 10),
              Text("Capture Quality: $_currentQuality%",
                  style: const TextStyle(fontSize: 16)),

              const Spacer(),
              ElevatedButton(
                onPressed: () => _blePlugin.disconnectDevice(),
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
    _bleSubscription?.cancel();
    _blePlugin.disconnectDevice();
    super.dispose();
  }
}