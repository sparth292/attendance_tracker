import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timetable_screen.dart';
import 'attendance_tracker_screen.dart';
import 'notifications_screen.dart';
import '../upcoming_events_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  
  const HomeScreen({Key? key, this.studentData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _attendanceData;
  double _overallPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    try {
      // Get current user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      
      if (userId.isNotEmpty) {
        // Load attendance data
        final attendanceJson = await rootBundle.loadString('assets/json/attendance_percentage.json');
        final attendanceMap = json.decode(attendanceJson);
        
        if (attendanceMap.containsKey(userId)) {
          setState(() {
            _attendanceData = attendanceMap[userId];
            _overallPercentage = _attendanceData?['overallPercentage']?.toDouble() ?? 0.0;
          });
        }
      }
    } catch (e) {
      print('Error loading attendance data: $e');
    }
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
                            widget.studentData?['name'] ?? "Parth Salunke",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "FCUG23749",
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ─── CURRENT LECTURE ───────────────────────────────────────
                _sectionLabel("Current Lecture"),
                const SizedBox(height: 10),
                const _CurrentLectureCard(),

                const SizedBox(height: 22),

                /// ─── ATTENDANCE TRACKER ────────────────────────────────────
                _sectionLabel("Attendance Tracker"),
                const SizedBox(height: 10),
                GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceTrackerScreen()),
                  );
                },
                child: _AttendanceCard(overallPercentage: _overallPercentage),
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
  const _CurrentLectureCard();

  @override
  Widget build(BuildContext context) {
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
                  "Lecturer",
                  "Manjiri Samant",
                ),
                const _divider(),
                _lectureInfoRow(
                  Icons.access_time_rounded,
                  "Time Slot",
                  "10:30 AM – 11:30 AM",
                ),
                const _divider(),
                _lectureInfoRow(Icons.meeting_room_outlined, "Room No", "207"),
                const _divider(),
                _lectureInfoRow(
                  Icons.computer_outlined,
                  "Department",
                  "Computer",
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
        icon: Icons.menu_book_outlined,
        label: "Subjects",
        onTap: () {},
      ),
      _QuickItem(
        icon: Icons.receipt_long_outlined,
        label: "Concession",
        onTap: () {},
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
