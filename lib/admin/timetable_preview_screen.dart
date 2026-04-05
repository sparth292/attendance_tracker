import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const kPrimary      = Color(0xFFA50C22);
const kPrimaryLight = Color(0xFFFCE4EC);
const kBg           = Color(0xFFF1F3F6);
const kSurface      = Colors.white;
const kBorder       = Color(0xFFE5E7EB);
const kTextDark     = Color(0xFF111827);
const kTextMid      = Color(0xFF374151);
const kTextLight    = Color(0xFF6B7280);
const kTextFaint    = Color(0xFF9CA3AF);

const kLectureBg     = Color(0xFFEFF6FF);
const kLectureBorder = Color(0xFF93C5FD);
const kLectureText   = Color(0xFF1D4ED8);

const kLabBg     = Color(0xFFFCE4EC);
const kLabBorder = Color(0xFFA50C22);

const kProjectBg     = Color(0xFFF0FDF4);
const kProjectBorder = Color(0xFF6EE7B7);
const kProjectText   = Color(0xFF065F46);

// Break colors
const kBreakBg     = Color(0xFFFFFBEB);
const kBreakBorder = Color(0xFFFBBF24);
const kBreakText   = Color(0xFF92400E);

// ─── Break definitions ────────────────────────────────────────────────────────
class _Break {
  final String start;   // "12:30"
  final String end;     // "13:15"
  final String label;   // "Lunch\nBreak"
  final String emoji;
  final double width;
  const _Break({
    required this.start,
    required this.end,
    required this.label,
    required this.emoji,
    required this.width,
  });
}

const _kBreaks = [
  _Break(start: '12:30', end: '13:15', label: 'Lunch\nBreak', emoji: '', width: 52),
  _Break(start: '15:15', end: '15:30', label: 'High\nTea',    emoji: '', width: 40),
];

// ─── Constants ────────────────────────────────────────────────────────────────
const double kDayColW = 72;
const double kSlotW   = 112.0;
const double kRowH    = 92.0;
const double kHeaderH = 56.0;

