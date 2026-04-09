import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'faculty_profile_screen.dart';
import 'timetable_screen.dart';
import 'post_announcement_screen.dart';
import 'upload_material_screen.dart';
import 'substitution_requests_screen.dart';
import '../services/fcm_service.dart';

class FacultyHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? facultyData;

  const FacultyHomeScreen({Key? key, this.facultyData}) : super(key: key);

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class AttendanceRecord {
  final String facultyId;
  final String name;
  final String status;
  final String loginTime;
  final String date;

  AttendanceRecord({
    required this.facultyId,
    required this.name,
    required this.status,
    required this.loginTime,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'name': name,
      'status': status,
      'login_time': loginTime,
      'date': date,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      facultyId: json['faculty_id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      loginTime: json['login_time'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class AttendanceService {
  static Future<void> saveAttendance(AttendanceRecord attendance) async {
    final prefs = await SharedPreferences.getInstance();
    print("Saving attendance to SharedPreferences...");
    await prefs.setString('faculty_id', attendance.facultyId);
    await prefs.setString('name', attendance.name);
    await prefs.setString('status', attendance.status);
    await prefs.setString('login_time', attendance.loginTime);
    await prefs.setString('date', attendance.date);
    print("Attendance data saved successfully");
  }

  static Future<AttendanceRecord?> getTodayAttendance() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final facultyId = prefs.getString('faculty_id');
      final name = prefs.getString('name');
      final status = prefs.getString('status');
      final loginTime = prefs.getString('login_time');
      final date = prefs.getString('date');

      print(
        "Retrieved attendance data: facultyId=$facultyId, name=$name, status=$status, loginTime=$loginTime, date=$date",
      );

      if (facultyId == null ||
          name == null ||
          status == null ||
          loginTime == null ||
          date == null) {
        print("Some attendance data is null, returning null");
        return null;
      }

      final attendance = AttendanceRecord(
        facultyId: facultyId,
        name: name,
        status: status,
        loginTime: loginTime,
        date: date,
      );

      final today = _formatDate(DateTime.now());
      print("Today's date: $today, Attendance date: ${attendance.date}");

      if (attendance.date == today) {
        print("Attendance is for today, returning record");
        return attendance;
      }
      print("Attendance is not for today, returning null");
      return null;
    } catch (e) {
      print("Error retrieving attendance: $e");
      return null;
    }
  }

  static String _formatDate(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  int _currentIndex = 0;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _isAttendanceMarked = false;
  Map<String, String>? _facultyData; // Store real faculty data from API
  Map<String, dynamic>? _attendanceData; // Store attendance data
  Map<String, dynamic>? _currentLecture; // Store current lecture data
  List<Map<String, dynamic>> _acceptedLectures =
      []; // Store accepted substitution lectures
  Timer? _lectureTimer; // Timer to update current lecture
  bool _isLoadingLectures = true; // Loading state for lectures
  bool _isAssigned = false; // Track if current lecture is assigned/substituted

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadFacultyData(); // Load real faculty data
    _checkTodayAttendance();
    _loadTodayLectures(); // Load today's lectures
    _loadAssignmentState(); // Load assignment state from preferences

    // Update current lecture every minute
    _lectureTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _loadTodayLectures();
      }
    });

    // Listen to FCM messages for navigation
    _listenToFCMMessages();

    // Initialize screens list
    _updateScreens();
  }

  Future<void> _refreshHomeData() async {
    print('🔄 [FACULTY_HOME] Refreshing home data...');

    // Refresh faculty data
    await _loadFacultyData();

    // Refresh attendance data
    await _checkTodayAttendance();

    // Refresh today's lectures
    await _loadTodayLectures();

    // Refresh accepted lectures
    await _loadAcceptedLectures();

    print('✅ [FACULTY_HOME] Home data refresh completed');
  }

  // Method to refresh data when returning from substitution requests
  void refreshFromSubstitutionRequests() async {
    print('🔄 [FACULTY_HOME] Refreshing after substitution response...');

    // Check if we have accepted lectures and mark as assigned
    await _loadAcceptedLectures();

    // If we have accepted lectures, mark current lecture as assigned
    if (_acceptedLectures.isNotEmpty) {
      await _saveAssignmentState(true);
    }

    _refreshHomeData();
  }

  // Load assignment state from SharedPreferences
  Future<void> _loadAssignmentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';
      final today = DateTime.now().toString().split(
        ' ',
      )[0]; // YYYY-MM-DD format

      // Get assignment state for today
      final assignedDate = prefs.getString('assigned_date_$facultyId');
      final isAssigned = prefs.getBool('is_assigned_$facultyId') ?? false;

      // Reset assignment state if it's a new day
      if (assignedDate != today) {
        setState(() {
          _isAssigned = false;
        });
        // Clear old assignment state
        await prefs.remove('assigned_date_$facultyId');
        await prefs.remove('is_assigned_$facultyId');
        print('🔄 [ASSIGNMENT] Reset assignment state for new day');
      } else {
        setState(() {
          _isAssigned = isAssigned;
        });
        print(
          '✅ [ASSIGNMENT] Loaded assignment state: $_isAssigned for date: $assignedDate',
        );
      }
    } catch (e) {
      print('❌ [ASSIGNMENT] Error loading assignment state: $e');
    }
  }

  // Save assignment state to SharedPreferences
  Future<void> _saveAssignmentState(bool assigned) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';
      final today = DateTime.now().toString().split(
        ' ',
      )[0]; // YYYY-MM-DD format

      await prefs.setBool('is_assigned_$facultyId', assigned);
      await prefs.setString('assigned_date_$facultyId', today);

      setState(() {
        _isAssigned = assigned;
      });

      print(
        '✅ [ASSIGNMENT] Saved assignment state: $assigned for date: $today',
      );
    } catch (e) {
      print('❌ [ASSIGNMENT] Error saving assignment state: $e');
    }
  }

  // Load accepted substitution lectures
  Future<void> _loadAcceptedLectures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      final response = await http.get(
        Uri.parse(
          'http://13.235.16.3:5000/substitution/accepted?faculty_id=$facultyId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> acceptedLectures = [];

        if (data['accepted_lectures'] != null) {
          acceptedLectures = List<Map<String, dynamic>>.from(
            data['accepted_lectures'],
          );
        }

        setState(() {
          _acceptedLectures = acceptedLectures;
        });

        print(
          '✅ [SUBSTITUTION] Loaded ${_acceptedLectures.length} accepted lectures',
        );
      }
    } catch (e) {
      print('❌ [SUBSTITUTION] Error loading accepted lectures: $e');
    }
  }

  void _listenToFCMMessages() {
    print('🔔 [FACULTY_HOME] Setting up FCM message listener...');

    FCMService().messageStream.listen((RemoteMessage message) {
      print('🔔 [FACULTY_HOME] Received FCM message: ${message.messageId}');
      print('🔔 [FACULTY_HOME] Message title: ${message.notification?.title}');
      print('🔔 [FACULTY_HOME] Message body: ${message.notification?.body}');
      print('🔔 [FACULTY_HOME] Message data: ${message.data}');

      // Always navigate to substitution requests screen for FCM messages
      // since all FCM messages are substitution-related
      print('🔔 [FACULTY_HOME] Navigating to substitution requests screen...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubstitutionRequestsScreen(
            substitutionId: message.data['substitution_id'],
          ),
        ),
      );
    });
  }

  void _updateScreens() {
    _screens = [
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("Lectures for today"),
              const SizedBox(height: 12),
              _buildLectureCard(),
              const SizedBox(height: 24),

              // Accepted Substitution Lectures Section
              if (_acceptedLectures.isNotEmpty) ...[
                _sectionLabel("Assigned Lectures"),
                const SizedBox(height: 12),
                _buildAcceptedLecturesSection(),
                const SizedBox(height: 24),
              ],

              _sectionLabel("Quick Actions"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoundedActionButton(
                      Icons.campaign_outlined,
                      "Post Announcement",
                      "Create an announcement for students",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PostAnnouncementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoundedActionButton(
                      Icons.upload_file_outlined,
                      "Upload Material",
                      "Upload study materials for students",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadMaterialScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      TimetableScreen(facultyData: _facultyData),
      FacultyProfileScreen(facultyData: _facultyData),
    ];
  }

  @override
  void dispose() {
    _lectureTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  // Helper method to format time from API string
  String _formatTimeFromString(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12
        ? (hour - 12).toString().padLeft(2, '0')
        : hour.toString().padLeft(2, '0');
    return "$displayHour:$minute $period";
  }

  // Load today's lectures from API
  Future<void> _loadTodayLectures() async {
    setState(() {
      _isLoadingLectures = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      print('📚 [LECTURE] Loading lectures for faculty: $facultyId');

      final url = Uri.parse(
        "http://13.235.16.3:5000/api/faculty/full-timetable?faculty_id=$facultyId",
      );

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print('📚 [LECTURE] API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lectures = List<Map<String, dynamic>>.from(data);

        // Get current time
        final now = DateTime.now();
        final currentTime = _formatTimeForComparison(now);

        // Find next available lecture (skip current if assigned/taken)
        Map<String, dynamic>? nextLecture;
        Map<String, dynamic>? currentLecture;

        // Sort lectures by start time for proper next lecture detection
        final sortedLectures = List<Map<String, dynamic>>.from(lectures);
        sortedLectures.sort(
          (a, b) =>
              (a['start_time'] as String).compareTo(b['start_time'] as String),
        );

        // First, identify the current lecture and next lecture based on time
        for (final lecture in sortedLectures) {
          final startTime = lecture['start_time'];
          final endTime = lecture['end_time'];
          final courseName = lecture['course_name'] ?? 'Unknown';

          print('📚 [LECTURE] Checking lecture: $courseName');
          print('📚 [LECTURE]   Time: $startTime - $endTime');
          print('📚 [LECTURE]   Current: $currentTime');

          // Convert times to total minutes for accurate comparison
          final currentMinutes = _timeToMinutes(currentTime);
          final startMinutes = _timeToMinutes(startTime);
          final endMinutes = _timeToMinutes(endTime);

          print('📚 [LECTURE]   Current minutes: $currentMinutes');
          print('📚 [LECTURE]   Start minutes: $startMinutes');
          print('📚 [LECTURE]   End minutes: $endMinutes');

          // Check if this is the current lecture (in progress)
          if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
            currentLecture = lecture as Map<String, dynamic>;
            print('📚 [LECTURE] → Found current lecture: $courseName');
          }
          // Check if this is the next lecture (hasn't started yet)
          else if (currentMinutes < startMinutes && nextLecture == null) {
            nextLecture = lecture as Map<String, dynamic>;
            print('📚 [LECTURE] → Found next lecture: $courseName');
            break; // Found the next lecture, no need to check further
          }
        }

        // If current lecture exists and is assigned/taken, show the next lecture
        if (currentLecture != null && _isAssigned) {
          print(
            '📚 [LECTURE] Current lecture is assigned/taken, showing next lecture',
          );
          // nextLecture is already set from the loop above
        } else if (currentLecture != null && !_isAssigned) {
          print('📚 [LECTURE] Current lecture is available, showing current');
          nextLecture = currentLecture; // Show current lecture if not assigned
        } else {
          print('📚 [LECTURE] No current lecture, showing next available');
          // nextLecture is already set from the loop above
        }

        setState(() {
          _currentLecture = nextLecture;
          _isLoadingLectures = false;
          _updateScreens(); // Rebuild screens with new data
        });

        print(
          '🔄 [UI] setState called with lecture: ${nextLecture?['course_name']}',
        );
        print('🔄 [UI] _isLoadingLectures set to: false');
        print(
          '🔄 [UI] _currentLecture set to: ${_currentLecture?['course_name']}',
        );
        print('🔄 [UI] _updateScreens called to rebuild UI');

        if (_currentLecture != null) {
          print(
            '📚 [LECTURE] ✓ Displaying next lecture: ${_currentLecture!['course_name']}',
          );
        } else {
          print('📚 [LECTURE] ✗ No next lectures found for today');
        }
      } else {
        print('❌ [LECTURE] API error: ${response.statusCode}');
        setState(() {
          _isLoadingLectures = false;
          _updateScreens(); // Rebuild screens to show error state
        });
      }
    } catch (e) {
      print('❌ [LECTURE] Error loading lectures: $e');
      setState(() {
        _isLoadingLectures = false;
        _updateScreens(); // Rebuild screens to show error state
      });
    }
  }

  // Helper method to convert time string to total minutes
  int _timeToMinutes(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  // Helper methods for time comparison
  String _getDayOfWeek(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return weekday >= 1 && weekday <= 6 ? days[weekday - 1] : 'SUN';
  }

  String _formatTimeForComparison(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00";
  }

  // Load faculty data from SharedPreferences (saved during login)
  Future<void> _loadFacultyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyName = prefs.getString('facultyName') ?? 'Faculty';
      final facultyEmail =
          prefs.getString('facultyEmail') ?? 'faculty@somaiya.edu';
      final facultyDepartment = prefs.getString('facultyDepartment') ?? 'N/A';
      final facultyDesignation = prefs.getString('facultyDesignation') ?? 'N/A';
      final facultyId = prefs.getString('facultyId') ?? 'N/A';

      setState(() {
        _facultyData = {
          'name': facultyName,
          'email': facultyEmail,
          'department': facultyDepartment,
          'designation': facultyDesignation,
          'faculty_id': facultyId,
        };
      });
    } catch (e) {
      print('❌ [FACULTY] Error loading faculty data: $e');
    }
  }

  Future<void> _checkTodayAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = prefs.getString('attendance_date');
      final today = DateTime.now().toString().split(' ')[0];

      if (date == today) {
        final facultyId =
            prefs.getString('attendance_faculty_id') ?? "Loading...";
        final name = prefs.getString('attendance_name') ?? "Loading...";
        final status = prefs.getString('attendance_status') ?? "Loading...";
        final loginTime = prefs.getString('attendance_login_time') ?? "";

        setState(() {
          _isAttendanceMarked = true;
          _attendanceData = {
            'faculty_id': facultyId,
            'name': name,
            'status': status,
            'login_time': loginTime,
            'date': date ?? "",
          };
        });
      }
    } catch (e) {
      print("Error checking attendance: $e");
    }
  }

  Widget _buildLectureCard() {
    print('🎯 [UI] _buildLectureCard called');
    print('🎯 [UI] _isLoadingLectures: $_isLoadingLectures');
    print('🎯 [UI] _currentLecture is null: ${_currentLecture == null}');
    if (_currentLecture != null) {
      print('🎯 [UI] Lecture data: ${_currentLecture!['course_name']}');
      print('🎯 [UI] Lecture start time: ${_currentLecture!['start_time']}');
      print('🎯 [UI] Lecture room: ${_currentLecture!['room_number']}');
    }

    // Show loading state
    if (_isLoadingLectures) {
      print('🎯 [UI] Showing loading state');
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Red header band
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFA50C22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Loading Lecture...",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Loading body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Fetching your next lecture...",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If no current lecture, show a message
    if (_currentLecture == null) {
      print('🎯 [UI] Showing no lecture state');
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Red header band
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFA50C22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.free_breakfast,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "No Lecture Scheduled",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Details body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.free_breakfast,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Enjoy your free time!",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No lectures scheduled for this time slot.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show current lecture
    final lecture = _currentLecture!;
    final courseName = lecture['course_name'] ?? 'Unknown Course';
    final courseCode = lecture['course_code'] ?? 'N/A';
    final batch = lecture['batch'] ?? 'N/A';
    final room = lecture['room_number'] ?? 'N/A';
    final startTime = _formatTimeFromString(lecture['start_time']);
    final endTime = _formatTimeFromString(lecture['end_time']);
    final sessionType = lecture['session_type'] ?? 'LECTURE';

    print('🎯 [UI] Showing lecture: $courseName');
    print(
      '🎯 [UI] Lecture details: $courseCode, $batch, $room, $startTime - $endTime',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Red header band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFA50C22),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  courseCode,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Details body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _lectureInfoRow(Icons.business_outlined, "Batch", batch),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(
                  Icons.access_time_rounded,
                  "Time Slot",
                  "$startTime to $endTime",
                ),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(
                  Icons.meeting_room_outlined,
                  "Room Number",
                  room,
                ),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(Icons.category_outlined, "Type", sessionType),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAssigned
                        ? null
                        : () {
                            _assignLecture();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA50C22),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isAssigned ? "Already Assigned" : "Assign this lec",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isAssigned
                        ? null
                        : () {
                            _showActionDialog("Take lecture");
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA50C22),
                      side: const BorderSide(color: Color(0xFFA50C22)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isAssigned ? "Already Taken" : "Take lecture",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lectureInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFA50C22)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Future<void> _assignLecture() async {
    if (_currentLecture == null) {
      print('❌ [ASSIGN] No lecture data available');
      return;
    }

    final lecture = _currentLecture!;
    final batch = lecture['batch'] ?? '';
    final courseName = lecture['course_name'] ?? '';
    final room = lecture['room_number'] ?? '';
    final startTime = lecture['start_time'] ?? '';
    final endTime = lecture['end_time'] ?? '';
    final sessionType = lecture['session_type'] ?? '';

    print('📋 [ASSIGN] Assigning lecture:');
    print('📋 [ASSIGN] Course: $courseName');
    print('📋 [ASSIGN] Batch: $batch');
    print('📋 [ASSIGN] Room: $room');
    print('📋 [ASSIGN] Time: $startTime - $endTime');
    print('📋 [ASSIGN] Type: $sessionType');

    if (batch.isEmpty) {
      print('❌ [ASSIGN] No batch found for this lecture');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No batch found for this lecture",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('📡 [ASSIGN] Fetching faculty data for batch: $batch');

      final url = Uri.parse(
        "http://13.235.16.3:5000/api/batch/faculty?batch=$batch",
      );

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print('📡 [ASSIGN] API Response Status: ${response.statusCode}');
      print('📡 [ASSIGN] API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [ASSIGN] Faculty data fetched successfully:');
        print('✅ [ASSIGN] Data: $data');

        // Extract faculty list from response - handle new format with names
        List<String> facultyList = [];

        // Try to find faculty data for any batch key
        String? batchKey;
        for (final key in data.keys) {
          if (key.toString().toLowerCase().contains(batch.toLowerCase()) &&
              key.toString().toLowerCase().contains('faculty')) {
            batchKey = key.toString();
            break;
          }
        }

        if (batchKey != null && data[batchKey] != null) {
          // New format: array of faculty objects with name field
          final facultyObjects = data[batchKey] as List<dynamic>;
          facultyList = facultyObjects
              .map((faculty) => faculty['name']?.toString() ?? 'Unknown')
              .toList();
          print('✅ [ASSIGN] Found faculty list for batch key: $batchKey');
        } else {
          // Fallback: try old format or other keys
          final facultyIds = data['FYCO faculty'] as List<dynamic>?;
          if (facultyIds != null) {
            facultyList = facultyIds.cast<String>();
          }
        }

        if (facultyList.isNotEmpty) {
          _showFacultySelectionDialog(batch, courseName, facultyList);
        } else {
          print('❌ [ASSIGN] Faculty list is empty for batch: $batch');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No faculty found for batch $batch",
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ [ASSIGN] API error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error fetching faculty data: ${response.statusCode}",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [ASSIGN] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFacultySelectionDialog(
    String batch,
    String courseName,
    List<String> facultyList,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Assign Lecture - $courseName",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          content: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Send notification to assign this lecture to anyone from the following faculty list?",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Batch: $batch",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: facultyList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          title: Text(
                            facultyList[index],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            final selectedFaculty = facultyList[index];
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Notification sent to $selectedFaculty",
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: const Color(0xFFA50C22),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () {
                print(
                  "FULL URL: ${Uri.parse('http://13.235.16.3:5000/api/substitution/request')}",
                );
                Navigator.of(context).pop();
                _createSubstitutionRequest();
              },
              child: Text(
                "Send to All",
                style: GoogleFonts.inter(
                  color: const Color(0xFFA50C22),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSubstitutionRequest() async {
    if (_currentLecture == null) {
      print('❌ [SUBSTITUTION] No lecture data available');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No lecture data available",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
              ),
              SizedBox(width: 16),
              Text('Creating substitution request...'),
            ],
          ),
        );
      },
    );

    final lecture = _currentLecture!;
    final courseName = lecture['course_name'] ?? '';
    final room = lecture['room_number'] ?? '';
    final startTime = lecture['start_time'] ?? '';
    final endTime = lecture['end_time'] ?? '';
    final sessionType = lecture['session_type'] ?? '';

    print('📋 [SUBSTITUTION] Creating substitution request:');
    print('📋 [SUBSTITUTION] Course: $courseName');
    print('📋 [SUBSTITUTION] Room: $room');
    print('📋 [SUBSTITUTION] Time: $startTime - $endTime');
    print('📋 [SUBSTITUTION] Type: $sessionType');

    try {
      // Get current faculty ID
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      print(
        '📡 [SUBSTITUTION] Sending substitution request for faculty: $facultyId',
      );

      final url = 'http://13.235.16.3:5000/substitution/request';
      print("FULL URL: ${Uri.parse(url)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timetable_id':
              10, // This should come from your actual timetable data
          'original_faculty_id': facultyId,
          'date': DateTime.now().toString().split(' ')[0], // Current date
        }),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      print('📡 [SUBSTITUTION] API Response Status: ${response.statusCode}');
      print('📡 [SUBSTITUTION] API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [SUBSTITUTION] Substitution request created successfully:');
        print('✅ [SUBSTITUTION] Substitution ID: ${data['substitution_id']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Substitution request sent',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFFA50C22),
          ),
        );

        // Mark lecture as assigned and save state
        await _saveAssignmentState(true);

        // Refresh UI after successful request
        setState(() {
          _loadTodayLectures(); // Refresh lectures to show next one
        });
      } else {
        print('❌ [SUBSTITUTION] API error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error creating substitution request: ${response.statusCode}",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('❌ [SUBSTITUTION] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showActionDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          content: Text(
            "Are you sure you want to $action?",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // If taking a lecture, mark as assigned
                if (action == "Take lecture") {
                  await _saveAssignmentState(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Lecture taken successfully",
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$action action completed",
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: const Color(0xFFA50C22),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA50C22),
              ),
              child: Text(
                "Confirm",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildRoundedActionButton(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFA50C22).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFA50C22), size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build accepted lectures section
  Widget _buildAcceptedLecturesSection() {
    return Column(
      children: _acceptedLectures.map((lecture) {
        final courseName = lecture['course_name'] ?? 'Unknown Course';
        final room = lecture['room_no'] ?? 'N/A'; // Updated field name
        final startTime = _formatTimeFromString(lecture['start_time']);
        final endTime = _formatTimeFromString(lecture['end_time']);
        final originalFaculty =
            lecture['original_faculty_name'] ?? 'Unknown Faculty';
        final substituteFaculty =
            lecture['substitute_faculty_name'] ??
            'You'; // Who accepted this lecture

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with substitution badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ASSIGNED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _lectureInfoRow(
                  Icons.access_time_rounded,
                  "Time",
                  "$startTime to $endTime",
                ),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(Icons.meeting_room_outlined, "Room", room),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(Icons.person_outline, "From", originalFaculty),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(Icons.person, "Assigned to", substituteFaculty),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFF1F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive
                    ? const Color(0xFFA50C22)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFFA50C22)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFA50C22),
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    height: 45,
                    width: 45,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/somaiyalogo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _facultyData?['email'] ?? "faculty@somaiya.edu",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _facultyData?['email'] ?? "faculty@somaiya.edu",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SubstitutionRequestsScreen(),
                        ),
                      );

                      // Refresh home screen data when returning from substitution requests
                      if (result != null && result == true) {
                        refreshFromSubstitutionRequests();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    "assets/images/somaiyatrust.png",
                    height: 45,
                    width: 45,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHomeData,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'Timetable',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
