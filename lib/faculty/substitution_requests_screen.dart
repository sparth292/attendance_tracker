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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current faculty ID
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      final response = await http.get(
        Uri.parse(
          'http://13.235.16.3:5000/substitution/requests?faculty_id=$facultyId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔔 [SUBSTITUTION] API Response Status: ${response.statusCode}');
      print('🔔 [SUBSTITUTION] API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> requests = [];

        if (data['pending_requests'] != null) {
          requests = List<Map<String, dynamic>>.from(data['pending_requests']);
        }

        setState(() {
          _substitutionRequests = requests;
          _isLoading = false;
          print(
            '🔔 [SUBSTITUTION] Loaded ${_substitutionRequests.length} substitution requests',
          );
        });
      } else {
        throw Exception(
          'Failed to load substitution requests: ${response.statusCode}',
        );
      }
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
      '?? [SUBSTITUTION] Responding to request: $substitutionId, action: $action',
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
              ),
              SizedBox(width: 16),
              Text('Processing...'),
            ],
          ),
        );
      },
    );

    try {
      // Get current faculty ID
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      // Validate substitutionId before parsing
      if (substitutionId.isEmpty) {
        print('ERROR: substitutionId is empty');
        Navigator.of(context).pop();
        return;
      }

      final requestBody = {
        'substitution_id': int.tryParse(substitutionId) ?? 0,
        'faculty_id': facultyId,
        'action': action.toUpperCase(),
      };
      
      print('?? [SUBSTITUTION] API Request URL: http://13.235.16.3:5000/substitution/respond');
      print('?? [SUBSTITUTION] API Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://13.235.16.3:5000/substitution/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Close loading dialog
      Navigator.of(context).pop();

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

        // Refresh the list and trigger home screen refresh
        setState(() {
          _loadSubstitutionRequests();
        });

        // Navigate back to home screen to refresh the lecture list
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate refresh needed
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
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

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
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications currently',
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
                      widget.substitutionId != null && widget.substitutionId == request['id'];

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
                                '${request['start_time'] ?? 'Unknown'} - ${request['end_time'] ?? 'Unknown'}',
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
                                'Room ${request['room_no'] ?? 'Unknown'}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (request['status'] == 'pending' || request['status'] == 'PENDING') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final subId = request['id'] ?? request['substitution_id'];
                                      if (subId != null) {
                                        _respondToRequest(
                                          subId.toString(),
                                          'accept',
                                        );
                                      }
                                    },
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
                                    onPressed: () {
                                      final subId = request['id'] ?? request['substitution_id'];
                                      if (subId != null) {
                                        _respondToRequest(
                                          subId.toString(),
                                          'reject',
                                        );
                                      }
                                    },
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
      case 'PENDING':
        return Colors.orange;
      case 'accepted':
      case 'ACCEPTED':
        return Colors.green;
      case 'rejected':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
