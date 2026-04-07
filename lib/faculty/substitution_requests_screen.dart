import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubstitutionRequestsScreen extends StatefulWidget {
  final String? substitutionId;

  const SubstitutionRequestsScreen({super.key, this.substitutionId});

  @override
  State<SubstitutionRequestsScreen> createState() =>
      _SubstitutionRequestsScreenState();
}

class _SubstitutionRequestsScreenState
    extends State<SubstitutionRequestsScreen> {
  List<Map<String, dynamic>> _substitutionRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('🔔 [SUBSTITUTION] SubstitutionRequestsScreen initialized');
    print(
      '🔔 [SUBSTITUTION] Substitution ID from notification: ${widget.substitutionId}',
    );
    _loadSubstitutionRequests();
  }

  Future<void> _loadSubstitutionRequests() async {
    print('🔔 [SUBSTITUTION] Loading substitution requests...');

    try {
      // This would be your API to get substitution requests
      // For now, we'll simulate with mock data
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _substitutionRequests = [
          {
            'id': '1',
            'original_faculty': 'FAC002',
            'original_faculty_name': 'Varsha Kinge',
            'course_name': 'Software Engineering LAB',
            'date': '2026-04-06',
            'time': '15:30-17:30',
            'room': '218',
            'status': 'pending',
            'substitution_id': '1',
          },
          {
            'id': '2',
            'original_faculty': 'FAC001',
            'original_faculty_name': 'John Doe',
            'course_name': 'Data Structures',
            'date': '2026-04-06',
            'time': '10:30-11:30',
            'room': '101',
            'status': 'accepted',
            'substitution_id': '2',
          },
        ];
        _isLoading = false;
        print(
          '🔔 [SUBSTITUTION] Loaded ${_substitutionRequests.length} substitution requests',
        );
      });
    } catch (e) {
      print('❌ [SUBSTITUTION] Error loading substitution requests: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToRequest(String substitutionId, String action) async {
    print(
      '🔔 [SUBSTITUTION] Responding to request: $substitutionId, action: $action',
    );

    try {
      // Get current faculty ID
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      final response = await http.post(
        Uri.parse('http://13.235.16.3:5000/substitution/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'substitution_id': int.parse(substitutionId),
          'faculty_id': facultyId,
          'action': action.toUpperCase(),
        }),
      );

      print('🔔 [SUBSTITUTION] Response status: ${response.statusCode}');
      print('🔔 [SUBSTITUTION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔔 [SUBSTITUTION] Response recorded: ${data['message']}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Response recorded',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the list
        _loadSubstitutionRequests();
      } else {
        print(
          '❌ [SUBSTITUTION] Error responding to request: ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${response.statusCode}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [SUBSTITUTION] Error responding to request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Substitution Requests',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFA50C22),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.red[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSubstitutionRequests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA50C22),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry', style: GoogleFonts.inter()),
                  ),
                ],
              ),
            )
          : _substitutionRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No substitution requests',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have any substitution requests at the moment.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSubstitutionRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _substitutionRequests.length,
                itemBuilder: (context, index) {
                  final request = _substitutionRequests[index];
                  final isHighlighted =
                      widget.substitutionId == request['substitution_id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHighlighted
                            ? const Color(0xFFA50C22)
                            : const Color(0xFFE5E7EB),
                        width: isHighlighted ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(request['status']),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  request['status']?.toString().toUpperCase() ??
                                      'UNKNOWN',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (isHighlighted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA50C22),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            request['course_name'] ?? 'Unknown Course',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request['original_faculty_name'] ??
                                    'Unknown Faculty',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request['date'] ?? 'Unknown Date',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request['time'] ?? 'Unknown Time',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.room_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Room ${request['room'] ?? 'Unknown'}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (request['status'] == 'pending') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _respondToRequest(
                                      request['substitution_id'].toString(),
                                      'accept',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Accept',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _respondToRequest(
                                      request['substitution_id'].toString(),
                                      'reject',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Reject',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
