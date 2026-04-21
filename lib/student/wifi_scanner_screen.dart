import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class WifiScanner {
  static Future<void> startScan() async {
    print('Starting WiFi scan...');

    try {
      // Check and request location permission
      PermissionStatus permission = await Permission.location.status;
      if (!permission.isGranted) {
        permission = await Permission.location.request();
        if (!permission.isGranted) {
          print('Location permission is required for WiFi scanning.');
          return;
        }
      }

      // Check if location services are enabled
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        print(
          'Location services are disabled. Please enable location services to scan for WiFi networks.',
        );
        return;
      }

      // Check if WiFi scanning is supported
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        String errorMsg = 'Cannot start WiFi scan: ';
        if (canScan == CanStartScan.noLocationPermissionDenied) {
          errorMsg +=
              'Location permission denied. Please enable it in app settings.';
        } else if (canScan == CanStartScan.noLocationServiceDisabled) {
          errorMsg +=
              'Location services are disabled. Please enable them in device settings.';
        } else {
          errorMsg += canScan.toString();
        }
        print(errorMsg);
        return;
      }

      // Start scan and get results
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();

      print('\n=== WiFi Scan Results ===');
      print('Found ${results.length} networks:');

      for (int i = 0; i < results.length; i++) {
        final ap = results[i];
        print(
          '\n${i + 1}. SSID: ${ap.ssid.isNotEmpty ? ap.ssid : 'Hidden Network'}',
        );
        print('   BSSID: ${ap.bssid}');
        print('   Signal: ${ap.level} dBm');
        print('   Frequency: ${ap.frequency} MHz');
      }

      print('\n=== End of Scan Results ===\n');
    } catch (e) {
      print('Error scanning for WiFi: $e');
    }
  }
}

// Main function to run the WiFi scanner
void main() async {
  print('WiFi Scanner Background Service');
  print('===============================');

  // Run scan immediately
  await WifiScanner.startScan();

  // Optional: Run scan periodically every 30 seconds
  print('Starting periodic scans (every 30 seconds)...');
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    await WifiScanner.startScan();
  }
}
