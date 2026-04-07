import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, String>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Print all available keys in SharedPreferences
      print('🔍 [PROFILE] All SharedPreferences keys: ${prefs.getKeys()}');

      // Debug: Check each individual field before loading
      final studentName = prefs.getString('studentName');
      final studentEmail = prefs.getString('studentEmail');
      final studentPhone = prefs.getString('studentPhone');
      final studentAddress = prefs.getString('studentAddress');
      final studentDepartment = prefs.getString('studentDepartment');
      final studentYear = prefs.getString('studentYear');
      final studentRollNumber = prefs.getString('studentRollNumber');
      final studentId = prefs.getString('studentId');
      final studentSgpa = prefs.getString('studentSgpa');
      final studentLabBatch = prefs.getString('studentLabBatch');
      final studentDateOfBirth = prefs.getString('studentDateOfBirth');

      print('📋 [PROFILE] Raw data from SharedPreferences:');
      print('📋 [PROFILE] studentName: $studentName');
      print('📋 [PROFILE] studentEmail: $studentEmail');
      print('📋 [PROFILE] studentPhone: $studentPhone');
      print('📋 [PROFILE] studentAddress: $studentAddress');
      print('📋 [PROFILE] studentDepartment: $studentDepartment');
      print('📋 [PROFILE] studentYear: $studentYear');
      print('📋 [PROFILE] studentRollNumber: $studentRollNumber');
      print('📋 [PROFILE] studentId: $studentId');
      print('📋 [PROFILE] studentSgpa: $studentSgpa');
      print('📋 [PROFILE] studentLabBatch: $studentLabBatch');
      print('📋 [PROFILE] studentDateOfBirth: $studentDateOfBirth');

      setState(() {
        _studentData = {
          'name': studentName ?? 'Loading...',
          'email': studentEmail ?? 'Loading...',
          'phone': studentPhone ?? 'Loading...',
          'address': studentAddress ?? 'Loading...',
          'department': studentDepartment ?? 'Loading...',
          'year': studentYear ?? 'Loading...',
          'roll_number': studentRollNumber ?? 'Loading...',
          'student_id': studentId ?? 'Loading...',
          'sgpa': studentSgpa ?? 'Loading...',
          'lab_batch': studentLabBatch ?? 'Loading...',
          'date_of_birth': studentDateOfBirth ?? 'Loading...',
        };
      });

      print('📋 [PROFILE] Final _studentData map: $_studentData');
    } catch (e) {
      print('❌ [PROFILE] Error loading student data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA50C22),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/somaiyalogo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _studentData?['name'] ?? "Loading...",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    (_studentData?['email'] as String?)?.split('@')[0] ??
                        "Loading...",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Notification Icon
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "No new notifications",
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: const Color(0xFFA50C22),
                  ),
                );
              },
            ),
            // Somaiya Trust Logo
            Image.asset(
              'assets/images/somaiyatrust.png', // Replace with your Somaiya Trust logo asset path
              height: 30,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // Profile Header Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // Profile Picture
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: const Color(0xFFA50C22),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Color(0xFFA50C22),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name, ID, and Department
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _studentData?['name'] ?? "Loading...",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_studentData?['email'] ?? "Loading..."} | ${_studentData?['department'] ?? "Loading..."}",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Integrated Profile Information Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA50C22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Profile Information",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Personal Information Subsection
                    Text(
                      "Personal Information",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileInfoRow(
                      Icons.email_outlined,
                      "Email",
                      _studentData?['email'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.phone_outlined,
                      "Phone",
                      _studentData?['phone'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.badge_outlined,
                      "Student ID",
                      _studentData?['student_id'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.calendar_today_outlined,
                      "Date of Birth",
                      _studentData?['date_of_birth'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.location_on_outlined,
                      "Address",
                      _studentData?['address'] ?? "Loading...",
                    ),

                    const SizedBox(height: 24),

                    // Academic Information Subsection
                    Text(
                      "Academic Information",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileInfoRow(
                      Icons.school_outlined,
                      "Department",
                      _studentData?['department'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.class_outlined,
                      "Year",
                      _studentData?['year'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.group_outlined,
                      "Lab Batch",
                      _studentData?['lab_batch'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.numbers_outlined,
                      "Roll Number",
                      _studentData?['roll_number'] ?? "Loading...",
                    ),
                    _buildProfileInfoRow(
                      Icons.grade_outlined,
                      "SGPA",
                      _studentData?['sgpa'] ?? "Loading...",
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Divider(color: const Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    _buildActionRow(Icons.logout_outlined, "Logout", () {
                      _showLogoutDialog(context);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFA50C22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFFA50C22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
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

  void _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Logout",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
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
              onPressed: () async {
                Navigator.of(context).pop();

                // Clear shared preferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to auth screen
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA50C22),
              ),
              child: Text(
                "Logout",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
