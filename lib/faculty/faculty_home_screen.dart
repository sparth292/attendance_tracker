import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'faculty_profile_screen.dart';
import 'timetable_screen.dart';
import 'create_assignment_screen.dart';
import 'post_announcement_screen.dart';
import 'upload_material_screen.dart';

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
  Map<String, String>? _attendanceData;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkTodayAttendance();
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
              _sectionLabel("Faculty Attendance"),
              const SizedBox(height: 12),
              _buildFacultyAttendanceCard(),
            ],
          ),
        ),
      ),
      TimetableScreen(facultyData: widget.facultyData),
      FacultyProfileScreen(facultyData: widget.facultyData),
    ];
  }

  Future<void> _checkTodayAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = prefs.getString('attendance_date');
      final today = DateTime.now().toString().split(' ')[0];

      if (date == today) {
        final facultyId = prefs.getString('attendance_faculty_id') ?? "01281";
        final name = prefs.getString('attendance_name') ?? "Manjiri Samant";
        final status = prefs.getString('attendance_status') ?? "Verified";
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

  Future<void> _saveAttendance() async {
    try {
      final now = DateTime.now();
      final date = now.toString().split(' ')[0];
      final loginTime = _formatTime(now);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('attendance_date', date);
      await prefs.setString(
        'attendance_faculty_id',
        widget.facultyData?['id'] ?? "01281",
      );
      await prefs.setString(
        'attendance_name',
        widget.facultyData?['name'] ?? "Manjiri Samant",
      );
      await prefs.setString('attendance_status', "Verified");
      await prefs.setString('attendance_login_time', loginTime);

      setState(() {
        _isAttendanceMarked = true;
        _attendanceData = {
          'faculty_id': widget.facultyData?['id'] ?? "01281",
          'name': widget.facultyData?['name'] ?? "Manjiri Samant",
          'status': "Verified",
          'login_time': loginTime,
          'date': date,
        };
      });
    } catch (e) {
      print("Error saving attendance: $e");
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = dateTime.hour > 12
        ? (dateTime.hour - 12).toString().padLeft(2, '0')
        : hour;
    return "$displayHour:$minute $period";
  }

  Widget _buildFacultyAttendanceCard() {
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
                Icon(
                  _isAttendanceMarked ? Icons.check_circle : Icons.fingerprint,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Faculty Attendance",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  "Today",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Attendance content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_isAttendanceMarked) ...[
                  // Success state with attendance details
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Attendance Verified",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _attendanceDetailRow(
                          "ID",
                          _attendanceData?['faculty_id'] ?? "01281",
                        ),
                        const SizedBox(height: 8),
                        _attendanceDetailRow(
                          "Name",
                          _attendanceData?['name'] ?? "Manjiri Samant",
                        ),
                        const SizedBox(height: 8),
                        _attendanceDetailRow(
                          "Status",
                          _attendanceData?['status'] ?? "Verified",
                        ),
                        const SizedBox(height: 8),
                        _attendanceDetailRow(
                          "Login Time",
                          _attendanceData?['login_time'] ?? "",
                        ),
                        const SizedBox(height: 8),
                        _attendanceDetailRow(
                          "Date",
                          _attendanceData?['date'] ?? "",
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Initial state
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: const Color(0xFFA50C22),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 40,
                      color: Color(0xFFA50C22),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Mark Your Attendance",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Use your fingerprint to securely mark your attendance",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _authenticateWithBiometrics(),
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: Text(
                        "Scan Fingerprint",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA50C22),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                          widget.facultyData?['name'] ?? "Manjiri Samant",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.facultyData?['email'] ??
                              "manjiris@somaiya.edu",
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
                    onPressed: () {},
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showFabOptionsDialog(),
              backgroundColor: const Color(0xFFA50C22),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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

  Widget _buildLectureCard() {
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
                  "Image Processing",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "023RC22",
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
                _lectureInfoRow(
                  Icons.business_outlined,
                  "Department",
                  "Computer(FYCO)",
                ),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(
                  Icons.access_time_rounded,
                  "Time Slot",
                  "10:30 to 11:30",
                ),
                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                _lectureInfoRow(
                  Icons.meeting_room_outlined,
                  "Room Number",
                  "207",
                ),
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
                    onPressed: () {
                      _showActionDialog("Assign this lecture");
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
                      "Assign this lec",
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
                    onPressed: () {
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
                      "Take lecture",
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
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "$action action completed",
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: const Color(0xFFA50C22),
                  ),
                );
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

  void _showFabOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "What would you like to do?",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fabOptionItem(
                Icons.assignment_outlined,
                "Create Assignment",
                "Create a new assignment for students",
                () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAssignmentScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _fabOptionItem(
                Icons.campaign_outlined,
                "Post announcement",
                "Create an announcement for students",
                () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostAnnouncementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _fabOptionItem(
                Icons.upload_file_outlined,
                "Upload Material",
                "Upload study materials for students",
                () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadMaterialScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fabOptionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA50C22).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFA50C22), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
      );
    } catch (e) {
      print(e);
      _showSnackBar(
        "Biometric authentication not available or not set up.",
        isError: true,
      );
      return;
    }

    if (authenticated) {
      print("Authentication successful, saving attendance...");
      await _saveAttendance();
      print("Attendance saved and state updated");
    } else {
      _showSnackBar(
        "Fingerprint authentication failed or cancelled.",
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
