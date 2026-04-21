import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WifiScanner {
  static const String targetSSID = 'SOMAIYA-AP';
  static const String baseUrl = "http://13.235.16.3:5000";

  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final url = Uri.parse("$baseUrl/sessions/active");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to fetch active sessions");
    }
  }

  static Future<void> startScan() async {
    print('Starting WiFi scan...');

    try {
      // For Windows - use netsh command
      if (Platform.isWindows) {
        await _scanWindows();
      }
      // For macOS - use airport command
      else if (Platform.isMacOS) {
        await _scanMacOS();
      }
      // For Linux - use iwlist or nmcli
      else if (Platform.isLinux) {
        await _scanLinux();
      } else {
        print('Platform not supported for WiFi scanning');
        return;
      }
    } catch (e) {
      print('Error scanning for WiFi: $e');
    }
  }

  static Future<void> _scanWindows() async {
    try {
      print('Scanning WiFi networks on Windows...');

      // Use netsh to scan for available networks
      ProcessResult result = await Process.run('netsh', [
        'wlan',
        'show',
        'networks',
        'mode=bssid',
      ]);

      if (result.exitCode == 0) {
        String output = result.stdout.toString();
        _parseWindowsOutput(output);
      } else {
        print('Failed to scan WiFi networks: ${result.stderr}');
      }
    } catch (e) {
      print('Error scanning Windows WiFi: $e');
    }
  }

  static Future<void> _scanMacOS() async {
    try {
      print('Scanning WiFi networks on macOS...');

      // Use airport command to scan for networks
      ProcessResult result = await Process.run(
        '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport',
        ['-s'],
      );

      if (result.exitCode == 0) {
        String output = result.stdout.toString();
        _parseMacOSOutput(output);
      } else {
        print('Failed to scan WiFi networks: ${result.stderr}');
      }
    } catch (e) {
      print('Error scanning macOS WiFi: $e');
    }
  }

  static Future<void> _scanLinux() async {
    try {
      print('Scanning WiFi networks on Linux...');

      // Try nmcli first
      ProcessResult result = await Process.run('nmcli', [
        'device',
        'wifi',
        'list',
      ]);

      if (result.exitCode == 0) {
        String output = result.stdout.toString();
        _parseLinuxOutput(output);
      } else {
        // Fallback to iwlist
        result = await Process.run('iwlist', ['scan']);
        if (result.exitCode == 0) {
          String output = result.stdout.toString();
          _parseIwlistOutput(output);
        } else {
          print('Failed to scan WiFi networks: ${result.stderr}');
        }
      }
    } catch (e) {
      print('Error scanning Linux WiFi: $e');
    }
  }

  static Future<void> _parseWindowsOutput(String output) async {
    print('\n=== WiFi Scan Results ===');

    List<String> lines = output.split('\n');
    List<Map<String, String>> networks = [];

    Map<String, String> currentNetwork = {};

    for (String line in lines) {
      line = line.trim();

      if (line.startsWith('SSID')) {
        if (currentNetwork.isNotEmpty) {
          networks.add(currentNetwork);
        }
        currentNetwork = {
          'SSID': line.split(':').last.trim(),
          'BSSID': '',
          'Signal': '',
          'Frequency': '',
        };
      } else if (line.startsWith('BSSID')) {
        currentNetwork['BSSID'] = line.split(':').last.trim();
      } else if (line.contains('Signal')) {
        currentNetwork['Signal'] = line.split(':').last.trim();
      } else if (line.contains('Channel')) {
        currentNetwork['Frequency'] = line.split(':').last.trim();
      }
    }

    if (currentNetwork.isNotEmpty) {
      networks.add(currentNetwork);
    }

    print('Found ${networks.length} networks:');

    for (int i = 0; i < networks.length; i++) {
      final network = networks[i];
      print('\n${i + 1}. SSID: ${network['SSID'] ?? 'Hidden Network'}');
      print('   BSSID: ${network['BSSID'] ?? 'N/A'}');
      print('   Signal: ${network['Signal'] ?? 'N/A'}');
      print('   Frequency: ${network['Frequency'] ?? 'N/A'}');
    }

    print('\n=== End of Scan Results ===\n');

    // Check for target network and make API call if found
    await _checkTargetNetworkAndCallAPI(networks);
  }

  static Future<void> _checkTargetNetworkAndCallAPI(
    List<Map<String, String>> networks,
  ) async {
    bool foundTargetNetwork = false;

    for (int i = 0; i < networks.length; i++) {
      final network = networks[i];
      String ssid = network['SSID'] ?? 'Hidden Network';

      if (ssid == targetSSID) {
        foundTargetNetwork = true;
        print('   *** TARGET NETWORK FOUND: $targetSSID ***');
        break;
      }
    }

    if (foundTargetNetwork) {
      print(
        '🎯 Target network "$targetSSID" detected! Fetching active sessions...',
      );
      await _fetchActiveSessionsAndDisplay();
    } else {
      print(
        '❌ Target network "$targetSSID" not found. Device not in range of college.',
      );
    }
  }

  static Future<void> _fetchActiveSessionsAndDisplay() async {
    try {
      print('📡 Fetching active sessions from API...');
      final sessions = await getActiveSessions();
      print('✅ Successfully fetched ${sessions.length} active sessions');

      if (sessions.isEmpty) {
        print('📋 No active sessions currently available');
      } else {
        print('📋 Active Sessions:');
        for (int i = 0; i < sessions.length; i++) {
          final session = sessions[i];
          print('   ${i + 1}. Course: ${session['course_code'] ?? 'N/A'}');
          print('      Faculty: ${session['faculty_id'] ?? 'N/A'}');
          print(
            '      Time: ${session['start_time'] ?? 'N/A'} - ${session['end_time'] ?? 'N/A'}',
          );
          print('      Session ID: ${session['session_id'] ?? 'N/A'}');
          if (i < sessions.length - 1) print('');
        }
      }
    } catch (e) {
      print('❌ Error fetching active sessions: $e');
    }
  }

  static Future<void> _parseMacOSOutput(String output) async {
    print('\n=== WiFi Scan Results ===');

    List<String> lines = output.split('\n');
    List<Map<String, String>> networks = [];

    // Skip header line
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // Parse macOS airport output format
      List<String> parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 6) {
        String ssid = parts.sublist(0, parts.length - 5).join(' ');
        String bssid = parts[parts.length - 5];
        String rssi = parts[parts.length - 4];
        String channel = parts[parts.length - 2];

        networks.add({
          'SSID': ssid,
          'BSSID': bssid,
          'Signal': '$rssi dBm',
          'Frequency': 'Channel $channel',
        });
      }
    }

    print('Found ${networks.length} networks:');

    for (int i = 0; i < networks.length; i++) {
      final network = networks[i];
      print('\n${i + 1}. SSID: ${network['SSID'] ?? 'Hidden Network'}');
      print('   BSSID: ${network['BSSID'] ?? 'N/A'}');
      print('   Signal: ${network['Signal'] ?? 'N/A'}');
      print('   Frequency: ${network['Frequency'] ?? 'N/A'}');
    }

    print('\n=== End of Scan Results ===\n');

    // Check for target network and make API call if found
    await _checkTargetNetworkAndCallAPI(networks);
  }

  static Future<void> _parseLinuxOutput(String output) async {
    print('\n=== WiFi Scan Results ===');

    List<String> lines = output.split('\n');
    List<Map<String, String>> networks = [];

    // Skip header lines
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty || line.startsWith('*')) continue;

      // Parse nmcli output format
      List<String> parts = line.split(RegExp(r'\s{2,}'));
      if (parts.length >= 4) {
        String ssid = parts[1].isEmpty ? 'Hidden Network' : parts[1];
        String chan = parts[3];
        String signal = parts[5];

        networks.add({
          'SSID': ssid,
          'BSSID': 'N/A',
          'Signal': '$signal dBm',
          'Frequency': 'Channel $chan',
        });
      }
    }

    print('Found ${networks.length} networks:');

    for (int i = 0; i < networks.length; i++) {
      final network = networks[i];
      print('\n${i + 1}. SSID: ${network['SSID'] ?? 'Hidden Network'}');
      print('   BSSID: ${network['BSSID'] ?? 'N/A'}');
      print('   Signal: ${network['Signal'] ?? 'N/A'}');
      print('   Frequency: ${network['Frequency'] ?? 'N/A'}');
    }

    print('\n=== End of Scan Results ===\n');

    // Check for target network and make API call if found
    await _checkTargetNetworkAndCallAPI(networks);
  }

  static Future<void> _parseIwlistOutput(String output) async {
    print('\n=== WiFi Scan Results ===');

    List<String> lines = output.split('\n');
    List<Map<String, String>> networks = [];
    Map<String, String> currentNetwork = {};

    for (String line in lines) {
      line = line.trim();

      if (line.startsWith('Cell')) {
        if (currentNetwork.isNotEmpty) {
          networks.add(currentNetwork);
        }
        currentNetwork = {
          'SSID': '',
          'BSSID': '',
          'Signal': '',
          'Frequency': '',
        };

        // Extract BSSID
        RegExpMatch? match = RegExp(
          r'Address: ([0-9A-Fa-f:]+)',
        ).firstMatch(line);
        if (match != null) {
          currentNetwork['BSSID'] = match.group(1)!;
        }
      } else if (line.startsWith('ESSID:')) {
        String ssid = line.split('"')[1];
        currentNetwork['SSID'] = ssid.isEmpty ? 'Hidden Network' : ssid;
      } else if (line.contains('Signal level=')) {
        RegExpMatch? match = RegExp(r'Signal level=([-\d]+)').firstMatch(line);
        if (match != null) {
          currentNetwork['Signal'] = '${match.group(1)} dBm';
        }
      } else if (line.contains('Frequency:')) {
        RegExpMatch? match = RegExp(r'Frequency:([\d.]+)').firstMatch(line);
        if (match != null) {
          currentNetwork['Frequency'] = '${match.group(1)} GHz';
        }
      }
    }

    if (currentNetwork.isNotEmpty) {
      networks.add(currentNetwork);
    }

    print('Found ${networks.length} networks:');

    for (int i = 0; i < networks.length; i++) {
      final network = networks[i];
      print('\n${i + 1}. SSID: ${network['SSID'] ?? 'Hidden Network'}');
      print('   BSSID: ${network['BSSID'] ?? 'N/A'}');
      print('   Signal: ${network['Signal'] ?? 'N/A'}');
      print('   Frequency: ${network['Frequency'] ?? 'N/A'}');
    }

    print('\n=== End of Scan Results ===\n');

    // Check for target network and make API call if found
    await _checkTargetNetworkAndCallAPI(networks);
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
