import 'package:flutter/material.dart';
import 'wifi_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Scanner App'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Welcome to WiFi Scanner',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WifiScannerScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.wifi_find, color: Colors.white),
      ),
    );
  }
}
