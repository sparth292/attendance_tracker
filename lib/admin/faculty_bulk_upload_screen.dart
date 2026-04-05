import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Screen for bulk faculty upload via Excel
class FacultyBulkUploadScreen extends StatefulWidget {
  const FacultyBulkUploadScreen({super.key});

  @override
  State<FacultyBulkUploadScreen> createState() =>
      _FacultyBulkUploadScreenState();
}

class _FacultyBulkUploadScreenState extends State<FacultyBulkUploadScreen> {
  static const String _baseUrl = 'http://13.235.16.3:5001';

  bool _isDownloading = false;
  bool _isUploading = false;

  // Columns matching the faculty DB schema
  // 'created_at' is excluded — auto-set by DB (CURRENT_TIMESTAMP default)
  static const List<String> _excelColumns = [
    'faculty_id',
    'password_hash',
    'name',
    'email',
    'phone',
    'department',
    'designation',
  ];

  // ───────────────────────────── Download ─────────────────────────────

  Future<void> _downloadExcelFormat() async {
    setState(() => _isDownloading = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Faculty'];

      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4A1942'),
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

      // Sample hint row
      final hintValues = [
        'FAC001',
        'plaintext_password',
        'Dr. Jane Smith',
        'jane@example.com',
        '9876543210',
        'Computer Science',
        'Associate Professor',
      ];

      final hintStyle = CellStyle(
        italic: true,
        fontColorHex: ExcelColor.fromHexString('#888888'),
      );

      for (int i = 0; i < hintValues.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
        );
        cell.value = TextCellValue(hintValues[i]);
        cell.cellStyle = hintStyle;
      }

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel file');

      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final filePath = '${directory.path}/faculty_upload_format.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (mounted) {
        _showSnackBar(
          '✅ Template saved to:\n$filePath',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('❌ Download failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
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

      // Validate required columns
      const required = ['faculty_id', 'name', 'email'];
      for (final col in required) {
        if (!headers.contains(col)) {
          throw Exception('Missing required column: "$col"');
        }
      }

      int successCount = 0;
      int failCount = 0;
      final List<String> errors = [];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.every((cell) =>
            cell == null ||
            cell.value == null ||
            cell.value.toString().isEmpty)) {
          continue;
        }

        final Map<String, dynamic> facultyData = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          var key = headers[j];
          final value = row[j]?.value?.toString().trim() ?? '';
          if (key.isNotEmpty && value.isNotEmpty) {
            // Remap Excel column name to what the API expects
            if (key == 'password_hash') key = 'password';
            facultyData[key] = value;
          }
        }

        try {
          final response = await http.post(
            Uri.parse('$_baseUrl/faculty/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(facultyData),
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
                  height: 120,
                  child: SingleChildScrollView(
                    child: Text(
                      errors.join('\n'),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.red),
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
          'Bulk Faculty Upload',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4A1942),
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
                  color: const Color(0xFF4A1942).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Color(0xFF4A1942),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bulk Faculty Upload',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A1942),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Download the template, fill in faculty data,\nthen upload to register faculty in bulk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              _ActionCard(
                icon: Icons.download_rounded,
                title: 'Download Excel Format',
                subtitle: 'Get the template with all required columns',
                color: const Color(0xFF4A1942),
                isLoading: _isDownloading,
                onTap: _downloadExcelFormat,
              ),

              const SizedBox(height: 16),

              _ActionCard(
                icon: Icons.upload_file_rounded,
                title: 'Upload Excel File',
                subtitle: 'Select your filled Excel file to register faculty',
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
                            const Color(0xFF4A1942).withOpacity(0.08),
                        labelStyle:
                            const TextStyle(color: Color(0xFF4A1942)),
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