import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      if (mounted) setState(() => _now = DateTime.now());
    });
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

  // ── Timetable data ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _days = [
    {
      'label': 'MON',
      'full': 'Monday',
      'subjects': [
        {'subject': 'IP', 'faculty': 'MS', 'room': '207'},
        {'subject': 'SE', 'faculty': 'VSG', 'room': '209'},
        {'subject': '', 'faculty': '', 'room': ''},
        {'subject': 'LAN', 'faculty': 'NRK', 'room': '207'},
        {'subject': 'CC', 'faculty': 'PRA', 'room': '301'},
        {'subject': 'DB', 'faculty': 'MS', 'room': '402'},
        {'subject': 'CN', 'faculty': 'MS', 'room': '205'},
      ],
    },
    {
      'label': 'TUE',
      'full': 'Tuesday',
      'subjects': [
        {'subject': 'IP', 'faculty': 'MS', 'room': '207'},
        {'subject': 'SE Lab', 'faculty': 'MS', 'room': '404'},
        {'subject': '', 'faculty': '', 'room': ''},
        {'subject': 'DB Lab', 'faculty': 'MS', 'room': '402'},
        {'subject': 'CC', 'faculty': 'PRA', 'room': '301'},
        {'subject': 'LAN', 'faculty': 'NRK', 'room': '207'},
        {'subject': 'SE', 'faculty': 'VSG', 'room': '209'},
      ],
    },
    {
      'label': 'WED',
      'full': 'Wednesday',
      'subjects': [
        {'subject': 'DB', 'faculty': 'MS', 'room': '402'},
        {'subject': 'IP Lab', 'faculty': 'MS', 'room': '301'},
        {'subject': '', 'faculty': '', 'room': ''},
        {'subject': 'SE', 'faculty': 'VSG', 'room': '209'},
        {'subject': 'LAN', 'faculty': 'NRK', 'room': '207'},
        {'subject': 'CC', 'faculty': 'PRA', 'room': '301'},
        {'subject': 'CN', 'faculty': 'MS', 'room': '205'},
      ],
    },
    {
      'label': 'THU',
      'full': 'Thursday',
      'subjects': [
        {'subject': 'CN', 'faculty': 'MS', 'room': '205'},
        {'subject': 'DB Lab', 'faculty': 'MS', 'room': '402'},
        {'subject': '', 'faculty': '', 'room': ''},
        {'subject': 'IP Lab', 'faculty': 'MS', 'room': '301'},
        {'subject': 'SE Lab', 'faculty': 'VSG', 'room': '404'},
        {'subject': 'CC', 'faculty': 'PRA', 'room': '301'},
        {'subject': 'LAN', 'faculty': 'NRK', 'room': '207'},
      ],
    },
    {
      'label': 'FRI',
      'full': 'Friday',
      'subjects': [
        {'subject': 'IP', 'faculty': 'MS', 'room': '207'},
        {'subject': 'CC Lab', 'faculty': 'MS', 'room': '402'},
        {'subject': '', 'faculty': '', 'room': ''},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': 'SE', 'faculty': 'VSG', 'room': '209'},
        {'subject': 'LAN', 'faculty': 'NRK', 'room': '207'},
      ],
    },
    {
      'label': 'SAT',
      'full': 'Saturday',
      'subjects': [
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': '', 'faculty': '', 'room': ''},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
        {'subject': 'Project', 'faculty': 'MS', 'room': 'Lab'},
      ],
    },
  ];

  // ── Subject detail lookup ─────────────────────────────────────────────────
  Map<String, String> _subjectDetail(String abbr) {
    const Map<String, Map<String, String>> details = {
      'IP': {'name': 'Image Processing', 'code': '023RC22'},
      'SE': {'name': 'Software Engineering', 'code': '023RC23'},
      'LAN': {'name': 'Local Area Networks', 'code': '023RC24'},
      'CC Lab': {'name': 'Cloud Computing Lab', 'code': '023RC25'},
      'LAN Lab': {'name': 'LAN Lab', 'code': '023RC26'},
      'SE Lab': {'name': 'Software Engineering Lab', 'code': '023RC27'},
      'Project': {'name': 'Project Work', 'code': '023RC28'},
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),

      // ── App Bar ────────────────────────────────────────────────────
      appBar: AppBar(
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
        title: const SizedBox.shrink(),
        automaticallyImplyLeading: true,
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
                      Text(
                        'Faculty — ${widget.facultyData?['name'] ?? "Manjiri Samant"}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Computer Engineering — Term – Even  • Semester VI',
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
    final subject = data['subject']!;
    final faculty = data['faculty']!;
    final room = data['room']!;

    // Check if this is the current faculty's lecture
    final facultyName = widget.facultyData?['name'] ?? '';
    final isFacultyLecture =
        facultyName.isNotEmpty &&
        (faculty == facultyName.split(' ').map((word) => word[0]).join('') ||
            faculty ==
                facultyName.substring(
                  0,
                  facultyName.length > 3 ? 3 : facultyName.length,
                ));

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
      onTap: () => _showSubjectModal(subject, faculty, room),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) {
          // Enhanced highlighting for faculty's own lectures
          final isFacultyHighlight = isFacultyLecture && isToday;

          final bgColor = isOngoing
              ? Color.lerp(
                  const Color(0xFFFFF1F2),
                  const Color(0xFFFFE4E6),
                  _pulseAnimation.value,
                )!
              : isFacultyHighlight
              ? const Color(0xFFE8F5E8) // Light green for faculty's lectures
              : const Color(0xFFF9FAFB);

          final borderColor = isOngoing
              ? Color.lerp(
                  const Color(0xFFA50C22).withOpacity(0.4),
                  const Color(0xFFA50C22).withOpacity(0.9),
                  _pulseAnimation.value,
                )!
              : isFacultyHighlight
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
                width: isOngoing ? 1.5 : (isFacultyHighlight ? 1.5 : 1),
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
                        : isFacultyHighlight
                        ? const Color(
                            0xFF2E7D32,
                          ) // Dark green for faculty's lectures
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
                        : isFacultyHighlight
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
                        : isFacultyHighlight
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
                          : isFacultyHighlight
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
                if (isFacultyHighlight && !isOngoing) ...[
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
  void _showSubjectModal(String abbr, String faculty, String room) {
    final detail = _subjectDetail(abbr);

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
                  _modalRow(Icons.person_outline_rounded, 'Faculty', faculty),
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
