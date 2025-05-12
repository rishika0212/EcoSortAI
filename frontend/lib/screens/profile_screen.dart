import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  String _username = '';
  bool _isLoading = true;
  String _badgeName = 'Green Beginner';
  String _badgeEmoji = '🐣';
  int _points = 0;
  Map<String, int> _plasticCounts = {
    'PET': 0,
    'HDPE': 0,
    'LDPE': 0,
    'PP': 0,
    'PS': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadBadgeInfo();
    _loadPoints();
  }

  Future<void> _loadUserProfile() async {
    final response = await _userService.getUserProfile();
    if (!mounted) return;

    if (response['success']) {
      final data = response['data'];
      setState(() {
        _username = data['username'] ?? '';
        
        // Load plastic counts if available
        if (data['pet_count'] != null) {
          _plasticCounts['PET'] = data['pet_count'] ?? 0;
          _plasticCounts['HDPE'] = data['hdpe_count'] ?? 0;
          _plasticCounts['LDPE'] = data['ldpe_count'] ?? 0;
          _plasticCounts['PP'] = data['pp_count'] ?? 0;
          _plasticCounts['PS'] = data['ps_count'] ?? 0;
        }
        
        // Load points if available
        if (data['points'] != null) {
          _points = data['points'] ?? 0;
        }
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadBadgeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final badgeName = prefs.getString('badge_name') ?? '🐣 Green Beginner';
    
    setState(() {
      _badgeEmoji = _extractEmoji(badgeName);
      _badgeName = badgeName.replaceAll(_badgeEmoji, '').trim();
    });
  }

  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _points = prefs.getInt('points') ?? 0;
    });
  }

  String _extractEmoji(String badgeName) {
    // Extract the emoji from the badge name
    if (badgeName.isNotEmpty) {
      // Find the first emoji in the string
      final RegExp emojiRegex = RegExp(r'(\p{Emoji})', unicode: true);
      final Match? match = emojiRegex.firstMatch(badgeName);
      if (match != null) {
        return match.group(0) ?? '🐣';
      }
    }
    return '🐣'; // Default emoji
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlasticTypeCard(String type, int count, String emoji) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Recycled: $count items',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header with avatar and info
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Profile picture with badge emoji
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              _badgeEmoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Username and badge name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username in green color
                                Text(
                                  _username,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.green,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Badge name
                                Text(
                                  _badgeName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Stats section
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Your Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Stats cards in a row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Points',
                          _points.toString(),
                          Icons.star_rounded,
                          Colors.amber,
                        ),
                      ),
                      Expanded(
                        child: _buildStatCard(
                          'Items Recycled',
                          _plasticCounts.values.fold(0, (sum, count) => sum + count).toString(),
                          Icons.recycling_rounded,
                          AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recycling breakdown section
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Recycling Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Plastic type cards
                  _buildPlasticTypeCard('PET', _plasticCounts['PET'] ?? 0, '🥤'),
                  const SizedBox(height: 8),
                  _buildPlasticTypeCard('HDPE', _plasticCounts['HDPE'] ?? 0, '🧴'),
                  const SizedBox(height: 8),
                  _buildPlasticTypeCard('LDPE', _plasticCounts['LDPE'] ?? 0, '💼'),
                  const SizedBox(height: 8),
                  _buildPlasticTypeCard('PP', _plasticCounts['PP'] ?? 0, '🍶'),
                  const SizedBox(height: 8),
                  _buildPlasticTypeCard('PS', _plasticCounts['PS'] ?? 0, '🥡'),
                  
                  const SizedBox(height: 24),
                  
                  // Red logout button at the bottom
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutConfirmation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Logout"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
