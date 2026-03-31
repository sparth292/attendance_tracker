// timetable_screen.dart
import 'package:attendance_tracker/admin/models/time_models.dart';
import 'package:attendance_tracker/admin/services/timetable_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const kPrimary    = Color(0xFFA50C22);
const kAccent     = Color(0xFFFFB800);
const kBg         = Color(0xFFF4F6F9);
const kBreakBg    = Color(0xFFFFF3CD);
const kBreakFg    = Color(0xFF856404);
const kTheoryBg   = Color(0xFFE8F4FD);
const kTheoryBdr  = Color(0xFF2196F3);
const kLabBdr     = Color(0xFF4CAF50);
const kC1Bg       = Color(0xFFE3F2FD);
const kC2Bg       = Color(0xFFF3E5F5);
const kC2Bdr      = Color(0xFF9C27B0);
const kC3Bg       = Color(0xFFFFF8E1);

// ─── Layout constants ─────────────────────────────────────────────────────────
// Portrait
const double _pDayW   = 72.0;
const double _pSlotW  = 120.0;
const double _pBrkW   = 58.0;
const double _pHdrH   = 48.0;
const double _pRowH   = 100.0;

// Landscape (wider cols, shorter rows)
const double _lDayW   = 80.0;
const double _lSlotW  = 140.0;
const double _lBrkW   = 60.0;
const double _lHdrH   = 44.0;
const double _lRowH   = 88.0;

// ─── Slot indices that are ALWAYS breaks (never receive entries) ──────────────
// kTimeSlots index 3 = Lunch Break (12:30–1:15)
// kTimeSlots index 6 = Tea Break   (3:15–3:30)
const Set<int> kBreakSlotIndices = {3, 6};

// ═══════════════════════════════════════════════════════════════════════════════
// LANDING SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TimetableMakerScreen extends StatefulWidget {
  const TimetableMakerScreen({Key? key}) : super(key: key);
  @override
  State<TimetableMakerScreen> createState() => _TimetableMakerScreenState();
}

class _TimetableMakerScreenState extends State<TimetableMakerScreen> {
  List<GeneratedTimetable>? _timetables;
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 700));
    final result = TimetableGenerator.generateAll();
    if (mounted) setState(() { _timetables = result; _isGenerating = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_timetables != null) {
      return TimetableTabsScreen(timetables: _timetables!);
    }
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text('Timetable Generator',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08), shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withOpacity(0.2), width: 2),
                ),
                child: const Icon(Icons.calendar_month_rounded, size: 60, color: kPrimary),
              ),
              const SizedBox(height: 28),
              Text('Automatic Timetable\nGenerator',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E), height: 1.3)),
              const SizedBox(height: 10),
              Text('Conflict-free schedules for Sem 2 · Sem 4 · Sem 6',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.6)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                children: const [
                  _Chip(icon: Icons.check_circle_outline, label: 'No Faculty Clashes'),
                  _Chip(icon: Icons.check_circle_outline, label: 'Lab Divisions'),
                  _Chip(icon: Icons.check_circle_outline, label: 'Room Allocation'),
                  _Chip(icon: Icons.check_circle_outline, label: 'Break Slots'),
                ],
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    elevation: 4, shadowColor: kPrimary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isGenerating
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_fix_high_rounded, size: 22),
                            const SizedBox(width: 10),
                            Text('Generate Timetables',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: kPrimary), const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TABS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TimetableTabsScreen extends StatefulWidget {
  final List<GeneratedTimetable> timetables;
  const TimetableTabsScreen({Key? key, required this.timetables}) : super(key: key);
  @override
  State<TimetableTabsScreen> createState() => _TimetableTabsScreenState();
}

class _TimetableTabsScreenState extends State<TimetableTabsScreen> {
  bool _landscape = false;

