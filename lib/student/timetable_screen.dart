import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Timer _clockTimer;

  // Live time
  DateTime _now = DateTime.now();

  // API data storage
  List<Map<String, dynamic>> _apiTimetableData = [];
  bool _isLoadingTimetable = true;
  String? _studentLabBatch;

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

    // Fetch timetable data from API
    _fetchTimetable();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Refresh every 30 seconds so the highlighted slot stays accurate
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  // ── API Call to fetch timetable ───────────────────────────────────────────────
  Future<void> _fetchTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentBatch = prefs.getString('studentYear') ?? '';
      final studentLabBatch = prefs.getString('studentLabBatch') ?? '';

      print('📚 [TIMETABLE] Fetching timetable for batch: $studentBatch');
      print('📚 [TIMETABLE] Student lab batch: $studentLabBatch');

      setState(() {
        _studentLabBatch = studentLabBatch;
      });

      if (studentBatch.isEmpty) {
        print('❌ [TIMETABLE] No batch found in SharedPreferences');
        setState(() {
          _isLoadingTimetable = false;
        });
        return;
      }

      final url = 'http://13.235.16.3:5001/timetable?batch=$studentBatch';
      print('📚 [TIMETABLE] API URL: $url');

      final response = await http.get(Uri.parse(url));
      print('📚 [TIMETABLE] Response status: ${response.statusCode}');
      print('📚 [TIMETABLE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📚 [TIMETABLE] Parsed JSON data: $data');

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> timetableData = data['data'];
          setState(() {
            _apiTimetableData = timetableData.cast<Map<String, dynamic>>();
            _isLoadingTimetable = false;
          });
          print(
            '📚 [TIMETABLE] Successfully fetched ${_apiTimetableData.length} timetable entries',
          );
        } else {
          print('❌ [TIMETABLE] API returned no data or failed');
          setState(() {
            _isLoadingTimetable = false;
          });
        }
      } else {
        print('❌ [TIMETABLE] API Error - Status: ${response.statusCode}');
        print('❌ [TIMETABLE] API Error - Body: ${response.body}');
        setState(() {
          _isLoadingTimetable = false;
        });
      }
    } catch (e) {
      print('❌ [TIMETABLE] Exception caught: $e');
      setState(() {
        _isLoadingTimetable = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  // ── Time slots ────────────────────────────────────────────────────────────
  final List<String> _timeSlots = [
    '10:30\n11:30',
    '11:30\n12:30',
    'LUNCH',
    '1:15\n2:15',
    '2:15\n3:15',
    '3:30\n4:30',
    '4:30\n5:30',
  ];

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

  // ── Process API data to generate timetable structure ─────────────────────────────
  List<Map<String, dynamic>> _generateTimetableFromAPI() {
    if (_apiTimetableData.isEmpty || _studentLabBatch == null) {
      return [];
    }

    // Initialize empty timetable structure
    final Map<String, List<Map<String, dynamic>>> dayWiseData = {
      'MON': List.filled(7, {'subject': '', 'faculty': '', 'room': ''}),
      'TUE': List.filled(7, {'subject': '', 'faculty': '', 'room': ''}),
      'WED': List.filled(7, {'subject': '', 'faculty': '', 'room': ''}),
      'THU': List.filled(7, {'subject': '', 'faculty': '', 'room': ''}),
      'FRI': List.filled(7, {'subject': '', 'faculty': '', 'room': ''}),
    };

    // Process each API entry
    for (final entry in _apiTimetableData) {
      final day = entry['day_of_week'] as String;
      final courseCode = entry['course_code'] as String;
      final facultyId = entry['faculty_id'] as String;
      final roomNumber = entry['room_number'] as String;
      final sessionType = entry['session_type'] as String;
      final labBatch = entry['lab_batch'] as String?;
      final startTime = entry['start_time'] as String;

      // Skip if it's a lab for a different batch
      if (sessionType == 'LAB' &&
          labBatch != null &&
          labBatch != _studentLabBatch) {
        continue;
      }

      // Find the slot index based on start time
      final slotIndex = _getSlotIndex(startTime);
      if (slotIndex == -1) continue;

      // For lab sessions (2 hours), mark both slots
      if (sessionType == 'LAB') {
        if (slotIndex < 6) {
          // Ensure we don't go out of bounds
          dayWiseData[day]?[slotIndex] = {
            'subject': courseCode,
            'faculty': facultyId,
            'room': roomNumber,
            'isLab': true,
          };
          dayWiseData[day]?[slotIndex + 1] = {
            'subject': '', // Mark next slot as occupied
            'faculty': '',
            'room': '',
            'isOccupiedByLab': true,
          };
        }
      } else {
        // Regular lecture (1 hour)
        dayWiseData[day]?[slotIndex] = {
          'subject': courseCode,
          'faculty': facultyId,
          'room': roomNumber,
          'isLab': false,
        };
      }

      print(
        '📚 [TIMETABLE] Processed: $day $courseCode ($sessionType) at $startTime - $facultyId in $roomNumber',
      );
    }

    // Convert to the expected format
    return dayWiseData.entries.map((entry) {
      return {
        'label': entry.key,
        'full': _getDayFullName(entry.key),
        'subjects': entry.value,
      };
    }).toList();
  }

  // ── Get slot index from time string ───────────────────────────────────────────
  int _getSlotIndex(String timeString) {
    final time = DateTime.parse('2000-01-01 $timeString');
    final hour = time.hour;
    final minute = time.minute;

    if (hour == 10 && minute == 30) return 0; // 10:30-11:30
    if (hour == 11 && minute == 30) return 1; // 11:30-12:30
    if (hour == 13 && minute == 15) return 3; // 1:15-2:15
    if (hour == 14 && minute == 15) return 4; // 2:15-3:15
    if (hour == 15 && minute == 30) return 5; // 3:30-4:30 (lab start)
    if (hour == 16 && minute == 30) return 6; // 4:30-5:30 (lab end)

    return -1; // Not found
  }

  // ── Get full day name ───────────────────────────────────────────────────────
  String _getDayFullName(String shortDay) {
    switch (shortDay) {
      case 'MON':
        return 'Monday';
      case 'TUE':
        return 'Tuesday';
      case 'WED':
        return 'Wednesday';
      case 'THU':
        return 'Thursday';
      case 'FRI':
        return 'Friday';
      default:
        return shortDay;
    }
  }

  // ── Get student year display from SharedPreferences ─────────────────────────
  Future<String> _getStudentYearDisplay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentYear = prefs.getString('studentYear') ?? '';
      final studentDepartment = prefs.getString('studentDepartment') ?? '';

      print('📚 [TIMETABLE] Student year: $studentYear');
      print('📚 [TIMETABLE] Student department: $studentDepartment');

      if (studentYear.isEmpty || studentDepartment.isEmpty) {
        return 'Loading...';
      }

      // Format: "SYCO - Computer Engineering"
      return '$studentYear - $studentDepartment';
    } catch (e) {
      print('❌ [TIMETABLE] Error loading student data: $e');
      return 'Error';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final todayIdx = _todayDayIndex;
    final activeSlot = _activeSlotIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),

      // ── App Bar ────────────────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: const Color(0xFFA50C22),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Timetable',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

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
                      FutureBuilder<String>(
                        future: _getStudentYearDisplay(),
                        builder: (context, snapshot) {
                          final yearDisplay = snapshot.data ?? 'Loading...';
                          return Text(
                            yearDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          );
                        },
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
                              color: const Color(0xFFA50C22),
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

          // Vertical spacing between header and timetable
          const SizedBox(height: 15),

          // Thin divider
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // ── Grid ────────────────────────────────────────────────────────
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
                    ..._generateTimetableFromAPI().asMap().entries.map(
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
    final subjects = dayData['subjects'] as List<Map<String, dynamic>>;

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
    required Map<String, dynamic> data,
    required int slotIndex,
    required bool isToday,
    required int activeSlot,
    required String dayLabel,
  }) {
    final isLunch = slotIndex == 2;
    final subject = data['subject'] as String? ?? '';
    final faculty = data['faculty'] as String? ?? '';
    final room = data['room'] as String? ?? '';
    final isLab = data['isLab'] as bool? ?? false;
    final spansTwoSlots = data['spansTwoSlots'] as bool? ?? false;
    final isOccupiedByLab = data['isOccupiedByLab'] as bool? ?? false;

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

    // Empty cell or occupied by lab (second slot)
    if (subject.isEmpty || isOccupiedByLab) {
      return const SizedBox(width: 80 + 6);
    }

    // A cell is "ongoing" only if it's today's row AND it's the active slot
    final isOngoing = isToday && slotIndex == activeSlot;

    // For labs that span two slots, make the cell wider
    final cellWidth = spansTwoSlots ? 160.0 : 80.0;

    return GestureDetector(
      onTap: () => _showSubjectModal(subject, faculty, room),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) {
          final bgColor = isOngoing
              ? Color.lerp(
                  const Color(0xFFFFF1F2),
                  const Color(0xFFFFE4E6),
                  _pulseAnimation.value,
                )!
              : isLab
              ? const Color(0xFFF0FDF4) // Green tint for labs
              : const Color(0xFFF9FAFB);

          final borderColor = isOngoing
              ? Color.lerp(
                  const Color(0xFFA50C22).withOpacity(0.4),
                  const Color(0xFFA50C22).withOpacity(0.9),
                  _pulseAnimation.value,
                )!
              : isLab
              ? const Color(0xFF16A34A)
              : const Color(0xFFE5E7EB);

          return Container(
            width: cellWidth,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: borderColor,
                width: isOngoing ? 1.5 : 1,
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
                    fontSize: isLab ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: isOngoing
                        ? const Color(0xFFA50C22)
                        : isLab
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                // Faculty
                Text(
                  faculty,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? const Color(0xFFA50C22).withOpacity(0.75)
                        : isLab
                        ? const Color(0xFF16A34A).withOpacity(0.75)
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
                        : isLab
                        ? const Color(0xFF16A34A).withOpacity(0.1)
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
                          : isLab
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                // Lab badge
                if (isLab) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isLab
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFA50C22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LAB • 2h',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
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
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Subject modal ─────────────────────────────────────────────────────────
  void _showSubjectModal(
    String courseCode,
    String facultyId,
    String roomNumber,
  ) {
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
                          courseCode,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Course Code',
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
                  _modalRow(Icons.person_outline_rounded, 'Faculty', facultyId),
                  const Divider(
                    height: 18,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  _modalRow(Icons.meeting_room_outlined, 'Room', roomNumber),
                  const Divider(
                    height: 18,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  _modalRow(Icons.tag_rounded, 'Course Code', courseCode),
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
