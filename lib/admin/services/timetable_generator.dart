// timetable_generator.dart
import 'package:attendance_tracker/admin/models/time_models.dart';

/// All fixed time slots including breaks
const List<TimeSlot> kTimeSlots = [
  TimeSlot(label: '9:30–10:30', start: '9:30', end: '10:30'),
  TimeSlot(label: '10:30–11:30', start: '10:30', end: '11:30'),
  TimeSlot(label: '11:30–12:30', start: '11:30', end: '12:30'),
  TimeSlot(label: 'Lunch Break', start: '12:30', end: '1:15', isBreak: true),
  TimeSlot(label: '1:15–2:15', start: '1:15', end: '2:15'),
  TimeSlot(label: '2:15–3:15', start: '2:15', end: '3:15'),
  TimeSlot(label: 'Tea Break', start: '3:15', end: '3:30', isBreak: true),
  TimeSlot(label: '3:30–4:30', start: '3:30', end: '4:30'),
  TimeSlot(label: '4:30–5:30', start: '4:30', end: '5:30'),
];

const List<String> kDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
];

// Valid theory slots (non-break indices)
const List<int> kTheorySlots = [0, 1, 2, 4, 5, 7, 8];

// Lab starts: needs 2 consecutive non-break slots
// Valid pairs: (0,1), (1,2), (4,5), (7,8)
const List<int> kLabStartSlots = [0, 1, 4, 7];

// ─── Semester Data ───────────────────────────────────────────────────────────

