import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class Material {
  final String id;
  final String title;
  final String description;
  final String facultyId;
  final String fileType;
  final int fileSize;
  final String fileUrl;
  final DateTime createdAt;

  Material({
    required this.id,
    required this.title,
    required this.description,
    required this.facultyId,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
    required this.createdAt,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      facultyId: json['faculty_id'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      fileUrl: json['file_url'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class UploadedMaterialsScreen extends StatefulWidget {
  const UploadedMaterialsScreen({Key? key}) : super(key: key);

  @override
  State<UploadedMaterialsScreen> createState() =>
      _UploadedMaterialsScreenState();
}

class _UploadedMaterialsScreenState extends State<UploadedMaterialsScreen> {
  List<Material> _materials = [];
  bool _isLoading = true;
  String _studentBatch = 'Loading...';

  @override
  void initState() {
    super.initState();
    print(
      '📚 [MATERIALS] initState() called - Materials screen is initializing!',
    );
    _loadStudentBatch().then((_) {
      _fetchMaterials();
    });
  }

  Future<void> _loadStudentBatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Print all available keys in SharedPreferences
      print('📚 [MATERIALS] All SharedPreferences keys: ${prefs.getKeys()}');

      // Debug: Check each individual field
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

      print('📚 [MATERIALS] Raw data from SharedPreferences:');
      print('📚 [MATERIALS] studentName: $studentName');
      print('📚 [MATERIALS] studentEmail: $studentEmail');
      print('📚 [MATERIALS] studentPhone: $studentPhone');
      print('📚 [MATERIALS] studentAddress: $studentAddress');
      print('📚 [MATERIALS] studentDepartment: $studentDepartment');
      print('📚 [MATERIALS] studentYear: $studentYear');
      print('📚 [MATERIALS] studentRollNumber: $studentRollNumber');
      print('📚 [MATERIALS] studentId: $studentId');
      print('📚 [MATERIALS] studentSgpa: $studentSgpa');
      print('📚 [MATERIALS] studentLabBatch: $studentLabBatch');
      print('📚 [MATERIALS] studentDateOfBirth: $studentDateOfBirth');

      final batch = prefs.getString('studentYear') ?? 'Loading...';
      setState(() {
        _studentBatch = batch;
      });
      print('📚 [MATERIALS] Loaded student batch: $batch');
    } catch (e) {
      print('❌ [MATERIALS] Error loading student batch: $e');
    }
  }

  Future<void> _fetchMaterials() async {
    try {
      print('📚 [MATERIALS] _fetchMaterials() method started');

      if (_studentBatch.isEmpty ||
          _studentBatch == 'Loading...' ||
          _studentBatch == 'Loading...') {
        print('📚 [MATERIALS] Early return - batch is empty or loading');
        print('📚 [MATERIALS] _studentBatch value: "$_studentBatch"');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('📚 [MATERIALS] Fetching materials for batch: $_studentBatch');

      final url = '${ApiService.baseUrl}/materials?batch=$_studentBatch';
      print('📚 [MATERIALS] Full API URL: $url');

      print('📚 [MATERIALS] About to make HTTP GET request...');
      final response = await http.get(Uri.parse(url));
      print('📚 [MATERIALS] HTTP request completed');

      print('📚 [MATERIALS] Response status: ${response.statusCode}');
      print('📚 [MATERIALS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('📚 [MATERIALS] About to parse JSON response...');
        final List<dynamic> data = json.decode(response.body);
        print('📚 [MATERIALS] Parsed JSON data: $data');

        final List<Material> materials = data
            .map((json) => Material.fromJson(json))
            .toList();

        print('📚 [MATERIALS] About to update UI state...');
        setState(() {
          _materials = materials;
          _isLoading = false;
        });
        print('📚 [MATERIALS] UI state updated successfully');

        print('📚 [MATERIALS] Loaded ${materials.length} materials');
        for (var material in materials) {
          print('📚 [MATERIALS] - ${material.title} by ${material.facultyId}');
        }
      } else {
        print('❌ [MATERIALS] API Error - Status: ${response.statusCode}');
        print('❌ [MATERIALS] API Error - Body: ${response.body}');
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [MATERIALS] EXCEPTION CAUGHT: $e');
      print('❌ [MATERIALS] Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });

      print('📚 [MATERIALS] About to show error snackbar...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading materials: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFA50C22),
        ),
      );
      print('📚 [MATERIALS] Error snackbar shown');
    }
  }

  Future<void> _openMaterial(String fileUrl, String fileName) async {
    try {
      print('🔗 [MATERIALS] Opening material: $fileName');

      final downloadUrl = '${ApiService.baseUrl}$fileUrl';
      print('🔗 [MATERIALS] Open URL: $downloadUrl');

      // Use url_launcher to open the file
      final Uri uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🔗 [MATERIALS] File opened successfully: $fileName');
      } else {
        throw Exception('Could not launch URL: $downloadUrl');
      }
    } catch (e) {
      print('❌ [MATERIALS] Error opening material: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error opening material: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFA50C22),
        ),
      );
    }
  }

  Future<void> _downloadMaterial(String fileUrl, String fileName) async {
    try {
      print('📥 [MATERIALS] Downloading material: $fileName');

      final downloadUrl = '${ApiService.baseUrl}$fileUrl';
      print('📥 [MATERIALS] Download URL: $downloadUrl');

      // Download the file
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        // Get the directory to save the file
        final directory = await getApplicationDocumentsDirectory();

        // Extract file extension from URL if not in filename
        String fullFileName = fileName;
        if (!fileName.contains('.')) {
          final urlPath = Uri.parse(downloadUrl).path;
          final extension = urlPath.split('.').last;
          fullFileName = '$fileName.$extension';
        }

        final filePath = '${directory.path}/$fullFileName';

        print('📥 [MATERIALS] Saving to: $filePath');

        // Save the file
        await File(filePath).writeAsBytes(response.bodyBytes);

        print('📥 [MATERIALS] File downloaded successfully: $filePath');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Downloaded: $fullFileName',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [MATERIALS] Error downloading material: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error downloading material: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFA50C22),
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFA50C22,
        ), // Same app bar color as other screens
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Uploaded Materials',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
              ),
            )
          : _materials.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 80,
                    color: const Color(0xFFA50C22),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Materials Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Materials uploaded by faculty will appear here',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchMaterials,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _materials.length,
                itemBuilder: (context, index) {
                  final material = _materials[index];
                  return _buildMaterialCard(material);
                },
              ),
            ),
    );
  }

  Widget _buildMaterialCard(Material material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA50C22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  material.fileType.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatFileSize(material.fileSize),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            material.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            material.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                material.facultyId,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const Spacer(),
              Text(
                '${material.createdAt.day}/${material.createdAt.month}/${material.createdAt.year}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Download Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 20),
              label: Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA50C22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _openMaterial(material.fileUrl, material.title),
            ),
          ),
        ],
      ),
    );
  }
}
