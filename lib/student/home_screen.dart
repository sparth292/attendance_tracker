import 'package:flutter/material.dart';
import 'wifi_scanner_screen.dart';
import 'package:attendance_tracker/timetable_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Year Project', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFA50C22),
      ),
      body: const Center(
        child: Text(
          'App under development',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),

      // 🔥 Multiple FABs
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WiFi Scanner Button
          FloatingActionButton(
            heroTag: "wifiBtn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WifiScannerScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFFA50C22),
            child: const Icon(Icons.wifi_find, color: Colors.white),
          ),

          const SizedBox(height: 12),

          // Timetable Button
          FloatingActionButton(
            heroTag: "timetableBtn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TimetableScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFFA50C22),
            child: const Icon(Icons.schedule, color: Colors.white),
          ),
        ],
      ),
    );
  }
}