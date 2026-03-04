import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student/main_screen.dart';
import 'faculty/faculty_home_screen.dart';
import 'admin/admin_screen.dart';

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
  
  Map<String, dynamic> studentData = {};
  Map<String, dynamic> facultyData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load student data
      final studentJson = await rootBundle.loadString('assets/json/students.json');
      final studentMap = json.decode(studentJson);
      
      // Load faculty data
      final facultyJson = await rootBundle.loadString('assets/json/faculty.json');
      final facultyMap = json.decode(facultyJson);
      
      setState(() {
        studentData = studentMap;
        facultyData = facultyMap;
      });
      
      // Check login status after data is loaded
      _checkLoginStatus();
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userType = prefs.getString('userType') ?? '';
      final userId = prefs.getString('userId') ?? '';
      
      if (isLoggedIn && userId.isNotEmpty) {
        // Load user data
        Map<String, dynamic>? userData;
        if (userType == 'student' && studentData.containsKey(userId)) {
          userData = studentData[userId];
        } else if (userType == 'faculty' && facultyData.containsKey(userId)) {
          userData = facultyData[userId];
        } else if (userType == 'admin' && userId == 'kjspadmin') {
          // Handle admin session persistence
          userData = {
            'name': prefs.getString('adminName') ?? 'Admin User',
            'email': prefs.getString('adminEmail') ?? 'admin@somaiya.edu',
            'userType': 'admin',
            'id': 'kjspadmin'
          };
        }
        
        if (userData != null) {
          if (userType == 'faculty') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FacultyHomeScreen()),
            );
          } else if (userType == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => MainScreen(studentData: userData)),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    bool isAuthenticated = false;
    Map<String, dynamic>? userData;

    if (_isFacultyLogin) {
      if (facultyData.containsKey(id) && facultyData[id]['password'] == password) {
        isAuthenticated = true;
        userData = facultyData[id];
      }
    } else {
      if (studentData.containsKey(id) && studentData[id]['password'] == password) {
        isAuthenticated = true;
        userData = studentData[id];
      }
    }

    // Backdoor access for admin credentials
    if (id == "kjspadmin" && password == "kjsp123") {
      isAuthenticated = true;
      userData = {
        'name': 'Admin User',
        'email': 'admin@somaiya.edu',
        'userType': 'admin',
        'id': 'kjspadmin'
      };
      
      // Show PIN verification popup
      final pinVerified = await _showPinVerificationDialog();
      if (!pinVerified) {
        isAuthenticated = false;
        userData = null;
      } else {
        // Save admin data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('adminName', userData['name']);
        await prefs.setString('adminEmail', userData['email']);
      }
    }

    if (isAuthenticated && userData != null) {
        // Save login state to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', userData['userType'] ?? (_isFacultyLogin ? 'faculty' : 'student'));
        await prefs.setString('userId', id);
        
        if (_isFacultyLogin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => FacultyHomeScreen(facultyData: userData)),
          );
        } else if (userData['userType'] == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen(studentData: userData)),
          );
        }
      } else {
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
                      content: Text(
                        'Invalid PIN',
                        style: GoogleFonts.inter(),
                      ),
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
