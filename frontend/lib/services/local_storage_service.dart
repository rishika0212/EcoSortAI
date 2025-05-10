import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _tokenKey = 'jwt_token';
  static const _usernameKey = 'username';
  static const _pointsKey = 'points';
  
  // Keys for plastic type counts
  static const _petCountKey = 'pet_count';
  static const _hdpeCountKey = 'hdpe_count';
  static const _ldpeCountKey = 'ldpe_count';
  static const _ppCountKey = 'pp_count';
  static const _psCountKey = 'ps_count';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
  
  // Get the last logged in username (useful for login screen)
  static Future<String?> getLastLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_logged_in_user');
  }

  static Future<void> savePoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, points);
  }

  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }
  
  // Save plastic type counts
  static Future<void> savePlasticCounts(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_petCountKey, counts['PET'] ?? 0);
    await prefs.setInt(_hdpeCountKey, counts['HDPE'] ?? 0);
    await prefs.setInt(_ldpeCountKey, counts['LDPE'] ?? 0);
    await prefs.setInt(_ppCountKey, counts['PP'] ?? 0);
    await prefs.setInt(_psCountKey, counts['PS'] ?? 0);
    
    print("LocalStorageService: Saved plastic counts: $counts");
  }
  
  // Get plastic type counts
  static Future<Map<String, int>> getPlasticCounts() async {
    final prefs = await SharedPreferences.getInstance();
    
    final counts = {
      'PET': prefs.getInt(_petCountKey) ?? 0,
      'HDPE': prefs.getInt(_hdpeCountKey) ?? 0,
      'LDPE': prefs.getInt(_ldpeCountKey) ?? 0,
      'PP': prefs.getInt(_ppCountKey) ?? 0,
      'PS': prefs.getInt(_psCountKey) ?? 0,
    };
    
    print("LocalStorageService: Retrieved plastic counts: $counts");
    return counts;
  }
  
  // Increment a specific plastic type count
  static Future<void> incrementPlasticCount(String plasticType) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    
    switch (plasticType) {
      case 'PET':
        key = _petCountKey;
        break;
      case 'HDPE':
        key = _hdpeCountKey;
        break;
      case 'LDPE':
        key = _ldpeCountKey;
        break;
      case 'PP':
        key = _ppCountKey;
        break;
      case 'PS':
        key = _psCountKey;
        break;
      default:
        print("LocalStorageService: Unknown plastic type: $plasticType");
        return;
    }
    
    final currentCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentCount + 1);
    print("LocalStorageService: Incremented $plasticType count to ${currentCount + 1}");
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  // Clear only authentication data when logging out, preserving user progress
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Only clear authentication token (security-sensitive)
    await prefs.remove(_tokenKey);
    
    // Store the username temporarily for a better UX on next login
    final username = prefs.getString(_usernameKey);
    if (username != null) {
      await prefs.setString('last_logged_in_user', username);
    }
    
    print("LocalStorageService: Cleared authentication token while preserving user data");
  }
  
  // Use this method if you need to completely reset all user data
  // This can be used for troubleshooting or when explicitly requested by the user
  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all authentication data
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_pointsKey);
    
    // Clear all plastic counts
    await prefs.remove(_petCountKey);
    await prefs.remove(_hdpeCountKey);
    await prefs.remove(_ldpeCountKey);
    await prefs.remove(_ppCountKey);
    await prefs.remove(_psCountKey);
    
    // Clear batch counts
    await prefs.remove('batch_pet');
    await prefs.remove('batch_hdpe');
    await prefs.remove('batch_ldpe');
    await prefs.remove('batch_pp');
    await prefs.remove('batch_ps');
    await prefs.remove('last_batch_reset');
    
    // Clear batch goals reached status
    await prefs.remove('batch_goal_reached_pet');
    await prefs.remove('batch_goal_reached_hdpe');
    await prefs.remove('batch_goal_reached_ldpe');
    await prefs.remove('batch_goal_reached_pp');
    await prefs.remove('batch_goal_reached_ps');
    
    // Clear any other related data
    await prefs.remove('last_updated_plastic');
    await prefs.remove('last_update_time');
    await prefs.remove('last_profile_update');
    await prefs.remove('points'); // For backward compatibility
    await prefs.remove('last_logged_in_user');
    
    print("LocalStorageService: Cleared all user data completely");
  }
}
