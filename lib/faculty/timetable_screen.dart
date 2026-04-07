import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TimetableScreen extends StatefulWidget {
  final Map<String, dynamic>? facultyData;

  const TimetableScreen({Key? key, this.facultyData}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Timer _clockTimer;
  Map<String, dynamic>? facultyInfo;

  // Live time
  DateTime _now = DateTime.now();

  // Slot time ranges: [startHour, startMin, endHour, endMin]
  final List<List<int>> _slotRanges = [
    [10, 30, 11, 30],
    [11, 30, 12, 30],
    [-1, -1, -1, -1], // LUNCH — never active
    [13, 15, 14, 15],
    [14, 15, 15, 15],
    [15, 30, 16, 30],
    [16, 30, 17, 30],
  ];

  // Returns 0–6 index of active slot, or -1 if none
  int get _activeSlotIndex {
    final mins = _now.hour * 60 + _now.minute;
    for (int i = 0; i < _slotRanges.length; i++) {
      final r = _slotRanges[i];
      if (r[0] == -1) continue;
      final start = r[0] * 60 + r[1];
      final end = r[2] * 60 + r[3];
      if (mins >= start && mins < end) return i;
    }
    return -1;
  }

  // 0 = MON … 5 = SAT; -1 if Sunday or not a school day
  int get _todayDayIndex {
    final wd = _now.weekday; // 1=Mon … 7=Sun
    if (wd >= 1 && wd <= 6) return wd - 1;
    return -1;
  }

  @override
  void initState() {
    super.initState();
    _loadFacultyData();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Refresh every 30 seconds so that highlighted slot stays accurate
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        // Also refresh faculty data to ensure it's current
        _loadFacultyData();
      }
    });
  }

  Future<void> _loadFacultyData() async {
    try {
      // Get faculty ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      print('📋 [TIMETABLE] Loading timetable for faculty ID: $facultyId');

      // Fetch timetable from API
      final timetableData = await _fetchTimetableFromAPI(facultyId);

      setState(() {
        facultyInfo = {'id': facultyId};
        _days = _generateTimetableFromAPI(timetableData);
      });
    } catch (e) {
      print("❌ [TIMETABLE] Error loading faculty data: $e");
      // Fallback to local data if API fails
      _loadLocalFacultyData();
    }
  }

  // Fallback method to load local data
  Future<void> _loadLocalFacultyData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/faculty.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      final facultyId = widget.facultyData?['id'] ?? "Faculty";
      final faculty = data[facultyId];

      setState(() {
        facultyInfo = faculty;
        _days = _generateTimetableFromFacultyData();
      });
    } catch (e) {
      print("❌ [TIMETABLE] Error loading local faculty data: $e");
    }
  }

  // Fetch timetable from API
  Future<List<Map<String, dynamic>>> _fetchTimetableFromAPI(
    String facultyId,
  ) async {
    final url = Uri.parse(
      "http://13.235.16.3:5000/api/faculty/full-timetable?faculty_id=$facultyId",
    );

    print('📡 [API] Fetching timetable from: $url');

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    print('📊 [API] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to fetch timetable: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  // ── Time slots ────────────────────────────────────────────────────
  final List<String> _timeSlots = [
    '10:30\n11:30',
    '11:30\n12:30',
    'LUNCH',
    '1:15\n2:15',
    '2:15\n3:15',
    '3:30\n4:30',
    '4:30\n5:30',
  ];

  // ── Generate timetable from API response ─────────────────────────────
  List<Map<String, dynamic>> _generateTimetableFromAPI(
    List<Map<String, dynamic>> apiData,
  ) {
    final timetable = <String, Map<String, dynamic>>{};

    // Initialize all slots as empty
    const dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    for (int day = 0; day < 6; day++) {
      timetable[dayLabels[day]] = {
        'label': dayLabels[day],
        'full': _getDayFullName(dayLabels[day]),
        'subjects': List.generate(
          7,
          (slotIndex) => {'subject': '', 'batch': '', 'room': ''},
        ),
      };
    }

    // Fill slots with API data
    for (final entry in apiData) {
      final day = entry['day_of_week'] as String;
      final startTime = entry['start_time'] as String;
      final courseName = entry['course_name'] as String;
      final room = entry['room_number'] as String;
      final batch = entry['batch'] as String? ?? '';
      final sessionType = entry['session_type'] as String;

      final dayIndex = _getDayIndex(day);
      if (dayIndex != -1) {
        final slotIndex = _getSlotIndexFromTime(startTime);
        if (slotIndex != -1 && slotIndex != 2) {
          // Not lunch
          timetable[dayLabels[dayIndex]]!['subjects'][slotIndex] = {
            'subject': _getSubjectAbbreviation(courseName),
            'batch': batch,
            'room': room,
            'course_name': courseName,
            'session_type': sessionType,
          };
        }
      }
    }

    return timetable.values.toList();
  }

  // ── Generate timetable from faculty data (fallback) ─────────────────────
  List<Map<String, dynamic>> _generateTimetableFromFacultyData() {
    final timetable = <String, Map<String, dynamic>>{};

    // Initialize all slots as empty
    const dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    for (int day = 0; day < 6; day++) {
      timetable[dayLabels[day]] = {
        'label': dayLabels[day],
        'full': _getDayFullName(dayLabels[day]),
        'subjects': List.generate(
          7,
          (slotIndex) => {'subject': '', 'batch': '', 'room': ''},
        ),
      };
    }

    // Fill slots with faculty's subject schedules
    if (facultyInfo != null && facultyInfo!['schedule'] != null) {
      final schedule = facultyInfo!['schedule'] as List<dynamic>;

      for (final subject in schedule) {
        final subjectName = subject['subject'] as String;
        final subjectCode = subject['code'] as String;
        final timeSlots = subject['time_slots'] as List<dynamic>;

        for (final slot in timeSlots) {
          final day = slot['day'] as String;
          final time = slot['time'] as String;
          final room = slot['room'] as String;
          final batch = slot['batch'] as String? ?? '';

          final dayIndex = _getDayIndex(day);
          if (dayIndex != -1) {
            final slotIndex = _getSlotIndex(time);
            if (slotIndex != -1 && slotIndex != 2) {
              // Not lunch
              timetable[dayLabels[dayIndex]]!['subjects'][slotIndex] = {
                'subject': _getSubjectAbbreviation(subjectName),
                'batch': batch,
                'room': room,
              };
            }
          }
        }
      }
    }

    return timetable.values.toList();
  }

  // Helper methods for dynamic scheduling
  String _getDayFullName(String dayLabel) {
    final days = {
      'MON': 'Monday',
      'TUE': 'Tuesday',
      'WED': 'Wednesday',
      'THU': 'Thursday',
      'FRI': 'Friday',
      'SAT': 'Saturday',
    };
    return days[dayLabel] ?? dayLabel;
  }

  int _getDayIndex(String dayLabel) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return days.indexOf(dayLabel);
  }

  int _getSlotIndex(String timeSlot) {
    final slotMap = {
      '10:30-11:30': 0,
      '11:30-12:30': 1,
      '1:15-2:15': 3,
      '2:15-3:15': 4,
      '3:30-4:30': 5,
      '4:30-5:30': 6,
    };
    return slotMap[timeSlot] ?? -1;
  }

  // Convert time string from API (HH:MM:SS) to slot index
  int _getSlotIndexFromTime(String timeString) {
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final totalMinutes = hour * 60 + minute;

    // Map time ranges to slot indices
    if (totalMinutes >= 630 && totalMinutes < 690) return 0; // 10:30-11:30
    if (totalMinutes >= 690 && totalMinutes < 750) return 1; // 11:30-12:30
    if (totalMinutes >= 795 && totalMinutes < 855) return 3; // 13:15-14:15
    if (totalMinutes >= 855 && totalMinutes < 915) return 4; // 14:15-15:15
    if (totalMinutes >= 930 && totalMinutes < 990) return 5; // 15:30-16:30
    if (totalMinutes >= 990 && totalMinutes < 1050) return 6; // 16:30-17:30

    return -1; // No matching slot
  }

  String _getSubjectAbbreviation(String subjectName) {
    final abbreviations = {
      'Image Processing': 'IP',
      'Software Engineering': 'SE',
      'Database Systems': 'DB',
      'Computer Networks': 'CN',
      'Cloud Computing': 'CC',
      'Data Structures': 'DS',
      'Algorithms': 'AL',
      'Operating Systems': 'OS',
      'Web Development': 'WD',
      'Local Area Networks': 'LAN',
      'Web Design Lab': 'WD LAB',
      'Software Engineering LAB': 'SE LAB',
    };
    return abbreviations[subjectName] ??
        subjectName.substring(0, 3).toUpperCase();
  }

  String _getBatchForSubject(String subjectName) {
    if (facultyInfo != null && facultyInfo!['schedule'] != null) {
      final schedule = facultyInfo!['schedule'] as List<dynamic>;

      for (final subject in schedule) {
        final subjectNameInSchedule = subject['subject'] as String;
        final timeSlots = subject['time_slots'] as List<dynamic>;

        // If this is the subject we're looking for, return the batch from its first time slot
        if (subjectNameInSchedule == subjectName && timeSlots.isNotEmpty) {
          return timeSlots.first['batch'] as String? ?? '';
        }
      }
    }
    return '';
  }

  // ── Timetable data (will be generated dynamically) ─────────────────────
  List<Map<String, dynamic>> _days = [];

  // ── Subject detail lookup ─────────────────────────────────────────────────
  Map<String, String> _subjectDetail(String abbr) {
    const Map<String, Map<String, String>> details = {
      'IP': {'name': 'Image Processing', 'code': '023RC22'},
      'SE': {'name': 'Software Engineering', 'code': '023RC23'},
      'LAN': {'name': 'Local Area Networks', 'code': '023RC24'},
      'CC': {'name': 'Cloud Computing', 'code': '023RC25'},
      'DB': {'name': 'Database Systems', 'code': '023RC26'},
      'CN': {'name': 'Computer Networks', 'code': '023RC27'},
      'IP Lab': {'name': 'Image Processing Lab', 'code': '023RC28'},
      'SE Lab': {'name': 'Software Engineering Lab', 'code': '023RC29'},
      'CC Lab': {'name': 'Cloud Computing Lab', 'code': '023RC30'},
      'DB Lab': {'name': 'Database Lab', 'code': '023RC31'},
      'Project': {'name': 'Project Work', 'code': '023RC32'},
    };
    return Map<String, String>.from(
      details[abbr] ?? {'name': abbr, 'code': '—'},
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _todayLabel {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return labels[_now.weekday - 1];
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final todayIdx = _todayDayIndex;
    final activeSlot = _activeSlotIndex;

    if (facultyInfo == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header info ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Timetable',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        facultyInfo?['id'] ?? "FAC001",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Today chip — shows current day name, pulses when a class is ongoing
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) {
                    final isOngoing = todayIdx != -1 && activeSlot != -1;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOngoing
                            ? Color.lerp(
                                const Color(0xFFFFF1F2),
                                const Color(0xFFFFE4E6),
                                _pulseAnimation.value,
                              )
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOngoing
                              ? const Color(0xFFA50C22).withOpacity(0.35)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOngoing
                                  ? Color.lerp(
                                      const Color(0xFFA50C22),
                                      const Color(0xFFDC2626),
                                      _pulseAnimation.value,
                                    )
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _todayLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOngoing
                                  ? const Color(0xFFA50C22)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Thin divider
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // ── Grid ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeHeader(activeSlot, todayIdx),
                    const SizedBox(height: 8),
                    ..._days.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _buildDayRow(
                          entry.key,
                          entry.value,
                          todayIdx,
                          activeSlot,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Time header ───────────────────────────────────────────────────────────
  Widget _buildTimeHeader(int activeSlot, int todayIdx) {
    return Row(
      children: [
        const SizedBox(width: 48),
        const SizedBox(width: 6),
        ..._timeSlots.asMap().entries.map((e) {
          final isLunch = e.key == 2;
          // Highlight header column only when it's today AND that slot is active
          final isActiveNow = !isLunch && e.key == activeSlot && todayIdx != -1;

          return Container(
            width: isLunch ? 58 : 80,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isActiveNow
                  ? const Color(0xFFA50C22).withOpacity(0.08)
                  : isLunch
                  ? const Color(0xFFF3F4F6)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isActiveNow
                    ? const Color(0xFFA50C22).withOpacity(0.5)
                    : const Color(0xFFE5E7EB),
                width: isActiveNow ? 1.5 : 1,
              ),
            ),
            child: Text(
              e.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isLunch ? 8 : 9,
                fontWeight: isActiveNow ? FontWeight.w700 : FontWeight.w600,
                color: isActiveNow
                    ? const Color(0xFFA50C22)
                    : isLunch
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Day row ───────────────────────────────────────────────────────────────
  Widget _buildDayRow(
    int dayIndex,
    Map<String, dynamic> dayData,
    int todayIdx,
    int activeSlot,
  ) {
    final isToday = dayIndex == todayIdx;
    final subjects = dayData['subjects'] as List<Map<String, String>>;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? const Color(0xFFA50C22).withOpacity(0.45)
              : const Color(0xFFE5E7EB),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isToday ? 0.06 : 0.03),
            blurRadius: isToday ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Day label
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFFA50C22)
                  : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                bottomLeft: Radius.circular(9),
              ),
              border: Border(
                right: BorderSide(
                  color: isToday
                      ? const Color(0xFFA50C22)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Text(
              dayData['label'],
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isToday ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Subject cells
          ...subjects.asMap().entries.map((e) {
            return _buildCell(
              data: e.value,
              slotIndex: e.key,
              isToday: isToday,
              activeSlot: activeSlot,
              dayLabel: dayData['label'],
            );
          }),
        ],
      ),
    );
  }

  // ── Individual cell ───────────────────────────────────────────────────────
  Widget _buildCell({
    required Map<String, String> data,
    required int slotIndex,
    required bool isToday,
    required int activeSlot,
    required String dayLabel,
  }) {
    final isLunch = slotIndex == 2;
    final subject = data['subject'] ?? '';
    final batch = data['batch'] ?? '';
    final room = data['room'] ?? '';

    // LUNCH BREAK cell
    if (isLunch) {
      return Container(
        width: 58,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          'LUNCH\nBREAK',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9CA3AF),
            height: 1.5,
          ),
        ),
      );
    }

    // Empty cell
    if (subject.isEmpty) {
      return const SizedBox(width: 80 + 6);
    }

    // A cell is "ongoing" only if it's today's row AND it's the active slot
    final isOngoing = isToday && slotIndex == activeSlot;

    return GestureDetector(
      onTap: () => _showSubjectModal(subject, batch, room),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) {
          // Enhanced highlighting for faculty's own lectures
          final isFacultyLecture = batch.isNotEmpty && isToday;

          final bgColor = isOngoing
              ? Color.lerp(
                  const Color(0xFFFFF1F2),
                  const Color(0xFFFFE4E6),
                  _pulseAnimation.value,
                )!
              : isFacultyLecture
              ? const Color(0xFFE8F5E8) // Light green for faculty's lectures
              : const Color(0xFFF9FAFB);

          final borderColor = isOngoing
              ? Color.lerp(
                  const Color(0xFFA50C22).withOpacity(0.4),
                  const Color(0xFFA50C22).withOpacity(0.9),
                  _pulseAnimation.value,
                )!
              : isFacultyLecture
              ? const Color(0xFF4CAF50) // Green border for faculty's lectures
              : const Color(0xFFE5E7EB);

          return Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: borderColor,
                width: isOngoing ? 1.5 : (isFacultyLecture ? 1.5 : 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Subject abbreviation
                Text(
                  subject,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOngoing
                        ? const Color(0xFFA50C22)
                        : isFacultyLecture
                        ? const Color(
                            0xFF2E7D32,
                          ) // Dark green for faculty's lectures
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                // Batch
                Text(
                  batch,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? const Color(0xFFA50C22).withOpacity(0.75)
                        : isFacultyLecture
                        ? const Color(0xFF2E7D32).withOpacity(0.8)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
                // Room pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? const Color(0xFFA50C22).withOpacity(0.1)
                        : isFacultyLecture
                        ? const Color(0xFF4CAF50).withOpacity(0.2)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    room,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isOngoing
                          ? const Color(0xFFA50C22)
                          : isFacultyLecture
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                // "NOW" badge for ongoing
                if (isOngoing) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA50C22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '● NOW',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
                // Faculty indicator for their own lectures
                if (isFacultyLecture && !isOngoing) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '● MY',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Subject modal ─────────────────────────────────────────────────────────
  void _showSubjectModal(String abbr, String batch, String room) {
    final detail = _subjectDetail(abbr);

    // Find which batch this subject belongs to
    final subjectBatch = _getBatchForSubject(detail['name']!);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFA50C22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail['name']!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail['code']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _modalRow(Icons.person_outline_rounded, 'Faculty', batch),
                  const Divider(
                    height: 18,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  _modalRow(Icons.meeting_room_outlined, 'Room', room),
                  const Divider(
                    height: 18,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  _modalRow(Icons.tag_rounded, 'Course Code', detail['code']!),
                  const Divider(
                    height: 18,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  _modalRow(Icons.group_outlined, 'Batch', subjectBatch),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalRow(IconData icon, String label, String value) {
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
