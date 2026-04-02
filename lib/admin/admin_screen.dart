import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upload_event_screen.dart';
import 'register_student_screen.dart';
import 'register_faculty_screen.dart';
import 'delete_user_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String adminName = 'Admin User';
  String adminEmail = 'admin@somaiya.edu';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        adminName = prefs.getString('adminName') ?? 'Admin User';
        adminEmail = prefs.getString('adminEmail') ?? 'admin@somaiya.edu';
      });
    } catch (e) {
      print('Error loading admin data: $e');
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userType');
      await prefs.remove('userId');
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', 
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA50C22),
        elevation: 0,
        title: Text(
          'Admin Panel',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Color(0xFFA50C22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Access Granted',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome, $adminName',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              adminEmail,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Admin Functions Grid
            Text(
              'Admin Functions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                // Upload Event/Workshops
                _buildAdminCard(
                  icon: Icons.event,
                  title: 'Upload Events',
                  subtitle: 'workshops & events',
                  color: const Color(0xFFA50C22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UploadEventScreen()),
                    );
                  },
                ),
                
                // Register Student
                _buildAdminCard(
                  icon: Icons.person_add,
                  title: 'Register Student',
                  subtitle: 'Add new student',
                  color: const Color(0xFFA50C22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterStudentScreen()),
                    );
                  },
                ),
                
                // Register Faculty
                _buildAdminCard(
                  icon: Icons.school,
                  title: 'Register Faculty',
                  subtitle: 'Add new faculty',
                  color: const Color(0xFFA50C22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterFacultyScreen()),
                    );
                  },
                ),
                
                // Delete User
                _buildAdminCard(
                  icon: Icons.person_remove,
                  title: 'Delete User',
                  subtitle: 'Remove user',
                  color: const Color(0xFFA50C22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeleteUserScreen()),
                    );
                  },
                ),
                
                // Upload Timetable
                _buildAdminCard(
                  icon: Icons.calendar_month,
                  title: 'Upload Timetable',
                  subtitle: 'Update schedules',
                  color: const Color(0xFFA50C22),
                  onTap: () {
                    // TODO: Navigate to timetable upload
                  },
                ),
                
                // Send Notifications
                _buildAdminCard(
                  icon: Icons.notifications_active,
                  title: 'Notifications',
                  subtitle: 'Results, events',
                  color: const Color(0xFFA50C22),
                  onTap: () {
                    // TODO: Navigate to send notifications
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}