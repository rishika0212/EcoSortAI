import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_service.dart';
import 'user_service.dart';
import 'event_bus.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.222:8000";

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth) {
      final token = await LocalStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      // First, clear any existing data to ensure a clean state
      await LocalStorageService.clearAuthData();
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        // Save token and username
        await LocalStorageService.saveToken(token);
        await LocalStorageService.saveUsername(username);

        // Just return success immediately - we'll fetch the profile in the background
        // This prevents the login screen from showing an error
        
        // Start a background task to fetch the profile
        Future.microtask(() async {
          try {
            await _storeUserProfile();
            print("AuthService: Successfully fetched user profile in background");
            
            // Emit an event to notify the UI that the profile has been updated
            final points = await LocalStorageService.getPoints();
            EventBus().emitPointsUpdated(points);
          } catch (e) {
            print("AuthService: Failed to fetch profile in background: $e");
            // Don't show an error to the user, just log it
          }
        });

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Login failed.',
        };
      }
    } catch (e) {
      print("AuthService: Login error: $e");
      return {
        'success': false,
        'message': 'Login error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Registration failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    await LocalStorageService.clearAuthData();
  }

  Future<bool> isLoggedIn() async {
    final token = await LocalStorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> refreshUserData() async {
    print("AuthService: refreshUserData called");
    await _storeUserProfile();
  }

  Future<void> _storeUserProfile() async {
    try {
      print("AuthService: Storing user profile");
      final result = await UserService().getUserProfile();
      if (result['success']) {
        final user = result['data'];
        final username = user['username'];
        final points = user['points'] ?? 0;
        
        print("AuthService: Storing user profile - username: $username, points: $points");
        
        // Save username and points
        await LocalStorageService.saveUsername(username);
        await LocalStorageService.savePoints(points);
        
        // Get badge info
        final String badgeName = user['badge'] ?? '🐣 Green Beginner';
        final String badgeColor = user['badge_color'] ?? '#D0F0C0';
        
        // Store badge info in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('badge_name', badgeName);
        await prefs.setString('badge_color', badgeColor);
        
        print("AuthService: Stored badge info - name: $badgeName, color: $badgeColor");
        
        // Emit points updated event
        EventBus().emitPointsUpdated(points);
        
        // Also store plastic counts
        final scanCounts = <String, int>{
          'PET': (user['pet_count'] ?? 0) as int,
          'HDPE': (user['hdpe_count'] ?? 0) as int,
          'LDPE': (user['ldpe_count'] ?? 0) as int,
          'PP': (user['pp_count'] ?? 0) as int,
          'PS': (user['ps_count'] ?? 0) as int,
        };
        await LocalStorageService.savePlasticCounts(scanCounts);
        
        print("AuthService: Stored plastic counts: $scanCounts");
        
        // Store the last update time
        await prefs.setInt('last_profile_update', DateTime.now().millisecondsSinceEpoch);
        
        // Also store points in SharedPreferences for backward compatibility
        await prefs.setInt('points', points);
        
        // Store the last updated plastic type and time to ensure UI updates
        if (scanCounts.values.any((count) => count > 0)) {
          // Find the plastic type with the highest count
          String highestType = 'PET';
          int highestCount = 0;
          
          scanCounts.forEach((type, count) {
            if (count > highestCount) {
              highestCount = count;
              highestType = type;
            }
          });
          
          // Set this as the last updated plastic to trigger UI updates
          await prefs.setString('last_updated_plastic', highestType);
          await prefs.setInt('last_update_time', DateTime.now().millisecondsSinceEpoch);
          print("AuthService: Set last updated plastic to $highestType");
        }
        
        print("AuthService: Successfully stored user profile");
      } else {
        print("AuthService: Failed to get user profile: ${result['message']}");
        throw Exception("Failed to get user profile: ${result['message']}");
      }
    } catch (e) {
      print('AuthService: Error fetching user profile: $e');
      throw e; // Re-throw to allow retry logic in the caller
    }
  }

  // ✅ Add missing: getPoints()
  Future<int> getPoints() async {
    final result = await UserService().getUserProfile();
    if (result['success']) {
      final points = result['data']['points'] ?? 0;
      await LocalStorageService.savePoints(points);
      return points;
    }
    return 0;
  }

  // ✅ Add missing: updatePoints()
  Future<Map<String, dynamic>> updatePoints(int pointsToAdd, String plasticType) async {
    final url = Uri.parse('$baseUrl/points'); // Correct endpoint without /users prefix
    
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode({
          'plastic_type': plasticType,
          'points_to_add': pointsToAdd
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("AuthService: Points update response: $responseData");
        
        // Extract data from the response
        if (responseData['success'] && responseData['data'] != null) {
          final data = responseData['data'];
          
          // Save points to LocalStorageService
          if (data['points'] != null) {
            await LocalStorageService.savePoints(data['points']);
          }
          
          // Save scan counts if they're in the response
          final scanCounts = {
            'PET': (data['pet_count'] ?? 0) as int,
            'HDPE': (data['hdpe_count'] ?? 0) as int,
            'LDPE': (data['ldpe_count'] ?? 0) as int,
            'PP': (data['pp_count'] ?? 0) as int,
            'PS': (data['ps_count'] ?? 0) as int,
          };
          
          // Save scan counts to LocalStorageService
          await LocalStorageService.savePlasticCounts(scanCounts);
          
          // Store the last updated plastic type and time
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_updated_plastic', plasticType);
          await prefs.setInt('last_update_time', DateTime.now().millisecondsSinceEpoch);
          
          print("AuthService: Updated points: ${data['points']}");
          print("AuthService: Updated scan counts: $scanCounts");
          
          // After updating points, refresh user data
          await refreshUserData();
          
          return {'success': true, 'data': data};
        }
        
        return {'success': true, 'data': responseData['data'] ?? {}};
      } else {
        final data = jsonDecode(response.body);
        print("AuthService: Failed to update points: ${response.body}");
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to update points.',
        };
      }
    } catch (e) {
      print("AuthService: Error updating points: $e");
      return {'success': false, 'message': 'Error updating points: $e'};
    }
  }
}