  void _toggleOrientation() {
    setState(() => _landscape = !_landscape);
    if (_landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.timetables.length,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kPrimary, elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
              Navigator.of(context).pop();
            },
          ),
          title: Text('Timetables',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
          actions: [
            Tooltip(
              message: _landscape ? 'Switch to Portrait' : 'Switch to Landscape',
              child: IconButton(
                onPressed: _toggleOrientation,
                icon: Icon(
                  _landscape ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: kAccent, indicatorWeight: 3,
            labelColor: Colors.white, unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13),
            tabs: widget.timetables
                .map((t) => Tab(text: t.semesterLabel.split(' ').take(3).join(' ')))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: widget.timetables
              .map((t) => _TimetablePage(timetable: t, landscape: _landscape))
              .toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TIMETABLE PAGE (one semester)
// ═══════════════════════════════════════════════════════════════════════════════
class _TimetablePage extends StatelessWidget {
  final GeneratedTimetable timetable;
  final bool landscape;
  const _TimetablePage({required this.timetable, required this.landscape});

  // pick dimensions based on orientation
  double get dayW  => landscape ? _lDayW  : _pDayW;
  double get slotW => landscape ? _lSlotW : _pSlotW;
  double get brkW  => landscape ? _lBrkW  : _pBrkW;
  double get hdrH  => landscape ? _lHdrH  : _pHdrH;
  double get rowH  => landscape ? _lRowH  : _pRowH;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // sub-header
        Container(
          color: kPrimary,
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
          child: Row(children: [
            const Icon(Icons.school_rounded, color: Colors.white60, size: 15),
            const SizedBox(width: 6),
            Text(timetable.semesterLabel,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            _dot(kTheoryBdr, 'Theory'), const SizedBox(width: 10),
            _dot(kLabBdr,    'Lab'),
          ]),
        ),

        // scrollable grid
        Expanded(
          child: SingleChildScrollView(             // vertical
            child: SingleChildScrollView(           // horizontal
              scrollDirection: Axis.horizontal,
              child: _buildGrid(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color c, String l) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(l, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
  ]);

  // ── Grid ────────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,   // ← critical: wraps content, no infinite height
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerRow(),
        ...timetable.days.map((ds) => _dayRow(ds)),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _headerRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _hCell('Day / Time', dayW, isCorner: true),
        for (int i = 0; i < kTimeSlots.length; i++)
          _hCell(
            kTimeSlots[i].label,
            kBreakSlotIndices.contains(i) ? brkW : slotW,
            isBreak: kBreakSlotIndices.contains(i),
          ),
      ],
    );
  }

  Widget _hCell(String text, double w, {bool isCorner = false, bool isBreak = false}) {
    return Container(
      width: w, height: hdrH,
      decoration: BoxDecoration(
        color: isCorner ? kPrimary : isBreak ? kBreakBg : kPrimary.withOpacity(0.87),
        border: Border(
          right: BorderSide(color: isBreak ? Colors.grey.shade300 : Colors.white24),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isBreak ? 8 : 10,
            color: isBreak ? kBreakFg : Colors.white,
          )),
    );
  }

  // ── Day row ──────────────────────────────────────────────────────────────────
  Widget _dayRow(DaySchedule ds) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,  // ← start, NOT stretch
        children: [
          // Day label — FIXED size
          Container(
            width: dayW, height: rowH,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            alignment: Alignment.center,
            child: Text(ds.day, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11, color: kPrimary)),
          ),

          // One cell per slot
          for (int si = 0; si < kTimeSlots.length; si++)
            _slotCell(ds, si),
        ],
      ),
    );
  }

  // ── Slot cell ────────────────────────────────────────────────────────────────
  Widget _slotCell(DaySchedule ds, int si) {
    // Always a break column?
    if (kBreakSlotIndices.contains(si)) {
      return _breakCell(kTimeSlots[si].label, brkW);
    }

    final w = slotW;

    // Is this slot visually consumed by a lab starting at si-1?
    if (si > 0 && !kBreakSlotIndices.contains(si - 1)) {
      final prevEntries = ds.entries[si - 1] ?? [];
      final spanned = prevEntries.any((e) => e.type == 'lab' && e.startSlot == si - 1);
      if (spanned) {
        // Hidden — the lab card from previous column uses OverflowBox to cover this space
        return SizedBox(width: w, height: rowH);
      }
    }

    final entries = (ds.entries[si] ?? []).where((e) => e.startSlot == si).toList();

    return Container(
      width: w, height: rowH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: entries.isEmpty
          ? const SizedBox.shrink()
          : entries.length == 1
              ? _card(entries.first, w)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: entries.map((e) => _card(e, w, maxH: rowH / entries.length)).toList(),
                ),
    );
  }

  // ── Break cell ───────────────────────────────────────────────────────────────
  Widget _breakCell(String label, double w) {
    return Container(
      width: w, height: rowH,
      color: kBreakBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(label.contains('Lunch') ? Icons.restaurant_rounded : Icons.coffee_rounded,
              size: 14, color: kBreakFg),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w600, color: kBreakFg)),
        ],
      ),
    );
  }

  // ── Entry card ───────────────────────────────────────────────────────────────
  Widget _card(ScheduledEntry e, double colW, {double? maxH}) {
    final isLab = e.type == 'lab';

    late Color bg, bdr;
    if (!isLab) {
      bg = kTheoryBg; bdr = kTheoryBdr;
    } else if (e.division == 'C1') {
      bg = kC1Bg; bdr = kLabBdr;
    } else if (e.division == 'C2') {
      bg = kC2Bg; bdr = kC2Bdr;
    } else {
      bg = kC3Bg; bdr = kAccent;
    }

    // Lab cards visually span 2 slot-columns using OverflowBox.
    // The NEXT column (si+1) renders a plain SizedBox so there is no double content.
    final cardW = isLab ? slotW * 2 - 8 : colW - 6;
    final cardH = (maxH ?? rowH) - 6;

    final content = Container(
      width: cardW, height: cardH,
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: bdr, width: 3)),
        boxShadow: [BoxShadow(color: bdr.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subject + division badge
          Row(children: [
            Expanded(
              child: Text(e.subjectCode,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11, color: bdr),
                  overflow: TextOverflow.ellipsis),
            ),
            if (e.division != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: bdr, borderRadius: BorderRadius.circular(4)),
                child: Text(e.division!,
                    style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
          ]),
          const SizedBox(height: 2),
          Text('(${e.facultyCode})',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Icon(Icons.room_outlined, size: 9, color: Colors.grey[500]),
            const SizedBox(width: 2),
            Expanded(
              child: Text(e.room,
                  style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          if (isLab) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: bdr.withOpacity(0.14), borderRadius: BorderRadius.circular(3)),
              child: Text('LAB • 2h',
                  style: GoogleFonts.poppins(fontSize: 8, color: bdr, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );

    if (!isLab) {
      // Theory: simple, fits exactly in its cell
      return Padding(padding: const EdgeInsets.all(3), child: content);
    }

    // Lab: use OverflowBox so card bleeds into the visually-hidden next column
    return SizedBox(
      width: colW,
      height: rowH,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: cardW + 6, maxWidth: cardW + 6,
        minHeight: cardH + 6, maxHeight: cardH + 6,
        child: Padding(padding: const EdgeInsets.all(3), child: content),
      ),
    );
  }
}