import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Resolve Border naming conflict
import 'package:flutter/src/painting/box_border.dart' as flutter_border;

/// Screen for bulk student upload via Excel
class StudentBulkUploadScreen extends StatefulWidget {
  const StudentBulkUploadScreen({super.key});

  @override
  State<StudentBulkUploadScreen> createState() =>
      _StudentBulkUploadScreenState();
}

class _StudentBulkUploadScreenState extends State<StudentBulkUploadScreen> {
  static const String _baseUrl = 'http://13.235.16.3:5001';

  bool _isDownloading = false;
  bool _isUploading = false;

  static const List<String> _excelColumns = [
    'student_id',
    'password_hash',
    'name',
    'email',
    'phone',
    'date_of_birth',
    'address',
    'department',
    'year',
    'roll_number',
    'sgpa',
    'lab_batch',
  ];

  // ───────────────────────────── Download ─────────────────────────────

  Future<void> _downloadExcelFormat() async {
    setState(() => _isDownloading = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Students'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int i = 0; i < _excelColumns.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(_excelColumns[i]);
        cell.cellStyle = headerStyle;
        sheet.setColumnWidth(i, 22);
      }

      // Sample hint row — matches exact format seen in DB image
      final hintValues = [
        '1920230001', // student_id
        'prayag@123', // password_hash
        'Prayag Upadhyaya', // name
        'prayag.u@somaiya.edu', // email — @somaiya.edu only
        '93214 86739', // phone — 5digits space 5digits (+91 auto-prepended)
        '2003-05-10', // date_of_birth
        'Ghatkopar, Maharashtra', // address
        'Computer Engineering', // department — fixed value
        'SYCO', // year
        'FCUG23762', // roll_number — text (not numeric)
        '8.20', // sgpa — decimal preserved
        'C3', // lab_batch — text
      ];

      final hintStyle = CellStyle(
        italic: true,
        fontColorHex: ExcelColor.fromHexString('#888888'),
      );

      for (int i = 0; i < hintValues.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
        );
        // Store ALL hint values as TextCellValue so Excel never auto-converts
        cell.value = TextCellValue(hintValues[i]);
        cell.cellStyle = hintStyle;
      }

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel file');

