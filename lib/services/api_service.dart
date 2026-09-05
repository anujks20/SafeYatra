import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // ============================================================
  // BACKEND URL
  // ============================================================

  static const String baseUrl = 'http://192.168.137.1:8000';

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return {
          'success': true,
          'message':
              data['message'] ?? 'Registration successful',
          'user_id': data['user_id'],
          'email': data['email'] ?? email,
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Registration failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data['message'] ?? 'Login successful',
          'user_id': data['user_id'],
          'full_name': data['full_name'] ?? '',
          'email': data['email'] ?? email,
          'profile_completed':
              data['profile_completed'] ?? false,
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Invalid email or password',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  static Future<Map<String, dynamic>> saveFCMToken(
    int userId,
    String fcmToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fcm-token/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return {
          'success': true,
          'message':
              data['message'] ??
                  'FCM token saved successfully',
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to save FCM token',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateProfile(
    int userId,
    String phone,
    String gender,
    int? age,
    String emergencyContactName,
    String emergencyContactPhone,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone.isEmpty ? null : phone,
          'gender': gender.isEmpty ? null : gender,
          'age': age,
          'emergency_contact_name':
              emergencyContactName.isEmpty
                  ? null
                  : emergencyContactName,
          'emergency_contact_phone':
              emergencyContactPhone.isEmpty
                  ? null
                  : emergencyContactPhone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data['message'] ??
                  'Profile updated successfully',
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to update profile',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getProfile(
    int userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to load profile',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // UPDATE USER LOCATION
  // ============================================================

  static Future<Map<String, dynamic>> updateUserLocation(
    int userId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/location/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data['message'] ?? 'Location updated',
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to update location',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // GET PRIVACY SETTINGS
  // ============================================================

  static Future<Map<String, dynamic>> getPrivacySettings(
    int userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/privacy/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'location_sharing':
              data['location_sharing'] ?? true,
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to load privacy settings',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // UPDATE PRIVACY SETTINGS
  // ============================================================

  static Future<Map<String, dynamic>> updatePrivacySettings(
    int userId,
    bool locationSharing,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/privacy/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'location_sharing': locationSharing,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data['message'] ??
                  'Privacy settings updated',
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to update privacy settings',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ============================================================
  // CREATE SOS ALERT
  // ============================================================

  static Future<Map<String, dynamic>> createSOSAlert(
    int userId, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sos/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return {
          'success': true,
          'message':
              data['message'] ??
                  'SOS alert created successfully',
          'data': data,
        };
      }

      return {
        'success': false,
        'message':
            data['detail'] ??
                data['message'] ??
                'Failed to create SOS alert',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}