const List<String> kDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
const Map<String, String> kDayFull = {
  'MON': 'Monday', 'TUE': 'Tuesday', 'WED': 'Wednesday',
  'THU': 'Thursday', 'FRI': 'Friday', 'SAT': 'Saturday',
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _fmt(String? t) =>
    (t != null && t.length >= 5) ? t.substring(0, 5) : (t ?? '');

int _toMin(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String _fromMin(int m) {
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$h:$mm';
}

// A column is either a regular time slot or a break
class _Col {
  final String start;
  final bool isBreak;
  final _Break? breakDef;
  const _Col(this.start, {this.isBreak = false, this.breakDef});
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class TimetablePreviewScreen extends StatelessWidget {
  final String batch;
  final List<Map<String, dynamic>> timetable;

  const TimetablePreviewScreen({
    Key? key,
    required this.batch,
    required this.timetable,
  }) : super(key: key);

  // ── Derive ordered columns (time slots + breaks interleaved) ──────────────
  List<_Col> _buildCols() {
    // 1. Collect all 1-hour slot starts from data
    final starts = <String>{};
    for (final e in timetable) {
      final s   = _fmt(e['start_time'] as String?);
      final end = _fmt(e['end_time']   as String?);
      if (s.isEmpty || end.isEmpty) continue;
      int cur = _toMin(s);
      final endMin = _toMin(end);
      while (cur < endMin) {
        starts.add(_fromMin(cur));
        cur += 60;
      }
    }

    // 2. Also add break start times so they appear in sorted order
    final breakStarts = { for (final b in _kBreaks) b.start };

    // 3. Merge and sort all unique time points
    final all = <String>{...starts, ...breakStarts}.toList()..sort();

    // 4. Build _Col list — tag breaks
    return all.map((t) {
      final brk = _kBreaks.cast<_Break?>().firstWhere(
        (b) => b!.start == t, orElse: () => null);
      if (brk != null) {
        return _Col(t, isBreak: true, breakDef: brk);
      }
      return _Col(t);
    }).toList();
  }

  int _spanOf(Map<String, dynamic> entry, List<_Col> cols) {
    final s   = _fmt(entry['start_time'] as String?);
    final end = _fmt(entry['end_time']   as String?);
    if (s.isEmpty || end.isEmpty) return 1;
    final startMin = _toMin(s);
    final endMin   = _toMin(end);
    // Count how many non-break cols this entry spans
    int span = 0;
    for (final col in cols) {
      if (col.isBreak) continue;
      final colMin = _toMin(col.start);
      if (colMin >= startMin && colMin < endMin) span++;
    }
    return span.clamp(1, 99);
  }

  bool _startsAt(Map<String, dynamic> entry, String colStart) =>
      _fmt(entry['start_time'] as String?) == colStart;

  bool _covers(Map<String, dynamic> entry, String colStart) {
    final s   = _fmt(entry['start_time'] as String?);
    final end = _fmt(entry['end_time']   as String?);
    if (s.isEmpty || end.isEmpty) return false;
    final colMin   = _toMin(colStart);
    final startMin = _toMin(s);
    final endMin   = _toMin(end);
    return colMin > startMin && colMin < endMin;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '$batch Timetable',
          style: GoogleFonts.lato(
            color: Colors.white, fontSize: 20,
            fontWeight: FontWeight.w700, letterSpacing: 0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          _infoHeader(),
          Expanded(child: timetable.isEmpty ? _empty() : _grid()),
        ],
      ),
    );
  }

  Widget _infoHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryLight, borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.calendar_month, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$batch – Computer Engineering',
                style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15, color: kTextDark)),
            Text('${timetable.length} entries loaded',
                style: GoogleFonts.lato(fontSize: 12, color: kTextLight)),
          ]),
        ),
        _legend(kLectureBg, kLectureBorder, 'Lecture'),
        const SizedBox(width: 8),
        _legend(kLabBg, kLabBorder, 'Lab'),
        const SizedBox(width: 8),
        _legend(kBreakBg, kBreakBorder, 'Break'),
      ]),
    );
  }

  Widget _legend(Color fill, Color border, String label) {
    return Row(children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.lato(fontSize: 11, color: kTextLight)),
    ]);
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.calendar_today, size: 64, color: kTextFaint),
        const SizedBox(height: 16),
        Text('No timetable data available',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600, color: kTextLight)),
        const SizedBox(height: 8),
        Text('Please try again later',
            style: GoogleFonts.lato(fontSize: 14, color: kTextFaint)),
      ]),
    );
  }

  // ─── Grid ─────────────────────────────────────────────────────────────────
  Widget _grid() {
    final cols = _buildCols();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: _table(cols),
      ),
    );
  }

  Widget _table(List<_Col> cols) {
    // ── Header ───────────────────────────────────────────────────────────────
    final headerCells = <Widget>[_hCell('Day / Time', kDayColW, isCorner: true)];

    for (int ci = 0; ci < cols.length; ci++) {
      final col = cols[ci];
      if (col.isBreak) {
        headerCells.add(_breakHeaderCell(col.breakDef!));
      } else {
        // Compute end label: next non-break col start, or +60 min
        int endMin = _toMin(col.start) + 60;
        for (int ni = ci + 1; ni < cols.length; ni++) {
          if (!cols[ni].isBreak) { endMin = _toMin(cols[ni].start); break; }
        }
        headerCells.add(_hCell('${col.start}\nTO\n${_fromMin(endMin)}', kSlotW));
      }
    }

    final List<Widget> rows = [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: headerCells),
      Container(height: 2, color: kPrimary, margin: const EdgeInsets.symmetric(vertical: 2)),
    ];

    // ── Day rows ─────────────────────────────────────────────────────────────
    for (final day in kDays) {
      final dayEntries = timetable.where((e) => e['day_of_week'] == day).toList();
      if (dayEntries.isEmpty) continue;

      final consumed = <int>{};
      final cells = <Widget>[_dayCell(day)];

      for (int ci = 0; ci < cols.length; ci++) {
        final col = cols[ci];

        // Always render break columns
        if (col.isBreak) {
          cells.add(_breakDataCell(col.breakDef!));
          continue;
        }

        if (consumed.contains(ci)) continue;

        final starters = dayEntries.where((e) => _startsAt(e, col.start)).toList();

        if (starters.isEmpty) {
          final covered = dayEntries.any((e) => _covers(e, col.start));
          if (!covered) cells.add(_emptyCell(kSlotW));
          continue;
        }

        if (starters.length == 1) {
          final entry = starters.first;
          final span  = _spanOf(entry, cols);
          // Mark consumed non-break cols
          int counted = 0;
          for (int ni = ci + 1; ni < cols.length && counted < span - 1; ni++) {
            if (!cols[ni].isBreak) { consumed.add(ni); counted++; }
          }
          // Pixel width = span * kSlotW (breaks in between are NOT included)
          cells.add(_entryCell(entry, kSlotW * span));
        } else {
          final span = _spanOf(starters.first, cols);
          int counted = 0;
          for (int ni = ci + 1; ni < cols.length && counted < span - 1; ni++) {
            if (!cols[ni].isBreak) { consumed.add(ni); counted++; }
          }
          cells.add(_multiCell(starters, kSlotW * span));
        }
      }

      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells));
      rows.add(Container(height: 1, color: kBorder));
    }

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  // ─── Cell builders ────────────────────────────────────────────────────────

  Widget _hCell(String text, double w, {bool isCorner = false}) {
    return Container(
      width: w, height: kHeaderH,
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(right: BorderSide(color: kBorder)),
      ),
      alignment: Alignment.center,
      child: Text(text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(
          fontSize: isCorner ? 12 : 11,
          fontWeight: FontWeight.w700,
          color: kTextMid, height: 1.4,
        ),
      ),
    );
  }

  Widget _breakHeaderCell(_Break brk) {
    return Container(
      width: brk.width, height: kHeaderH,
      decoration: const BoxDecoration(
        color: kBreakBg,
        border: Border(
          right: BorderSide(color: kBreakBorder),
          left:  BorderSide(color: kBreakBorder),
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(brk.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(
          brk.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 8, fontWeight: FontWeight.w700,
            color: kBreakText, height: 1.3,
          ),
        ),
      ]),
    );
  }

  Widget _dayCell(String day) {
    return Container(
      width: kDayColW, height: kRowH,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(day, style: GoogleFonts.lato(
            fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)),
        Text(kDayFull[day] ?? '',
            style: GoogleFonts.lato(fontSize: 9, color: kTextLight)),
      ]),
    );
  }

  Widget _emptyCell(double w) {
    return Container(
      width: w, height: kRowH,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: kBorder)),
      ),
    );
  }

  Widget _breakDataCell(_Break brk) {
    return Container(
      width: brk.width, height: kRowH,
      decoration: BoxDecoration(
        color: kBreakBg,
        border: Border(
          right: const BorderSide(color: kBreakBorder),
          left:  const BorderSide(color: kBreakBorder),
        ),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            '${brk.emoji} ${brk.label.replaceAll('\n', ' ')}',
            style: GoogleFonts.lato(
              fontSize: 8, fontWeight: FontWeight.w700,
              color: kBreakText, letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _entryCell(Map<String, dynamic> entry, double w) {
    final isLab     = entry['session_type'] == 'LAB';
    final isProject = entry['session_type'] == 'PROJECT';

    final bg     = isLab ? kLabBg     : isProject ? kProjectBg     : kLectureBg;
    final bdr    = isLab ? kLabBorder : isProject ? kProjectBorder : kLectureBorder;
    final txtCol = isLab ? kPrimary   : isProject ? kProjectText   : kLectureText;
    final labBatch = entry['lab_batch'] as String?;

    return Container(
      width: w, height: kRowH,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: const BorderSide(color: kBorder),
          left: BorderSide(color: bdr, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Expanded(
              child: Text(entry['course_code'] ?? '',
                style: GoogleFonts.lato(
                    fontSize: 12, fontWeight: FontWeight.w800, color: txtCol),
                overflow: TextOverflow.ellipsis),
            ),
            if (labBatch != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: kPrimary, borderRadius: BorderRadius.circular(4)),
                child: Text(labBatch,
                  style: GoogleFonts.lato(
                      fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
          ]),
          const SizedBox(height: 2),
          Text(entry['course_name'] ?? '',
            style: GoogleFonts.lato(fontSize: 10, color: kTextLight, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.room_outlined, size: 10, color: kTextFaint),
            const SizedBox(width: 2),
            Text(entry['room_number'] ?? '',
                style: GoogleFonts.lato(fontSize: 10, color: kTextFaint)),
            const SizedBox(width: 6),
            const Icon(Icons.person_outline, size: 10, color: kTextFaint),
            const SizedBox(width: 2),
            Expanded(
              child: Text(entry['faculty_id'] ?? '',
                  style: GoogleFonts.lato(fontSize: 10, color: kTextFaint),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _multiCell(List<Map<String, dynamic>> entries, double w) {
    final partW = w / entries.length;
    return Row(children: entries.map((e) => _entryCell(e, partW)).toList());
  }
}