      // Write to temp dir first, then trigger native Save As dialog
      // so the user can choose to save to Google Drive, Downloads, etc.
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/student_upload_format.xlsx';
      await File(tempPath).writeAsBytes(fileBytes);

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save Student Template',
        fileName: 'student_upload_format.xlsx',
        bytes: Uint8List.fromList(fileBytes),
      );

      if (mounted) {
        if (savedPath != null) {
          _showSnackBar('✅ Template saved successfully!', Colors.green);
        } else {
          _showSnackBar('ℹ️ Save cancelled', Colors.orange);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('❌ Download failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ───────────────────────────── Validation ──────────────────────────

  String? _validateRow(
    Map<String, dynamic> data,
    int rowIndex,
    Set<String> seenStudentIds,
    Set<String> seenRollNumbers,
  ) {
    final studentId = data['student_id']?.toString() ?? '';
    final rollNumber = data['roll_number']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final department = data['department']?.toString() ?? '';
    // Lab batch - optional but if provided should not be empty
    final labBatch = data['lab_batch']?.toString() ?? '';
    if (labBatch.isNotEmpty && labBatch.trim().isEmpty) {
      return 'Row $rowIndex: Lab batch is required';
    }
    if (seenStudentIds.contains(studentId)) {
      return 'Row $rowIndex: Duplicate student_id "$studentId"';
    }

    // Duplicate roll_number
    if (rollNumber.isNotEmpty && seenRollNumbers.contains(rollNumber)) {
      return 'Row $rowIndex: Duplicate roll_number "$rollNumber"';
    }

    // Email must be @somaiya.edu
    if (!email.toLowerCase().endsWith('@somaiya.edu')) {
      return 'Row $rowIndex: Email "$email" must be @somaiya.edu';
    }

    // Phone format: +91 XXXXX XXXXX (auto-formatted by upload parser)
    final phoneRegex = RegExp(r'^\+91 \d{5} \d{5}$');
    if (phone.isNotEmpty && !phoneRegex.hasMatch(phone)) {
      return 'Row $rowIndex: Phone "$phone" must be 10 digits (e.g. 98195 66115)';
    }

    // Department must be Computer Engineering
    if (department.toLowerCase() != 'computer engineering') {
      return 'Row $rowIndex: Department must be "Computer Engineering"';
    }

    return null;
  }

  // ───────────────────────────── Upload ──────────────────────────────

  Future<void> _uploadExcelFile() async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isUploading = false);
        return;
      }

      final bytes = File(result.files.single.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.isEmpty) throw Exception('Excel file is empty');

      final headers = rows[0]
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();

      const required = ['student_id', 'name', 'email'];
      for (final col in required) {
        if (!headers.contains(col)) {
          throw Exception('Missing required column: "$col"');
        }
      }

      int successCount = 0;
      int failCount = 0;
      final List<String> errors = [];

      final Set<String> seenStudentIds = {};
      final Set<String> seenRollNumbers = {};

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.every((cell) =>
            cell == null ||
            cell.value == null ||
            cell.value.toString().isEmpty)) {
          continue;
        }

        final Map<String, dynamic> studentData = {};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          var key = headers[j];
          if (key.isEmpty) continue;

          if (key == 'password_hash') key = 'password';

          final cellValue = row[j]?.value;
          if (cellValue == null) continue;

          String value;

          if (key == 'sgpa' || key == 'phone') {
            // Preserve exact string — no numeric conversion
            value = cellValue.toString().trim();
            // Normalize phone: strip all spaces, then auto-prepend +91
            if (key == 'phone' && value.isNotEmpty) {
              // If Excel read it as a double (e.g. 9819566115.0), convert to int first
              if (cellValue is DoubleCellValue) {
                value = cellValue.value.toInt().toString();
              } else if (cellValue is IntCellValue) {
                value = cellValue.value.toString();
              }
              // Remove any existing +91 or 0 prefix and all spaces
              value = value.replaceAll(' ', '').replaceAll('+91', '').replaceAll(RegExp(r'^0'), '');
              // value is now a clean 10-digit string e.g. "9819566115"
              // Format as +91 XXXXX XXXXX
              if (value.length == 10) {
                value = '+91 ${value.substring(0, 5)} ${value.substring(5)}';
              }
            }
          } else {
            // For all other columns avoid decimal representation.
            // DoubleCellValue happens when Excel auto-reads a number cell.
            // We convert to int first to strip the ".0" cleanly.
            // TextCellValue (lab_batch, roll_number, name, etc.) comes
            // through toString() unchanged — this is the lab_batch fix.
            if (cellValue is DoubleCellValue) {
              value = cellValue.value.toInt().toString();
            } else if (cellValue is IntCellValue) {
              value = cellValue.value.toString();
            } else {
              // TextCellValue, SharedStringCellValue — use raw string
              value = cellValue.toString().trim();
            }
          }

          if (value.isNotEmpty) {
            studentData[key] = value;
          }
        }

        // Client-side validation before hitting API
        final validationError = _validateRow(
          studentData,
          i + 1,
          seenStudentIds,
          seenRollNumbers,
        );

        if (validationError != null) {
          failCount++;
          errors.add(validationError);
          continue;
        }

        seenStudentIds.add(studentData['student_id'].toString());
        if (studentData.containsKey('roll_number')) {
          seenRollNumbers.add(studentData['roll_number'].toString());
        }

        try {
          final response = await http.post(
            Uri.parse('$_baseUrl/student/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(studentData),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            successCount++;
          } else {
            failCount++;
            errors.add('Row ${i + 1}: ${response.body}');
          }
        } catch (e) {
          failCount++;
          errors.add('Row ${i + 1}: Network error — $e');
        }
      }

      if (mounted) {
        _showUploadResultDialog(successCount, failCount, errors);
      }
    } catch (e) {
      if (mounted) _showSnackBar('❌ Upload failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─────────────────────────── Helpers ───────────────────────────────

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showUploadResultDialog(int success, int fail, List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              fail == 0 ? Icons.check_circle : Icons.warning_amber_rounded,
              color: fail == 0 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Upload Result'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultRow('✅ Successful', success, Colors.green),
              _resultRow('❌ Failed', fail, Colors.red),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Error Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Text(
                      errors.join('\n'),
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────── UI ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Bulk Student Upload',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  size: 64,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bulk Student Upload',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Download the template, fill in student data,\nthen upload to register students in bulk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Validation rules info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: flutter_border.Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Format Rules',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ruleItem('Department must be "Computer Engineering"'),
                    _ruleItem('Email must end with @somaiya.edu'),
                    _ruleItem('Phone: enter 10 digits only (e.g. 98195 66115), +91 added automatically'),
                    _ruleItem('student_id must be unique'),
                    _ruleItem('roll_number must be unique'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _ActionCard(
                icon: Icons.download_rounded,
                title: 'Download Excel Format',
                subtitle: 'Get the template with all required columns',
                color: const Color(0xFF1E3A5F),
                isLoading: _isDownloading,
                onTap: _downloadExcelFormat,
              ),

              const SizedBox(height: 16),

              _ActionCard(
                icon: Icons.upload_file_rounded,
                title: 'Upload Excel File',
                subtitle: 'Select your filled Excel file to register students',
                color: const Color(0xFF2E7D32),
                isLoading: _isUploading,
                onTap: _uploadExcelFile,
              ),

              const SizedBox(height: 32),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _excelColumns
                    .map(
                      (col) => Chip(
                        label: Text(
                          col,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            const Color(0xFF1E3A5F).withOpacity(0.08),
                        labelStyle:
                            const TextStyle(color: Color(0xFF1E3A5F)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Template columns',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Action Card Widget ────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withOpacity(0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}