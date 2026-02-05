import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Scanner',
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
  List<WifiNetwork> wifiNetworks = [];
  bool _isScanning = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    print('Checking permissions...');
    
    // Check and request multiple permissions
    var locationStatus = await Permission.locationWhenInUse.status;
    print('Location permission status: $locationStatus');
    
    if (!locationStatus.isGranted) {
      print('Requesting location permission...');
      locationStatus = await Permission.locationWhenInUse.request();
      print('Location permission after request: $locationStatus');
    }
    
    if (locationStatus.isGranted) {
      print('Permission granted, starting scan...');
      _startScan();
    } else {
      print('Permission denied');
      setState(() {
        _hasError = true;
        _errorMessage = 'Location permission is required to scan WiFi networks. Please grant permission in Settings.';
      });
    }
  }

  Future<void> _startScan() async {
    print('Starting WiFi scan...');
    setState(() {
      _isScanning = true;
      _hasError = false;
      wifiNetworks.clear();
    });

    try {
      // Check if WiFi is enabled
      print('Checking WiFi status...');
      bool isWifiEnabled = await WiFiForIoTPlugin.isEnabled();
      print('WiFi enabled: $isWifiEnabled');
      
      if (!isWifiEnabled) {
        setState(() {
          _isScanning = false;
          _hasError = true;
          _errorMessage = 'WiFi is disabled. Please enable WiFi on your device and try again.';
        });
        return;
      }

      // Get WiFi networks directly
      print('Scanning for WiFi networks...');
      final networks = await WiFiForIoTPlugin.loadWifiList();
      print('Found ${networks?.length ?? 0} WiFi networks');
      
      if (networks != null) {
        for (int i = 0; i < networks.length; i++) {
          final network = networks[i];
          print('Network $i: SSID="${network.ssid}", Level=${network.level}, Frequency=${network.frequency}');
        }
      }
      
      setState(() {
        wifiNetworks = networks ?? [];
        _isScanning = false;
        print('Displaying ${wifiNetworks.length} networks');
      });
      
    } catch (e) {
      print('Error during scan: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isScanning = false;
        _hasError = true;
        _errorMessage = 'Error scanning WiFi: $e\n\nPlease ensure:\n1. WiFi is enabled\n2. Location permission is granted\n3. Location services are turned on\n\nYou may need to grant WiFi scanning permissions in device settings.';
      });
    }
  }

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
            child: _hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _startScan,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : wifiNetworks.isEmpty && !_isScanning
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No WiFi networks found\nTap Scan to search for networks',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: wifiNetworks.length,
                        itemBuilder: (context, index) {
                          final network = wifiNetworks[index];
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          network.ssid ?? 'Unknown Network',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (network.frequency is int ? network.frequency! : int.tryParse(network.frequency.toString()) ?? 0) > 5000 ? '5GHz' : '2.4GHz',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${network.level ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        _getSignalIcon(network.level ?? 0),
                                        size: 16,
                                        color: _getSignalColor(network.level ?? 0),
                                      ),
                                    ],
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
                onPressed: _isScanning ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[200],
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isScanning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Scanning...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
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
