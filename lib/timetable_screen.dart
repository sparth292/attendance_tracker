import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Screen'),
        backgroundColor: const Color(0xFFA50C22),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  const Text(
                    'Computer Engineering Department',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'K.J. Somaiya Polytechnic, Mumbai',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Term-EVEN (Dec 2025 - April 2026), Sem-VI',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Timetable Table
            _buildTimetableTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      columnWidths: {
        0: const FixedColumnWidth(80.0),  // Time column
        1: const FlexColumnWidth(1.0),    // Monday
        2: const FlexColumnWidth(1.0),    // Tuesday
        3: const FlexColumnWidth(1.0),    // Wednesday
        4: const FlexColumnWidth(1.0),    // Thursday
        5: const FlexColumnWidth(1.0),    // Friday
        6: const FlexColumnWidth(1.0),    // Saturday
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
          ),
          children: [
            _buildHeaderCell('Time'),
            _buildHeaderCell('MON'),
            _buildHeaderCell('TUE'),
            _buildHeaderCell('WED'),
            _buildHeaderCell('THU'),
            _buildHeaderCell('FRI'),
            _buildHeaderCell('SAT'),
          ],
        ),
        
        // 9:30 To 10:30
        TableRow(
          children: [
            _buildTimeCell('9:30 To 10:30'),
            _buildSubjectCell('IP', 'F1', '207', 'MON', '9:30 To 10:30'),
            _buildSubjectCell('DBMS', 'F2', '210', 'TUE', '9:30 To 10:30'),
            _buildSubjectCell('IP', 'F1', '207', 'WED', '9:30 To 10:30'),
            _buildSubjectCell('DBMS', 'F2', '210', 'THU', '9:30 To 10:30'),
            _buildSubjectCell('IP', 'F1', '207', 'FRI', '9:30 To 10:30'),
            _buildSubjectCell('DBMS', 'F2', '210', 'SAT', '9:30 To 10:30'),
          ],
        ),
        
        // 10:30 To 11:30
        TableRow(
          children: [
            _buildTimeCell('10:30 To 11:30'),
            _buildSubjectCell('IP', 'F1', '207', 'MON', '10:30 To 11:30'),
            _buildSubjectCell('IP', 'F1', '207', 'TUE', '10:30 To 11:30'),
            _buildSubjectCell('DBMS', 'F2', '210', 'WED', '10:30 To 11:30'),
            _buildSubjectCell('DBMS', 'F2', '210', 'THU', '10:30 To 11:30'),
            _buildSubjectCell('DBMS', 'F2', '210', 'FRI', '10:30 To 11:30'),
            _buildSubjectCell('IP', 'F1', '207', 'SAT', '10:30 To 11:30'),
          ],
        ),
        
        // 11:30 To 12:30
        TableRow(
          children: [
            _buildTimeCell('11:30 To 12:30'),
            _buildSubjectCell('MPSP', 'F3', '209', 'MON', '11:30 To 12:30'),
            _buildSubjectCell('MPSP', 'F3', '209', 'TUE', '11:30 To 12:30'),
            _buildSubjectCell('MPSP', 'F3', '209', 'WED', '11:30 To 12:30'),
            _buildSubjectCell('MPSP', 'F3', '209', 'THU', '11:30 To 12:30'),
            _buildSubjectCell('MPSP', 'F3', '209', 'FRI', '11:30 To 12:30'),
            _buildSubjectCell('MPSP', 'F3', '209', 'SAT', '11:30 To 12:30'),
          ],
        ),
        
        // LUNCH BREAK
        TableRow(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
          ),
          children: [
            _buildTimeCell('12:30 To 1:15'),
            _buildBreakCell('LUNCH BREAK', 6),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
          ],
        ),
        
        // 1:15 To 2:15
        TableRow(
          children: [
            _buildTimeCell('1:15 To 2:15'),
            _buildSubjectCell('WAD', 'F4', '208', 'MON', '1:15 To 2:15'),
            _buildSubjectCell('WAD', 'F4', '208', 'TUE', '1:15 To 2:15'),
            _buildSubjectCell('WAD', 'F4', '208', 'WED', '1:15 To 2:15'),
            _buildSubjectCell('WAD', 'F4', '208', 'THU', '1:15 To 2:15'),
            _buildSubjectCell('WAD', 'F4', '208', 'FRI', '1:15 To 2:15'),
            _buildSubjectCell('WAD', 'F4', '208', 'SAT', '1:15 To 2:15'),
          ],
        ),
        
        // 2:15 To 3:15
        TableRow(
          children: [
            _buildTimeCell('2:15 To 3:15'),
            _buildSubjectCell('DSGT', 'F5', '211', 'MON', '2:15 To 3:15'),
            _buildSubjectCell('DSGT', 'F5', '211', 'TUE', '2:15 To 3:15'),
            _buildSubjectCell('DSGT', 'F5', '211', 'WED', '2:15 To 3:15'),
            _buildSubjectCell('DSGT', 'F5', '211', 'THU', '2:15 To 3:15'),
            _buildSubjectCell('DSGT', 'F5', '211', 'FRI', '2:15 To 3:15'),
            _buildSubjectCell('DSGT', 'F5', '211', 'SAT', '2:15 To 3:15'),
          ],
        ),
        
        // TEA BREAK
        TableRow(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
          ),
          children: [
            _buildTimeCell('3:15 To 3:30'),
            _buildBreakCell('TEA BREAK', 6),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
          ],
        ),
        
        // 3:30 To 4:30
        TableRow(
          children: [
            _buildTimeCell('3:30 To 4:30'),
            _buildSubjectCell('MPSP Lab', 'F3', 'Lab 1', 'MON', '3:30 To 4:30'),
            _buildSubjectCell('WAD Lab', 'F4', 'Lab 2', 'TUE', '3:30 To 4:30'),
            _buildSubjectCell('MPSP Lab', 'F3', 'Lab 1', 'WED', '3:30 To 4:30'),
            _buildSubjectCell('WAD Lab', 'F4', 'Lab 2', 'THU', '3:30 To 4:30'),
            _buildSubjectCell('Project', 'All', 'Lab 3', 'FRI', '3:30 To 4:30'),
            _buildSubjectCell('Project', 'All', 'Lab 3', 'SAT', '3:30 To 4:30'),
          ],
        ),
        
        // 4:30 To 5:30
        TableRow(
          children: [
            _buildTimeCell('4:30 To 5:30'),
            _buildSubjectCell('MPSP Lab', 'F3', 'Lab 1', 'MON', '4:30 To 5:30'),
            _buildSubjectCell('WAD Lab', 'F4', 'Lab 2', 'TUE', '4:30 To 5:30'),
            _buildSubjectCell('MPSP Lab', 'F3', 'Lab 1', 'WED', '4:30 To 5:30'),
            _buildSubjectCell('WAD Lab', 'F4', 'Lab 2', 'THU', '4:30 To 5:30'),
            _buildSubjectCell('Project', 'All', 'Lab 3', 'FRI', '4:30 To 5:30'),
            _buildSubjectCell('Project', 'All', 'Lab 3', 'SAT', '4:30 To 5:30'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTimeCell(String time) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSubjectCell(String subject, String faculty, String room, String day, String timeSlot) {
    bool isMonday930IP = (day == 'MON' && timeSlot == '9:30 To 10:30' && subject == 'IP');
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isMonday930IP 
                ? Colors.red.withOpacity(0.3 + (_animation.value * 0.7))
                : null,
            border: isMonday930IP 
                ? Border.all(color: Colors.red.withOpacity(_animation.value), width: 2)
                : null,
            borderRadius: isMonday930IP ? BorderRadius.circular(8) : null,
          ),
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            subject,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isMonday930IP ? Colors.red.shade800 : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            faculty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            room,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakCell(String breakText, int colspan) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(
          breakText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: breakText == 'LUNCH BREAK' ? Colors.orange[700] : Colors.green[700],
          ),
        ),
      ),
    );
  }
}
