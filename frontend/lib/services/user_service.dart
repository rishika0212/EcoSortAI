import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';
import 'event_bus.dart';

class UserService {
  // static const String baseUrl = "http://10.0.2.2:8000"; // For Android emulator to connect to localhost
  // static const String baseUrl = "http://localhost:8000"; // For local testing
  static const String baseUrl = "http://192.168.1.222:8000"; // IP address of the server on the network

  // Construct auth headers including JWT token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await LocalStorageService.getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
  
  /// Fetch leaderboard data
  Future<Map<String, dynamic>> getLeaderboard() async {
    final url = Uri.parse('$baseUrl/leaderboard');
    print("UserService: Fetching leaderboard from $url");

    try {
      final headers = await _getAuthHeaders();
      print("UserService: Using headers: $headers");
      
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print("UserService: Leaderboard response status: ${response.statusCode}");
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("UserService: Successfully fetched leaderboard data");
        print("UserService: Leaderboard data: ${data['data']}");
        
        // Ensure we have a valid data structure
        if (data['data'] == null) {
          print("UserService: Leaderboard data is null");
          return {
            'success': false,
            'message': 'No leaderboard data received from server',
          };
        }
        
        return {'success': true, 'data': data['data']};
      } else {
        print("UserService: Failed to fetch leaderboard: ${data['detail'] ?? 'Unknown error'}");
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to fetch leaderboard.',
        };
      }
    } catch (e) {
      print("UserService: Exception fetching leaderboard: $e");
      return {'success': false, 'message': 'Error fetching leaderboard: $e'};
    }
  }

  /// Fetch authenticated user's profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$baseUrl/users/me');
    print("UserService: Fetching user profile from $url");

    try {
      final headers = await _getAuthHeaders();
      print("UserService: Using headers: $headers");
      
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print("UserService: Profile response status: ${response.statusCode}");
      print("UserService: Profile response body: ${response.body}");
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("UserService: Successfully fetched profile data: ${data['data']}");
        return {'success': true, 'data': data['data']};
      } else {
        print("UserService: Failed to fetch profile: ${data['detail'] ?? 'Unknown error'}");
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to fetch user profile.',
        };
      }
    } catch (e) {
      print("UserService: Exception fetching profile: $e");
      return {'success': false, 'message': 'Error fetching profile: $e'};
    }
  }

  /// Update user points and scanned plastic type
  /// Updates the points for the current user based on the plastic type scanned
  Future<Map<String, dynamic>> updatePoints(int pointsToAdd, String plasticType) async {
    final url = Uri.parse('$baseUrl/points'); // Correct endpoint without /users prefix
    final body = jsonEncode({
      'plastic_type': plasticType,
      'points_to_add': pointsToAdd
    });

    try {
      print("UserService: Updating points - Type: $plasticType, Points to add: $pointsToAdd");
      print("UserService: POST request to $url with body: $body");
      
      final headers = await _getAuthHeaders();
      print("UserService: Using headers: $headers");
      
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      print("UserService: Points update response status: ${response.statusCode}");
      print("UserService: Points update response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("UserService: Points update response data: $responseData");
        
        // Extract data from the response
        if (responseData['success'] && responseData['data'] != null) {
          final data = responseData['data'];
          print("UserService: Processing response data: $data");
          
          // Save points to LocalStorageService
          if (data['points'] != null) {
            final points = data['points'] as int;
            print("UserService: Saving points: $points");
            await LocalStorageService.savePoints(points);
            
            // Also store points in SharedPreferences for backward compatibility
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('points', points);
            
            // Emit points updated event
            EventBus().emitPointsUpdated(points);
            print("UserService: Emitted points updated event with $points points");
            
            // Also emit a leaderboard update event
            EventBus().emitLeaderboardUpdated();
            print("UserService: Emitted leaderboard updated event");
          } else {
            print("UserService: No points data in response");
          }
          
          // Get badge info if available
          if (data['badge'] != null) {
            final String badgeName = data['badge'];
            final String badgeColor = data['badge_color'] ?? '#D0F0C0';
            
            print("UserService: Saving badge info - name: $badgeName, color: $badgeColor");
            
            // Store badge info in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('badge_name', badgeName);
            await prefs.setString('badge_color', badgeColor);
          } else {
            print("UserService: No badge data in response");
          }
          
          // Save scan counts if they're in the response
          final scanCounts = {
            'PET': (data['pet_count'] ?? 0) as int,
            'HDPE': (data['hdpe_count'] ?? 0) as int,
            'LDPE': (data['ldpe_count'] ?? 0) as int,
            'PP': (data['pp_count'] ?? 0) as int,
            'PS': (data['ps_count'] ?? 0) as int,
          };
          
          print("UserService: Saving scan counts: $scanCounts");
          
          // Save scan counts to LocalStorageService
          await LocalStorageService.savePlasticCounts(scanCounts);
          
          // Store the last updated plastic type and time
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_updated_plastic', plasticType);
          await prefs.setInt('last_update_time', DateTime.now().millisecondsSinceEpoch);
          await prefs.setInt('last_profile_update', DateTime.now().millisecondsSinceEpoch);
          
          print("UserService: Updated points: ${data['points']}");
          print("UserService: Updated scan counts: $scanCounts");
          
          // Force a refresh of the user profile to ensure all data is in sync
          print("UserService: Forcing profile refresh after points update");
          final profileResponse = await getUserProfile();
          print("UserService: Profile refresh response: $profileResponse");
          
          // Emit another points updated event to ensure UI updates
          if (data['points'] != null) {
            print("UserService: Emitting second points update event to ensure UI refresh");
            EventBus().emitPointsUpdated(data['points'] as int);
            
            // Also emit a leaderboard update event
            EventBus().emitLeaderboardUpdated();
            print("UserService: Emitted second leaderboard updated event");
          }
        } else {
          print("UserService: Response success or data is missing: $responseData");
        }
        
        return {'success': true, 'data': responseData['data'] ?? {}};
      } else {
        final data = jsonDecode(response.body);
        print("UserService: Failed to update points: ${response.body}");
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to update points.',
        };
      }
    } catch (e) {
      print("UserService: Error updating points: $e");
      return {'success': false, 'message': 'Error updating points: $e'};
    }
  }
}
