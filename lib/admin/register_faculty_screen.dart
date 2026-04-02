import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterFacultyScreen extends StatefulWidget {
  const RegisterFacultyScreen({Key? key}) : super(key: key);

  @override
  State<RegisterFacultyScreen> createState() => _RegisterFacultyScreenState();
}

class _RegisterFacultyScreenState extends State<RegisterFacultyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _facultyIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _facultyIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _facultyIdController.clear();
    _passwordController.clear();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _departmentController.clear();
    _designationController.clear();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestData = {
        'faculty_id': _facultyIdController.text.trim(),
        'password': _passwordController.text.trim(), // Match backend field name
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'department': _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        'designation': _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
      };
      
      print('Sending data: $requestData');
      
      final response = await http.post(
        Uri.parse('http://13.235.16.3:5001/api/faculty/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar('Faculty registered successfully!');
        _clearForm();
      } else {
        // Show detailed error information
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        _showErrorSnackBar('Registration failed. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Network error. Please check your connection.');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFA50C22)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA50C22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Register Faculty',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                          Icons.school,
                          size: 40,
                          color: Color(0xFFA50C22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Faculty Registration',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the faculty details below',
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
              
              // Registration Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Information',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Faculty ID
                    _buildTextField(
                      controller: _facultyIdController,
                      label: 'Faculty ID *',
                      hintText: 'Enter faculty ID',
                      icon: Icons.badge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Faculty ID is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password *',
                      hintText: 'Enter password',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      hintText: 'Enter full name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email *',
                      hintText: 'Enter email address',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Phone
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: 'Enter phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Department
                    _buildTextField(
                      controller: _departmentController,
                      label: 'Department',
                      hintText: 'Enter department',
                      icon: Icons.business,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Designation
                    _buildTextField(
                      controller: _designationController,
                      label: 'Designation',
                      hintText: 'Enter designation (e.g., Professor, Assistant Professor)',
                      icon: Icons.work,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA50C22),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Registering...',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Register Faculty',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
