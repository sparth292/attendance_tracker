import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({Key? key}) : super(key: key);

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<dynamic> _courses = [];
  List<dynamic> _filteredCourses = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String _selectedType = 'THEORY';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _batchController.dispose();
    _creditsController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    print('Loading courses...');
    try {
      // Add timestamp to prevent caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('http://13.235.16.3:5001/courses/?t=$timestamp'),
      );

      print('Load courses response status: ${response.statusCode}');
      print('Load courses response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');
        setState(() {
          _courses = data['courses'] ?? [];
          _filteredCourses = _courses;
          _isLoading = false;
        });
        print('Courses loaded: ${_courses.length} courses');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load courses');
      }
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  void _filterCourses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = _courses.where((course) {
        return course[0].toString().toLowerCase().contains(query) ||
            course[1].toString().toLowerCase().contains(query) ||
            course[2].toString().toLowerCase().contains(query) ||
            course[3].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Course',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g., CS101',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g., Data Structures',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  hintText: 'e.g., Computer Engineering',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch',
                  hintText: 'e.g., FYCO, SYCO, TYCO',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credits',
                  hintText: 'e.g., 4',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Course Type'),
                items: const [
                  DropdownMenuItem(value: 'THEORY', child: Text('Theory')),
                  DropdownMenuItem(value: 'LAB', child: Text('Lab')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addCourse();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA50C22),
            ),
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourse() async {
    final newCourse = [
      _codeController.text.trim(),
      _nameController.text.trim(),
      _departmentController.text.trim(),
      _batchController.text.trim(),
      int.tryParse(_creditsController.text.trim()) ?? 4,
    ];

    print('Creating course with data: $newCourse');
    print('JSON being sent: ${jsonEncode(newCourse)}');

    try {
      final response = await http.post(
        Uri.parse('http://13.235.16.3:5001/courses/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'course_code': _codeController.text.trim(),
          'course_name': _nameController.text.trim(),
          'department': _departmentController.text.trim(),
          'batch': _batchController.text.trim(),
          'credits': int.tryParse(_creditsController.text.trim()) ?? 4,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar('Course added successfully!');
        _clearForm();
        // Add a small delay before reloading to ensure server has processed the request
        await Future.delayed(const Duration(milliseconds: 500));
        _loadCourses();
      } else {
        _showErrorSnackBar(
          'Failed to add course. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating course: $e');
      _showErrorSnackBar('Network error: $e');
    }
  }

  void _clearForm() {
    _codeController.clear();
    _nameController.clear();
    _departmentController.clear();
    _batchController.clear();
    _creditsController.clear();
    _selectedType = 'THEORY';
  }

  Future<void> _deleteCourse(String courseCode) async {
    print(' [DELETE] Attempting to delete course: $courseCode');
    print(' [DELETE] Course code type: ${courseCode.runtimeType}');

    if (courseCode.isEmpty || courseCode == 'Unknown') {
      print(' [DELETE] Invalid course code: $courseCode');
      _showErrorSnackBar('Invalid course code');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete course $courseCode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print(' [DELETE] User confirmed deletion');
      try {
        // Try multiple URL formats in case API expects different formats
        final deleteUrls = [
          'http://13.235.16.3:5001/courses/$courseCode',
          'http://13.235.16.3:5001/courses/code/$courseCode',
          'http://13.235.16.3:5001/courses/delete/$courseCode',
        ];

        for (int i = 0; i < deleteUrls.length; i++) {
          final deleteUrl = deleteUrls[i];
          print(' [DELETE] Trying URL $i: $deleteUrl');

          final response = await http
              .delete(
                Uri.parse(deleteUrl),
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(const Duration(seconds: 10));

          print(' [DELETE] Response status: ${response.statusCode}');
          print(' [DELETE] Response body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 204) {
            print(' [DELETE] Course deleted successfully!');
            _showSuccessSnackBar('Course deleted successfully!');

            // Add delay to ensure backend operation completes
            await Future.delayed(const Duration(milliseconds: 500));

            // Force refresh with cache busting
            setState(() {
              _courses = [];
              _filteredCourses = [];
              _isLoading = true;
            });

            // Reload courses after clearing cache
            await _loadCourses();

            // Additional delay to ensure UI updates
            await Future.delayed(const Duration(milliseconds: 300));

            return; // Success, exit loop
          } else if (response.statusCode == 404) {
            print(' [DELETE] Course not found (404)');
            _showErrorSnackBar('Course not found');
            return; // Not found, no point trying other URLs
          } else if (i == deleteUrls.length - 1) {
            // Last URL tried and still failed
            print(
              ' [DELETE] All URLs failed. Last error: ${response.statusCode}',
            );
            _showErrorSnackBar(
              'Failed to delete course. Status: ${response.statusCode}',
            );
          }
        }
      } on TimeoutException catch (e) {
        print(' [DELETE] Timeout error: $e');
        _showErrorSnackBar('Request timeout. Please try again.');
      } catch (e) {
        print(' [DELETE] Network error: $e');
        _showErrorSnackBar('Network error: $e');
      }
    }
  }

  Widget _buildCourseCard(dynamic course) {
    // Handle both object and array-based course data
    String courseCode, courseName, department, batch, credits;

    if (course is Map<String, dynamic>) {
      // Object-based data from API
      courseCode =
          course['course_code']?.toString() ?? course['code']?.toString() ?? '';
      courseName =
          course['course_name']?.toString() ?? course['name']?.toString() ?? '';
      department = course['department']?.toString() ?? '';
      batch = course['batch']?.toString() ?? '';
      credits = course['credits']?.toString() ?? '';
    } else if (course is List) {
      // Array-based data (fallback)
      courseCode = course[0]?.toString() ?? '';
      courseName = course[1]?.toString() ?? '';
      department = course[2]?.toString() ?? '';
      batch = course[3]?.toString() ?? '';
      credits = course[4]?.toString() ?? '';
    } else {
      // Unknown format
      courseCode = course.toString();
      courseName = 'Unknown';
      department = '';
      batch = '';
      credits = '';
    }

    // Check if course code or name contains "LAB"
    bool isLab =
        courseCode.toUpperCase().contains('LAB') ||
        courseName.toUpperCase().contains('LAB');
    String courseType = isLab ? 'LAB' : 'THEORY';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseCode,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFA50C22),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        courseName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: courseType == 'LAB'
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    courseType,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () => _deleteCourse(courseCode),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: const Color(0xFF6B7280)),
                const SizedBox(width: 3),
                Text(
                  department,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.group, size: 14, color: const Color(0xFF6B7280)),
                const SizedBox(width: 3),
                Text(
                  batch,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.stars, size: 14, color: const Color(0xFF6B7280)),
                const SizedBox(width: 3),
                Text(
                  '$credits credits',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Course Management',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search courses by code, name, department, or batch...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFA50C22)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Course List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No courses found',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      return _buildCourseCard(_filteredCourses[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        backgroundColor: const Color(0xFFA50C22),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