/// SEM 2 – FYCO
final List<Subject> sem2Subjects = [
  Subject(code: 'PHY', name: 'Physics', facultyCode: 'VJK', facultyName: 'V.J. Kulkarni', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'CHEM', name: 'Chemistry', facultyCode: 'ARP', facultyName: 'A.R. Patil', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'MATHS', name: 'Mathematics-II', facultyCode: 'SM', facultyName: 'S. Mehta', type: 'theory', roomType: 'classroom', weeklyHours: 4),
  Subject(code: 'CS', name: 'Computer Science', facultyCode: 'DM', facultyName: 'D. More', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'ENG', name: 'Engineering Graphics', facultyCode: 'RK', facultyName: 'R. Kumar', type: 'theory', roomType: 'classroom', weeklyHours: 2),
  Subject(code: 'WD', name: 'Web Design Lab', facultyCode: 'NP', facultyName: 'N. Pawar', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
  Subject(code: 'PHY-P', name: 'Physics Practical', facultyCode: 'VJK', facultyName: 'V.J. Kulkarni', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
  Subject(code: 'CHEM-P', name: 'Chemistry Practical', facultyCode: 'ARP', facultyName: 'A.R. Patil', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
];

/// SEM 4 – SYCO
final List<Subject> sem4Subjects = [
  Subject(code: 'DS', name: 'Data Structures', facultyCode: 'PR', facultyName: 'P. Rao', type: 'theory', roomType: 'classroom', weeklyHours: 4),
  Subject(code: 'OS', name: 'Operating Systems', facultyCode: 'SK', facultyName: 'S. Khan', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'DBMS', name: 'Database Management', facultyCode: 'MG', facultyName: 'M. Gupta', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'CN', name: 'Computer Networks', facultyCode: 'HV', facultyName: 'H. Verma', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'SE', name: 'Software Engineering', facultyCode: 'BP', facultyName: 'B. Patel', type: 'theory', roomType: 'classroom', weeklyHours: 2),
  Subject(code: 'DS-L', name: 'DS Lab', facultyCode: 'PR', facultyName: 'P. Rao', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
  Subject(code: 'DBMS-L', name: 'DBMS Lab', facultyCode: 'MG', facultyName: 'M. Gupta', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
  Subject(code: 'CN-L', name: 'Networks Lab', facultyCode: 'HV', facultyName: 'H. Verma', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
];

/// SEM 6 – TYCO
final List<Subject> sem6Subjects = [
  Subject(code: 'ML', name: 'Machine Learning', facultyCode: 'AS', facultyName: 'A. Sharma', type: 'theory', roomType: 'classroom', weeklyHours: 4),
  Subject(code: 'CC', name: 'Cloud Computing', facultyCode: 'VR', facultyName: 'V. Reddy', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'IS', name: 'Information Security', facultyCode: 'TN', facultyName: 'T. Nair', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'AI', name: 'Artificial Intelligence', facultyCode: 'DK', facultyName: 'D. Kapoor', type: 'theory', roomType: 'classroom', weeklyHours: 3),
  Subject(code: 'PPL', name: 'Programming Paradigms', facultyCode: 'RM', facultyName: 'R. Mishra', type: 'theory', roomType: 'classroom', weeklyHours: 2),
  Subject(code: 'ML-L', name: 'ML Lab', facultyCode: 'AS', facultyName: 'A. Sharma', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
  Subject(code: 'CC-L', name: 'Cloud Lab', facultyCode: 'VR', facultyName: 'V. Reddy', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
  Subject(code: 'IS-L', name: 'Security Lab', facultyCode: 'TN', facultyName: 'T. Nair', type: 'lab', roomType: 'lab', weeklyHours: 2, divisions: ['C1', 'C2', 'C3']),
];

// ─── Rooms ────────────────────────────────────────────────────────────────────
final List<Map<String, String>> kClassrooms = [
  {'id': 'Room 07', 'type': 'classroom'},
  {'id': 'Room 08', 'type': 'classroom'},
  {'id': 'Room 09', 'type': 'classroom'},
  {'id': 'Room 10', 'type': 'classroom'},
  {'id': 'Room 11', 'type': 'classroom'},
];

final List<Map<String, String>> kLabRooms = [
  {'id': 'Lab 101', 'type': 'lab'},
  {'id': 'Lab 102', 'type': 'lab'},
  {'id': 'Lab 103', 'type': 'lab'},
  {'id': 'Lab 104', 'type': 'lab'},
];

// ─── Generator ───────────────────────────────────────────────────────────────
class TimetableGenerator {
  /// [daySchedule] maps dayIndex -> slotIndex -> list of entries
  /// [facultyBusy] maps facultyCode -> dayIndex -> Set of occupied slotIndices
  /// [roomBusy]    maps roomId      -> dayIndex -> Set of occupied slotIndices

  static List<GeneratedTimetable> generateAll() {
    return [
      _generate('Semester 2 (FYCO)', 'sem2', sem2Subjects),
      _generate('Semester 4 (SYCO)', 'sem4', sem4Subjects),
      _generate('Semester 6 (TYCO)', 'sem6', sem6Subjects),
    ];
  }

  static GeneratedTimetable _generate(String label, String code, List<Subject> subjects) {
    // day -> slot -> entries
    final Map<int, Map<int, List<ScheduledEntry>>> schedule = {};
    // faculty -> day -> occupied slots
    final Map<String, Map<int, Set<int>>> facultyBusy = {};
    // room -> day -> occupied slots
    final Map<String, Map<int, Set<int>>> roomBusy = {};

    for (int d = 0; d < kDays.length; d++) {
      schedule[d] = {};
      for (int s = 0; s < kTimeSlots.length; s++) {
        schedule[d]![s] = [];
      }
    }

    // Separate theory and lab subjects
    final theorySubjects = subjects.where((s) => s.type == 'theory').toList();
    final labSubjects = subjects.where((s) => s.type == 'lab').toList();

    // Helper: mark busy
    void markFacultyBusy(String fc, int day, List<int> slots) {
      facultyBusy.putIfAbsent(fc, () => {});
      facultyBusy[fc]!.putIfAbsent(day, () => {});
      facultyBusy[fc]![day]!.addAll(slots);
    }

    void markRoomBusy(String room, int day, List<int> slots) {
      roomBusy.putIfAbsent(room, () => {});
      roomBusy[room]!.putIfAbsent(day, () => {});
      roomBusy[room]![day]!.addAll(slots);
    }

    bool isFacultyFree(String fc, int day, List<int> slots) {
      final occupied = facultyBusy[fc]?[day] ?? {};
      return slots.every((s) => !occupied.contains(s));
    }

    bool isRoomFree(String roomId, int day, List<int> slots) {
      final occupied = roomBusy[roomId]?[day] ?? {};
      return slots.every((s) => !occupied.contains(s));
    }

    String? findFreeRoom(String type, int day, List<int> slots) {
      final rooms = type == 'lab' ? kLabRooms : kClassrooms;
      for (final r in rooms) {
        if (isRoomFree(r['id']!, day, slots)) return r['id'];
      }
      return null;
    }

    // ── Schedule theory subjects ──────────────────────────────────────────────
    // Each theory subject needs `weeklyHours` slots spread across the week
    for (final sub in theorySubjects) {
      int placed = 0;
      // Shuffle days and slots for variety using a deterministic seed based on subject
      final seed = sub.code.codeUnits.fold(0, (a, b) => a + b);
      final dayOrder = List.generate(kDays.length, (i) => i);
      dayOrder.sort((a, b) => ((a * 17 + seed) % kDays.length) - ((b * 17 + seed) % kDays.length));

      for (int attempt = 0; placed < sub.weeklyHours && attempt < 200; attempt++) {
        final d = dayOrder[attempt % kDays.length];
        final slotList = [...kTheorySlots];
        slotList.sort((a, b) => ((a * 13 + attempt + seed) % 7) - ((b * 13 + attempt + seed) % 7));

        for (final slot in slotList) {
          if (!isFacultyFree(sub.facultyCode, d, [slot])) continue;
          final room = findFreeRoom('classroom', d, [slot]);
          if (room == null) continue;
          // Check no duplicate subject on same day
          final dayEntries = schedule[d]!.values.expand((e) => e).toList();
          if (dayEntries.any((e) => e.subjectCode == sub.code)) continue;

          final entry = ScheduledEntry(
            subjectCode: sub.code,
            subjectName: sub.name,
            facultyCode: '${sub.facultyCode}',
            room: room,
            type: 'theory',
            startSlot: slot,
            endSlot: slot + 1,
          );
          schedule[d]![slot]!.add(entry);
          markFacultyBusy(sub.facultyCode, d, [slot]);
          markRoomBusy(room, d, [slot]);
          placed++;
          break;
        }
      }
    }

    // ── Schedule lab subjects (3 divisions, each 2 consecutive slots) ─────────
    // Each lab subject has 3 divisions. We schedule each division on a different day.
    for (final sub in labSubjects) {
      final divisions = sub.divisions ?? ['C1', 'C2', 'C3'];
      final seed = sub.code.codeUnits.fold(0, (a, b) => a + b);
      final dayOrder = List.generate(kDays.length, (i) => i);
      // Try to spread divisions across different days
      int divIdx = 0;
      final usedDays = <int>{};

      for (int attempt = 0; divIdx < divisions.length && attempt < 300; attempt++) {
        final d = dayOrder[(attempt + seed) % kDays.length];
        if (usedDays.contains(d) && usedDays.length < kDays.length) continue;

        final slotOrder = [...kLabStartSlots];
        slotOrder.sort((a, b) => ((a * 11 + attempt + seed) % kLabStartSlots.length) - ((b * 11 + attempt + seed) % kLabStartSlots.length));

        for (final startSlot in slotOrder) {
          final slots = [startSlot, startSlot + 1];
          final div = divisions[divIdx];
          // Unique faculty key per division
          final fcKey = '${sub.facultyCode}-$div';
          if (!isFacultyFree(sub.facultyCode, d, slots)) continue;
          final room = findFreeRoom('lab', d, slots);
          if (room == null) continue;

          // Schedule for this division
          final entry = ScheduledEntry(
            subjectCode: sub.code,
            subjectName: sub.name,
            facultyCode: sub.facultyCode,
            room: room,
            type: 'lab',
            division: div,
            startSlot: startSlot,
            endSlot: startSlot + 2,
          );
          // Add to startSlot and mark endSlot as spanned (don't double-add)
          schedule[d]![startSlot]!.add(entry);
          markFacultyBusy(sub.facultyCode, d, slots);
          markRoomBusy(room, d, slots);
          usedDays.add(d);
          divIdx++;
          break;
        }
      }
    }

    // Build DaySchedule list
    final daySchedules = List.generate(kDays.length, (d) {
      return DaySchedule(day: kDays[d], entries: schedule[d]!);
    });

    return GeneratedTimetable(
      semesterLabel: label,
      semesterCode: code,
      days: daySchedules,
    );
  }
}