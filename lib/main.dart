import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Scanner App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WiFiScannerScreen(),
    );
  }
}

class WiFiScannerScreen extends StatefulWidget {
  const WiFiScannerScreen({super.key});

  @override
  State<WiFiScannerScreen> createState() => _WiFiScannerScreenState();
}

class _WiFiScannerScreenState extends State<WiFiScannerScreen> {
  // Demo WiFi networks for prototype
  final List<Map<String, dynamic>> demoNetworks = [
    {"ssid": "Parth's Wifi", "level": -45},
    {"ssid": "Deeps Wifi", "level": -67},
    {"ssid": "abcd-7869-qwer", "level": -89},
    {"ssid": "HomeNetwork_5G", "level": -52},
    {"ssid": "CoffeeShop_Free", "level": -71},
    {"ssid": "Office_WiFi", "level": -38},
    {"ssid": "Neighbor_Net", "level": -78},
    {"ssid": "Guest_Network", "level": -65},
    {"ssid": "IoT_Devices", "level": -82},
    {"ssid": "SmartTV_2.4GHz", "level": -58},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WIFI SHOWN NEARBY'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: demoNetworks.length,
              itemBuilder: (context, index) {
                final network = demoNetworks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            network["ssid"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${network["level"]}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Demo scan - just refresh the UI
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[200],
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSignalIcon(int level) {
    if (level > -50) return Icons.signal_cellular_alt;
    if (level > -60) return Icons.signal_cellular_alt;
    if (level > -70) return Icons.signal_cellular_alt;
    return Icons.signal_cellular_alt;
  }

  Color _getSignalColor(int level) {
    if (level > -50) return Colors.green;
    if (level > -60) return Colors.yellow[700]!;
    if (level > -70) return Colors.orange;
    return Colors.red;
  }
}
