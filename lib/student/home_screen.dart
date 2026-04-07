import 'package:attendance_tracker/student/subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'timetable_screen.dart';
import 'attendance_tracker_screen.dart';
import 'notifications_screen.dart';
import '../upcoming_events_screen.dart';
import 'uploaded_materials_screen.dart';
import '../services/api_service.dart';
import '../services/announcement_service.dart';
import 'subjects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String>? _studentData;
  Map<String, dynamic>? _attendanceData;
  double _overallPercentage = 0.0;
  Map<String, dynamic>? _currentLecture;
  Timer? _lectureTimer;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _loadAttendanceData();
    _loadCurrentLecture();

    // Update current lecture every 30 seconds
    _lectureTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadCurrentLecture();
    });
  }

  @override
  void dispose() {
    _lectureTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentName = prefs.getString('studentName') ?? 'Loading...';
      final studentRollNumber =
          prefs.getString('studentRollNumber') ?? 'Loading...';

      setState(() {
        _studentData = {'name': studentName, 'roll_number': studentRollNumber};
      });

      print('📋 [HOME] Loaded student data for app bar:');
      print('📋 [HOME] Name: $studentName');
      print('📋 [HOME] Roll Number: $studentRollNumber');
    } catch (e) {
      print('❌ [HOME] Error loading student data: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentRollNumber =
          prefs.getString('studentRollNumber') ?? 'FCUG23762';

      print(
        '📊 [HOME] Loading attendance data for student: $studentRollNumber',
      );

      // Load attendance data from local JSON file
      final String jsonString = await rootBundle.loadString(
        'assets/json/attendance_percentage.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final studentAttendance = jsonData[studentRollNumber];

      if (studentAttendance != null) {
        setState(() {
          _attendanceData = studentAttendance;
          _overallPercentage = (studentAttendance['overallPercentage'] ?? 0.0)
              .toDouble();
        });

        print('📊 [HOME] Attendance data loaded successfully');
        print('📊 [HOME] Overall percentage: ${_overallPercentage}%');
      } else {
        print(
          '❌ [HOME] No attendance data found for student: $studentRollNumber',
        );
        setState(() {
          _overallPercentage = 0.0;
        });
      }
    } catch (e) {
      print('❌ [HOME] Error loading attendance data: $e');
      setState(() {
        _overallPercentage = 0.0;
      });
    }
  }

  Future<void> _loadCurrentLecture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentBatch = prefs.getString('studentYear') ?? '';
      final studentLabBatch = prefs.getString('studentLabBatch') ?? '';

      if (studentBatch.isEmpty) {
        print('❌ [HOME] No batch found for current lecture');
        setState(() {
          _currentLecture = null;
        });
        return;
      }

      // Get current IST time
      final now = DateTime.now().toUtc().add(
        const Duration(hours: 5, minutes: 30),
      );
      final currentDay = _getDayOfWeek(now.weekday);
      final currentTime = _formatTime(now.hour, now.minute);

      print(
        '🏫 [HOME] Checking current lecture for $currentDay at $currentTime',
      );

      final url = 'http://13.235.16.3:5001/timetable?batch=$studentBatch';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> timetableData = data['data'];

          // Find current lecture
          Map<String, dynamic>? currentLecture;

          for (final entry in timetableData) {
            final day = entry['day_of_week'] as String;
            final sessionType = entry['session_type'] as String;
            final labBatch = entry['lab_batch'] as String?;
            final startTime = entry['start_time'] as String;
            final endTime = entry['end_time'] as String;

            // Skip if it's a lab for a different batch
            if (sessionType == 'LAB' &&
                labBatch != null &&
                labBatch != studentLabBatch) {
              continue;
            }

            // Check if this session is currently ongoing
            if (day == currentDay &&
                _isTimeInCurrentSlot(startTime, endTime, currentTime)) {
              currentLecture = entry;
              break;
            }
          }

          setState(() {
            _currentLecture = currentLecture;
          });

          if (currentLecture != null) {
            print(
              '🏫 [HOME] Found current lecture: ${currentLecture['course_code']}',
            );
          } else {
            print('🏫 [HOME] No current lecture found');
          }
        }
      }
    } catch (e) {
      print('❌ [HOME] Error loading current lecture: $e');
      setState(() {
        _currentLecture = null;
      });
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return '';
    }
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  bool _isTimeInCurrentSlot(
    String startTime,
    String endTime,
    String currentTime,
  ) {
    try {
      final start = DateTime.parse('2000-01-01 $startTime');
      final end = DateTime.parse('2000-01-01 $endTime');
      final current = DateTime.parse('2000-01-01 $currentTime');

      return current.isAfter(start.subtract(const Duration(seconds: 1))) &&
          current.isBefore(end.add(const Duration(seconds: 1)));
    } catch (e) {
      return false;
    }
  }

  Future<void> _refreshHomeData() async {
    print('🔄 [HOME] Refreshing home data...');

    // Refresh student data
    await _loadStudentData();

    // Refresh attendance data
    await _loadAttendanceData();

    // Refresh current lecture
    await _loadCurrentLecture();

    // Trigger announcement check for new notifications
    try {
      final announcementService = AnnouncementService();
      await announcementService.checkAndNotifyNewAnnouncements();
      print('🔔 [HOME] Announcement check completed during refresh');
    } catch (e) {
      print('❌ [HOME] Error checking announcements during refresh: $e');
    }

    print('✅ [HOME] Home data refresh completed');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),

        /// 🔴 CUSTOM APP BAR (STUDENT CARD)
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
                            _studentData?['name'] ?? "Loading...",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _studentData?['roll_number'] ?? "Loading...",
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
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
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

        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshHomeData,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ─── CURRENT LECTURE ───────────────────────────────────────
                  _sectionLabel("Current Lecture"),
                  const SizedBox(height: 10),
                  _CurrentLectureCard(currentLecture: _currentLecture),

                  const SizedBox(height: 22),

                  /// ─── ATTENDANCE TRACKER ────────────────────────────────────
                  _sectionLabel("Attendance Tracker"),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceTrackerScreen(),
                        ),
                      );
                    },
                    child: _AttendanceCard(
                      overallPercentage: _overallPercentage,
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// ─── QUICK ACCESS ──────────────────────────────────────────
                  _sectionLabel("Quick Access"),
                  const SizedBox(height: 12),
                  _QuickAccessGrid(context: context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ── Section label ─────────────────────────────────────────────────────────
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

/// ── Current Lecture Card ──────────────────────────────────────────────────
class _CurrentLectureCard extends StatelessWidget {
  final Map<String, dynamic>? currentLecture;

  const _CurrentLectureCard({required this.currentLecture});

  @override
  Widget build(BuildContext context) {
    // If no current lecture, show a "No ongoing lecture" card
    if (currentLecture == null) {
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
            /// Red header band
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No Ongoing Lectures",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Check timetable for next class",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF9CA3AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Free Time",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Details body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  _lectureInfoRow(
                    Icons.access_time_rounded,
                    "Current Time",
                    _formatCurrentTime(),
                  ),
                  const _divider(),
                  _lectureInfoRow(
                    Icons.calendar_today_outlined,
                    "Status",
                    "No classes in progress",
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show current lecture data
    final courseCode = currentLecture!['course_code'] as String;
    final courseName = currentLecture!['course_name'] as String;
    final facultyId = currentLecture!['faculty_id'] as String;
    final roomNumber = currentLecture!['room_number'] as String;
    final startTime = currentLecture!['start_time'] as String;
    final endTime = currentLecture!['end_time'] as String;
    final sessionType = currentLecture!['session_type'] as String;

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
          /// Red header band
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Ongoing",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Details body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _lectureInfoRow(
                  Icons.person_outline_rounded,
                  "Faculty",
                  facultyId,
                ),
                const _divider(),
                _lectureInfoRow(
                  Icons.access_time_rounded,
                  "Time Slot",
                  _formatTimeRange(startTime, endTime),
                ),
                const _divider(),
                _lectureInfoRow(
                  Icons.meeting_room_outlined,
                  "Room No",
                  roomNumber,
                ),
                const _divider(),
                _lectureInfoRow(
                  Icons.computer_outlined,
                  "Type",
                  sessionType == 'LAB' ? 'Laboratory' : 'Lecture',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrentTime() {
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRange(String startTime, String endTime) {
    final start = DateTime.parse('2000-01-01 $startTime');
    final end = DateTime.parse('2000-01-01 $endTime');

    final startFormatted =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endFormatted =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return '$startFormatted - $endFormatted';
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
}

class _divider extends StatelessWidget {
  const _divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 18, thickness: 1, color: Color(0xFFF3F4F6));
}

/// ── Attendance Tracker Card ───────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final double overallPercentage;

  const _AttendanceCard({required this.overallPercentage});

  @override
  Widget build(BuildContext context) {
    // Calculate present and total from overall percentage (assuming 50 total lectures)
    final int total = 50;
    final int present = ((overallPercentage / 100) * total).round();

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          /// Circular progress with percentage
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 90,
                width: 90,
                child: CircularProgressIndicator(
                  value: overallPercentage / 100,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: const Color(0xFFA50C22),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${overallPercentage.toStringAsFixed(1)}%",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    "attended",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 18),

          /// Right side info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Overall Attendance",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: "$present",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const TextSpan(text: " of "),
                      TextSpan(
                        text: "$total",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const TextSpan(text: " lectures attended"),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                /// Status message
                if (overallPercentage >= 75.0)
                  Text(
                    "Good attendance",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF16A34A),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Below 75% threshold",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Quick Access Grid ─────────────────────────────────────────────────────
class _QuickAccessGrid extends StatelessWidget {
  final BuildContext context;
  const _QuickAccessGrid({required this.context});

  @override
  Widget build(BuildContext _) {
    final items = [
      _QuickItem(
        icon: Icons.calendar_today_outlined,
        label: "Timetable",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimetableScreen()),
        ),
      ),
      _QuickItem(
        icon: Icons.event_outlined,
        label: "Events",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpcomingEventsScreen()),
        ),
      ),
      _QuickItem(
        icon: Icons.folder_outlined,
        label: "Materials",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadedMaterialsScreen()),
        ),
      ),
      
      _QuickItem(
        icon: Icons.menu_book_outlined,
        label: "Subjects",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubjectsScreen()),
        ),
      ),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildQuickTile(item),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildQuickTile(_QuickItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 22, color: const Color(0xFFA50C22)),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
