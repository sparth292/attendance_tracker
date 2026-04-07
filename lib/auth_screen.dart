import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student/main_screen.dart';
import 'faculty/faculty_home_screen.dart';
import 'admin/admin_screen.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isFacultyLogin = false;

  Map<String, dynamic> facultyData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('📂 [DATA] Loading faculty data...');
    try {
      // Load faculty data only (students will use API)
      final facultyJson = await rootBundle.loadString(
        'assets/json/faculty.json',
      );
      final facultyMap = json.decode(facultyJson);
      print('✅ [DATA] Faculty data loaded successfully');
      print('📊 [DATA] Faculty entries: ${facultyMap.keys.length}');

      setState(() {
        facultyData = facultyMap;
      });

      // Check login status after data is loaded
      print('🔄 [DATA] Checking login status after data load...');
      _checkLoginStatus();
    } catch (e) {
      print('❌ [DATA] Error loading data: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    print('🔍 [SESSION] Checking login status...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userType = prefs.getString('userType') ?? '';
      final userId = prefs.getString('userId') ?? '';

      print(
        '📋 [SESSION] isLoggedIn: $isLoggedIn, userType: $userType, userId: $userId',
      );

      if (isLoggedIn && userId.isNotEmpty) {
        print('✅ [SESSION] User session found, restoring...');
        // Load user data
        Map<String, dynamic>? userData;
        if (userType == 'student') {
          print('🎓 [SESSION] Restoring student session...');
          // Debug: Print all stored preferences
          print('🔍 [SESSION] All stored keys: ${prefs.getKeys()}');
          print(
            '📋 [SESSION] Student ID from prefs: ${prefs.getString('studentId')}',
          );
          print(
            '📋 [SESSION] Student name from prefs: ${prefs.getString('studentName')}',
          );
          print(
            '📋 [SESSION] User ID from prefs: ${prefs.getString('userId')}',
          );

          // For students, restore all data from SharedPreferences
          userData = {
            'id': userId,
            'name': prefs.getString('studentName') ?? 'Student',
            'email': prefs.getString('studentEmail') ?? 'student@somaiya.edu',
            'phone': prefs.getString('studentPhone') ?? '',
            'address': prefs.getString('studentAddress') ?? '',
            'department': prefs.getString('studentDepartment') ?? '',
            'year': prefs.getString('studentYear') ?? '',
            'roll_number': prefs.getString('studentRollNumber') ?? '',
            'student_id': prefs.getString('studentId') ?? '',
            'sgpa': prefs.getString('studentSgpa') ?? '',
            'lab_batch': prefs.getString('studentLabBatch') ?? '',
            'date_of_birth': prefs.getString('studentDateOfBirth') ?? '',
            'userType': 'student',
          };
          print('📊 [SESSION] Complete student data restored: $userData');
        } else if (userType == 'faculty') {
          print('👨‍🏫 [SESSION] Restoring faculty session...');
          // Debug: Print all stored preferences
          print('🔍 [SESSION] All stored keys: ${prefs.getKeys()}');
          print(
            '📋 [SESSION] Faculty ID from prefs: ${prefs.getString('facultyId')}',
          );
          print(
            '📋 [SESSION] Faculty name from prefs: ${prefs.getString('facultyName')}',
          );
          print(
            '📋 [SESSION] User ID from prefs: ${prefs.getString('userId')}',
          );

          // Restore faculty data from SharedPreferences
          userData = {
            'id': userId,
            'faculty_id': prefs.getString('facultyId') ?? userId,
            'name': prefs.getString('facultyName') ?? 'Faculty',
            'email': prefs.getString('facultyEmail') ?? 'faculty@somaiya.edu',
            'department': prefs.getString('facultyDepartment') ?? 'N/A',
            'designation': prefs.getString('facultyDesignation') ?? 'N/A',
            'userType': 'faculty',
          };
          print('📊 [SESSION] Faculty data restored: $userData');
        } else if (userType == 'admin' && userId == 'kjspadmin') {
          print('👑 [SESSION] Restoring admin session...');
          // Handle admin session persistence
          userData = {
            'name': prefs.getString('adminName') ?? 'Admin User',
            'email': prefs.getString('adminEmail') ?? 'admin@somaiya.edu',
            'userType': 'admin',
            'id': 'kjspadmin',
          };
          print('📊 [SESSION] Admin data restored: $userData');
        }

        if (userData != null) {
          print(
            '🚀 [SESSION] Navigating to appropriate screen for $userType...',
          );

          // Initialize FCM for session restoration
          print('🔔 [SESSION] Initializing FCM for restored session...');
          await FCMService().init();

          if (userType == 'faculty') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FacultyHomeScreen()),
            );
            print('👨‍🏫 [SESSION] Navigated to FacultyHomeScreen');
          } else if (userType == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            );
            print('👑 [SESSION] Navigated to AdminScreen');
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
            print('🎓 [SESSION] Navigated to MainScreen');
          }
        } else {
          print('❌ [SESSION] No user data found for session restoration');
        }
      } else {
        print('ℹ️ [SESSION] No active session found');
      }
    } catch (e) {
      print('❌ [SESSION] Error checking login status: $e');
    }
  }

  Future<void> _login() async {
    print('🔐 [LOGIN] Starting login process...');
    print('📋 [LOGIN] Faculty login: $_isFacultyLogin');
    print('📋 [LOGIN] User ID: ${_idController.text.trim()}');

    setState(() => _isLoading = true);

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    bool isAuthenticated = false;
    Map<String, dynamic>? userData;

    if (_isFacultyLogin) {
      print('👨‍🏫 [LOGIN] Attempting faculty authentication via API...');
      // Faculty authentication using API
      try {
        print('📡 [API] Calling faculty login API for faculty ID: $id');
        userData = await ApiService.facultyLogin(id, password);
        isAuthenticated = true;
        print('✅ [API] Faculty authentication successful');
        print('📊 [API] Faculty response data: $userData');

        // Initialize FCM and send token to backend after successful faculty login
        print('🔔 [LOGIN] Initializing FCM for faculty...');
        await FCMService().init();
      } catch (e) {
        isAuthenticated = false;
        print('❌ [API] Faculty authentication failed: $e');
      }
    } else if (id == "kjspadmin" && password == "kjsp123") {
      print('👑 [LOGIN] Attempting admin authentication...');
      // Admin authentication
      isAuthenticated = true;
      userData = {
        'name': 'Admin User',
        'email': 'admin@somaiya.edu',
        'userType': 'admin',
        'id': 'kjspadmin',
      };
      print('✅ [LOGIN] Admin credentials verified, showing PIN dialog...');

      // Show PIN verification popup
      print('🔐 [PIN] Showing PIN verification dialog...');
      final pinVerified = await _showPinVerificationDialog();
      if (!pinVerified) {
        isAuthenticated = false;
        userData = null;
        print('❌ [LOGIN] Admin PIN verification failed');
      } else {
        print('✅ [LOGIN] Admin PIN verification successful');
        // Save admin data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('adminName', userData['name']);
        await prefs.setString('adminEmail', userData['email']);
        print('💾 [STORAGE] Admin data saved to SharedPreferences');

        // Initialize FCM for admin (optional - if admins need notifications)
        print('🔔 [LOGIN] Initializing FCM for admin...');
        await FCMService().init();
      }
    } else {
      print('🎓 [LOGIN] Attempting student authentication via API...');
      // Student authentication using API
      try {
        print('📡 [API] Calling login API for roll number: $id');
        userData = await ApiService.login(id, password);
        isAuthenticated = true;
        print('✅ [API] Student authentication successful');
        print('📊 [API] Complete response data: $userData');
        print('🔑 [API] Available response keys: ${userData.keys.toList()}');
        print('🎓 [API] Login ID used: $id');

        // Initialize FCM and send token to backend after successful student login
        print('🔔 [LOGIN] Initializing FCM for student...');
        await FCMService().init();
      } catch (e) {
        isAuthenticated = false;
        print('❌ [API] Student authentication failed: $e');
      }
    }

    setState(() => _isLoading = false);

    if (isAuthenticated && userData != null) {
      print('💾 [STORAGE] Saving login state to SharedPreferences...');
      // Save login state to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
        'userType',
        userData['userType'] ?? (_isFacultyLogin ? 'faculty' : 'student'),
      );
      await prefs.setString('userId', id);
      print(
        '💾 [STORAGE] Saved user type: ${userData['userType'] ?? (_isFacultyLogin ? 'faculty' : 'student')}',
      );

      // Save student data for persistence
      if (!_isFacultyLogin && userData['userType'] != 'admin') {
        await prefs.setString('studentName', userData['name'] ?? 'Student');
        await prefs.setString(
          'studentEmail',
          userData['email'] ?? 'student@somaiya.edu',
        );

        print('🔍 [AUTH] Saving student data to SharedPreferences...');
        await prefs.setString('studentPhone', userData['phone'] ?? '');
        print('💾 [AUTH] Saved studentPhone: ${userData['phone']}');

        await prefs.setString('studentAddress', userData['address'] ?? '');
        print('💾 [AUTH] Saved studentAddress: ${userData['address']}');

        await prefs.setString(
          'studentDepartment',
          userData['department'] ?? '',
        );
        print('💾 [AUTH] Saved studentDepartment: ${userData['department']}');

        await prefs.setString('studentYear', userData['year'] ?? '');
        print('💾 [AUTH] Saved studentYear: ${userData['year']}');

        await prefs.setString(
          'studentRollNumber',
          userData['roll_number'] ?? '',
        );
        print('💾 [AUTH] Saved studentRollNumber: ${userData['roll_number']}');

        await prefs.setString('studentId', userData['student_id'] ?? '');
        print('💾 [AUTH] Saved studentId: ${userData['student_id']}');

        await prefs.setString(
          'studentSgpa',
          userData['sgpa']?.toString() ?? '',
        );
        print('💾 [AUTH] Saved studentSgpa: ${userData['sgpa']}');

        await prefs.setString('studentLabBatch', userData['lab_batch'] ?? '');
        print('💾 [AUTH] Saved studentLabBatch: ${userData['lab_batch']}');

        await prefs.setString(
          'studentDateOfBirth',
          userData['date_of_birth'] ?? '',
        );
        print(
          '💾 [AUTH] Saved studentDateOfBirth: ${userData['date_of_birth']}',
        );

        print('✅ [AUTH] All student data saved successfully!');

        // Debug: Print entire API response
        print('📊 [API] Complete API response: $userData');
        print('🔑 [API] Available keys in response: ${userData.keys.toList()}');

        // IMPORTANT: Use roll_number as primary identifier throughout the app
        // roll_number (FCUG23762) is used for both login and attendance
        final attendanceId = id; // Use the login ID (roll_number)

        // Save roll_number to both keys for consistency
        await prefs.setString('userId', attendanceId);
        await prefs.setString('rollNumber', attendanceId); // Primary identifier
        print(
          '💾 [STORAGE] Using roll_number for all operations: $attendanceId',
        );
        print('💾 [STORAGE] Saved userId: $attendanceId');
        print('💾 [STORAGE] Saved rollNumber: $attendanceId');
        print('💾 [STORAGE] Login ID: $id');
        print(
          '💾 [STORAGE] API student_id: ${userData['student_id'] ?? 'NOT_FOUND'}',
        );

        print('💾 [STORAGE] Saved complete student data for persistence');
        print('💾 [STORAGE] Student Name: ${userData['name']}');
        print('💾 [STORAGE] Student Email: ${userData['email']}');
        print('💾 [STORAGE] Student Department: ${userData['department']}');
        print('💾 [STORAGE] Student Roll Number: ${userData['roll_number']}');
      }

      // Save faculty data for persistence
      if (_isFacultyLogin) {
        await prefs.setString('facultyName', userData['name'] ?? 'Faculty');
        await prefs.setString(
          'facultyEmail',
          userData['email'] ?? 'faculty@somaiya.edu',
        );
        await prefs.setString(
          'facultyDepartment',
          userData['department'] ?? 'N/A',
        );
        await prefs.setString(
          'facultyDesignation',
          userData['designation'] ?? 'N/A',
        );
        await prefs.setString(
          'facultyId',
          userData['faculty_id'] ?? userData['id'] ?? id,
        );
        await prefs.setString(
          'facultyPhone',
          userData['phone'] ?? userData['contact'] ?? '+91 98765 40001',
        );

        print('💾 [STORAGE] Faculty data saved:');
        print('💾 [STORAGE] Name: ${userData['name']}');
        print('💾 [STORAGE] Email: ${userData['email']}');
        print('💾 [STORAGE] Department: ${userData['department']}');
        print('💾 [STORAGE] Designation: ${userData['designation']}');
        print(
          '💾 [STORAGE] Phone: ${userData['phone'] ?? userData['contact'] ?? 'Not found in response'}',
        );
        print(
          '💾 [STORAGE] Faculty ID: ${userData['faculty_id'] ?? userData['id']}',
        );
        print('💾 [STORAGE] All userData keys: ${userData.keys}');
      }

      print('🚀 [NAVIGATION] Navigating to appropriate screen...');
      if (_isFacultyLogin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyHomeScreen(facultyData: userData),
          ),
        );
        print('👨‍🏫 [NAVIGATION] Navigated to FacultyHomeScreen');
      } else if (userData['userType'] == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
        print('👑 [NAVIGATION] Navigated to AdminScreen');
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        print('🎓 [NAVIGATION] Navigated to MainScreen');
      }
    } else {
      print('❌ [LOGIN] Authentication failed, showing error message...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFacultyLogin
                ? "Invalid faculty credentials."
                : "Invalid student credentials.",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFA50C22),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<bool> _showPinVerificationDialog() async {
    final TextEditingController pinController = TextEditingController();
    bool pinVerified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Admin PIN Verification',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter admin PIN to continue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFA50C22)),
                  ),
                  counterText: '',
                ),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (pinController.text == "2008") {
                  pinVerified = true;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid PIN', style: GoogleFonts.inter()),
                      backgroundColor: const Color(0xFFA50C22),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA50C22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Verify',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    return pinVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // Logo and Header
              Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/somaiyalogo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isFacultyLogin ? "Faculty Login" : "Welcome Back",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA50C22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFacultyLogin
                        ? "Sign in to access faculty portal"
                        : "Sign in to continue to your account",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Login Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username Field
                    Text(
                      _isFacultyLogin
                          ? "Faculty ID"
                          : "Student ID or Enrollment No",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        hintText: _isFacultyLogin
                            ? "Enter your faculty ID"
                            : "Enter your student ID or enrollment number",
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFFA50C22),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA50C22),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    Text(
                      "Password",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFFA50C22),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF9CA3AF),
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA50C22),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA50C22),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "Sign In",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Footer
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Biometric Login Option
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isFacultyLogin = !_isFacultyLogin;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isFacultyLogin
                                ? Icons.person_outline
                                : Icons.school_outlined,
                            color: const Color(0xFFA50C22),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isFacultyLogin
                                ? "Login as Student"
                                : "Login as Faculty",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
