import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({Key? key}) : super(key: key);

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  List<Map<String, dynamic>> activeSessions = [];
  bool isLoading = true;
  String? errorMessage;
  bool isInRangeOfCollege = false;
  bool isScanningWiFi = false;

  @override
  void initState() {
    super.initState();
    _checkWiFiRangeAndFetchSessions();
  }

  Future<void> _checkWiFiRangeAndFetchSessions() async {
    setState(() {
      isScanningWiFi = true;
      isLoading = true;
    });

    try {
      // Check and request location permission
      PermissionStatus permission = await Permission.location.status;
      if (!permission.isGranted) {
        permission = await Permission.location.request();
        if (!permission.isGranted) {
          setState(() {
            errorMessage = 'Location permission is required for WiFi scanning.';
            isLoading = false;
            isScanningWiFi = false;
          });
          return;
        }
      }

      // Check if location services are enabled
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        setState(() {
          errorMessage =
              'Location services are disabled. Please enable location services to scan for WiFi networks.';
          isLoading = false;
          isScanningWiFi = false;
        });
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
        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
          isScanningWiFi = false;
        });
        return;
      }

      // Start scan and get results
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();

      const String targetSSID = 'SOMAIYA-AP';
      bool foundTargetNetwork = results.any((ap) => ap.ssid == targetSSID);

      setState(() {
        isInRangeOfCollege = foundTargetNetwork;
        isScanningWiFi = false;
      });

      if (foundTargetNetwork) {
        print(
          '🎯 Target network "$targetSSID" detected! Fetching active sessions...',
        );
        await _fetchActiveSessions();
      } else {
        print(
          '❌ Target network "$targetSSID" not found. Device not in range of college.',
        );
        setState(() {
          isLoading = false;
          errorMessage = 'Device not in range of college';
        });
      }
    } catch (e) {
      print('Error scanning for WiFi: $e');
      setState(() {
        errorMessage = 'Error scanning for WiFi: $e';
        isLoading = false;
        isScanningWiFi = false;
      });
    }
  }

  Future<void> _fetchActiveSessions() async {
    try {
      print('📡 [SESSIONS] Fetching active sessions...');
      final sessions = await ApiService.getActiveSessions();
      print('✅ [SESSIONS] Fetched ${sessions.length} active sessions');
      print('📊 [SESSIONS] Sessions data: $sessions');

      setState(() {
        activeSessions = sessions;
        isLoading = false;
      });
    } catch (e) {
      print('❌ [SESSIONS] Error fetching active sessions: $e');
      setState(() {
        errorMessage = 'Failed to load active sessions: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showAttendanceConfirmationDialog(
    Map<String, dynamic> session,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Mark Attendance',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark Attendance for this session?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course: ${session['course_code'] ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faculty: ${session['faculty_id'] ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${session['start_time'] ?? 'N/A'} - ${session['end_time'] ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'No',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(
                'Yes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA50C22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _markAttendance(session);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAttendance(Map<String, dynamic> session) async {
    try {
      print('🔐 [BIOMETRIC] Starting biometric authentication...');

      final localAuth = LocalAuthentication();
      final canAuthenticate =
          await localAuth.canCheckBiometrics ||
          await localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biometric authentication is not available on this device',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Authenticate to mark your attendance',
      );

      if (!didAuthenticate) {
        print('❌ [BIOMETRIC] Authentication failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      print('✅ [BIOMETRIC] Authentication successful');

      // Get device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      }

      // Get roll number from SharedPreferences (primary identifier)
      final prefs = await SharedPreferences.getInstance();
      final rollNumber =
          prefs.getString('rollNumber') ??
          prefs.getString('userId') ??
          prefs.getString('studentId') ??
          '';

      // Debug: Print all stored preferences
      print('🔍 [STORAGE] Checking SharedPreferences...');
      print('📋 [STORAGE] All stored keys: ${prefs.getKeys()}');
      print(
        '📋 [STORAGE] Roll Number from rollNumber key: "${prefs.getString('rollNumber')}"',
      );
      print(
        '📋 [STORAGE] Roll Number from userId key: "${prefs.getString('userId')}"',
      );
      print('📋 [STORAGE] Roll Number is empty: ${rollNumber.isEmpty}');

      if (rollNumber.isEmpty) {
        throw Exception('Roll number not found. Please login again.');
      }

      // Get current timestamp in ISO format
      final timestamp = DateTime.now().toIso8601String();

      print('📡 [ATTENDANCE] Marking attendance...');
      print('📋 [ATTENDANCE] Roll Number: $rollNumber');
      print('📋 [ATTENDANCE] Session ID: ${session['session_id']}');
      print('📋 [ATTENDANCE] Device ID: $deviceId');
      print('📋 [ATTENDANCE] Timestamp: $timestamp');

      final result = await ApiService.markAttendance(
        studentId: rollNumber, // Use roll_number as primary identifier
        sessionId: session['session_id'],
        deviceId: deviceId,
        timestamp: timestamp,
      );

      print('✅ [ATTENDANCE] Attendance marked successfully');
      print('📊 [ATTENDANCE] Response: $result');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance marked successfully!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the sessions list to update UI
        _fetchActiveSessions();
      }
    } catch (e) {
      print('❌ [ATTENDANCE] Error marking attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to mark attendance: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFFA50C22),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          'Active Sessions',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFA50C22),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkWiFiRangeAndFetchSessions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading || isScanningWiFi) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
            ),
            SizedBox(height: 16),
            Text(
              'Scanning for college WiFi network...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      // Check if it's the specific "not in range" error
      if (errorMessage == 'Device not in range of college') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  'Device not in range of college',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please make sure you are within the college campus and connected to the college WiFi network to access active sessions.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkWiFiRangeAndFetchSessions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA50C22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Handle other errors
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFA50C22),
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF374151),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkWiFiRangeAndFetchSessions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA50C22),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (activeSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.schedule_outlined,
              color: Color(0xFF9CA3AF),
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              'No active sessions found',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for active attendance sessions',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActiveSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeSessions.length,
        itemBuilder: (context, index) {
          final session = activeSessions[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showAttendanceConfirmationDialog(session),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA50C22).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            session['course_code'] ?? 'N/A',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFA50C22),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Faculty: ${session['faculty_id'] ?? 'N/A'}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Tap to mark attendance',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFA50C22),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
