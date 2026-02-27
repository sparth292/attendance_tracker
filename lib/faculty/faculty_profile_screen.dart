import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyProfileScreen extends StatelessWidget {
  const FacultyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
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
                            "Manjiri Samant",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "FAC001 | Computer Engineering",
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
                      "manjiris@somaiya.edu",
                    ),
                    _buildProfileInfoRow(
                      Icons.phone_outlined,
                      "Phone",
                      "+91 98765 43210",
                    ),
                    _buildProfileInfoRow(
                      Icons.badge_outlined,
                      "Employee ID",
                      "FAC001",
                    ),
                    _buildProfileInfoRow(
                      Icons.location_on_outlined,
                      "Office",
                      "Room 207, Building A",
                    ),

                    const SizedBox(height: 24),

                    // Professional Information Subsection
                    Text(
                      "Professional Information",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileInfoRow(
                      Icons.work_outlined,
                      "Designation",
                      "Assistant Professor",
                    ),
                    _buildProfileInfoRow(
                      Icons.school_outlined,
                      "Department",
                      "Computer Engineering",
                    ),
                    _buildProfileInfoRow(
                      Icons.calendar_today_outlined,
                      "Experience",
                      "5 Years",
                    ),
                    _buildProfileInfoRow(
                      Icons.book_outlined,
                      "Specialization",
                      "Image Processing",
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Divider(color: const Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    _buildActionRow(Icons.edit_outlined, "Edit Profile", () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Edit profile feature coming soon!",
                            style: GoogleFonts.inter(),
                          ),
                          backgroundColor: const Color(0xFFA50C22),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
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

  void _showLogoutDialog(BuildContext context) {
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
              onPressed: () {
                Navigator.of(context).pop();
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
