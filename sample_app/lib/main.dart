import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_screen.dart';

void main() {
  runApp(const MorfinAuthApp());
}

class MorfinAuthApp extends StatelessWidget {
  const MorfinAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MorfinAuth SDK',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ConnectionModeScreen(),
    );
  }
}

class ConnectionModeScreen extends StatelessWidget {
  const ConnectionModeScreen({super.key});

  Future<void> _startBleMode(BuildContext context) async {
    // 1. Request strict BLE & Location permissions required by Android
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      // 2. Navigate to our new BLE Screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BleScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BLE Permissions are required!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Mode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.usb),
              label: const Text('Start USB Mode (Legacy)'),
              onPressed: () {
                // Navigate to  old USB UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('USB Mode - not implemented')),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text('Start BLE Mode (New)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () => _startBleMode(context),
            ),
          ],
        ),
      ),
    );
  }
}