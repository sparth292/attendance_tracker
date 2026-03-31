import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://13.235.16.3:5000"; // deployed API

  static Future<Map<String, dynamic>> login(
    String rollNumber,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"roll_number": rollNumber, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Login failed");
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final url = Uri.parse("$baseUrl/sessions/active");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to fetch active sessions");
    }
  }

  static Future<Map<String, dynamic>> markAttendance({
    required String studentId, // This will actually contain roll_number
    required String sessionId,
    required String deviceId,
    required String timestamp,
  }) async {
    final url = Uri.parse("$baseUrl/attendance/mark");

    final requestBody = {
      "roll_number": studentId, // Use roll_number field instead of student_id
      "session_id": sessionId,
      "device_id": deviceId,
      "timestamp": timestamp,
    };

    print('📡 [API] Marking attendance...');
    print('🔗 [API] URL: $url');
    print('📋 [API] Request body: $requestBody');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    print('📊 [API] Response status: ${response.statusCode}');
    print('📊 [API] Response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to mark attendance");
    }
  }
}
