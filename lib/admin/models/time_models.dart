// timetable_models.dart

class TimeSlot {
  final String label;
  final String start;
  final String end;
  final bool isBreak;

  const TimeSlot({
    required this.label,
    required this.start,
    required this.end,
    this.isBreak = false,
  });
}

class Subject {
  final String code;
  final String name;
  final String facultyCode;
  final String facultyName;
  final String type; // 'theory' or 'lab'
  final String roomType; // 'classroom' or 'lab'
  final int weeklyHours;
  final List<String>? divisions; // for labs: ['C1', 'C2', 'C3']

  const Subject({
    required this.code,
    required this.name,
    required this.facultyCode,
    required this.facultyName,
    required this.type,
    required this.roomType,
    required this.weeklyHours,
    this.divisions,
  });
}

class ScheduledEntry {
  final String subjectCode;
  final String subjectName;
  final String facultyCode;
  final String room;
  final String type;
  final String? division;
  final int startSlot;
  final int endSlot; // exclusive

  const ScheduledEntry({
    required this.subjectCode,
    required this.subjectName,
    required this.facultyCode,
    required this.room,
    required this.type,
    this.division,
    required this.startSlot,
    required this.endSlot,
  });

  int get spanSlots => endSlot - startSlot;
}

class DaySchedule {
  final String day;
  // slotIndex -> list of entries (multiple for split labs)
  final Map<int, List<ScheduledEntry>> entries;

  DaySchedule({required this.day, required this.entries});
}

class GeneratedTimetable {
  final String semesterLabel;
  final String semesterCode;
  final List<DaySchedule> days;

  GeneratedTimetable({
    required this.semesterLabel,
    required this.semesterCode,
    required this.days,
  });
}