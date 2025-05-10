import 'package:flutter/material.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../utils/hexcolor.dart';
import '../services/event_bus.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _refreshTimer;
  StreamSubscription? _leaderboardSubscription;
  
  @override
  bool get wantKeepAlive => true;
  
  // Debug counter to track rebuilds
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    print("LeaderboardScreen: initState called");
    
    // Add a debug user immediately for testing
    setState(() {
      _leaderboardData.add({
        'rank': 1,
        'username': 'Debug User',
        'points': 100,
        'badge': '🐣 Green Beginner',
        'badge_color': '#D0F0C0',
        'total_items_recycled': 5,
        'is_current_user': true,
      });
      _isLoading = false;
    });
    print("LeaderboardScreen: Added initial debug user");
    
    // Fetch leaderboard data immediately
    _fetchLeaderboardData();
    
    // Set up a periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        print("LeaderboardScreen: Timer tick ${timer.tick}");
        _fetchLeaderboardData();
      }
    });
    
    // Subscribe to leaderboard update events
    _leaderboardSubscription = EventBus().onLeaderboardUpdated.listen((_) {
      print("LeaderboardScreen: Received leaderboard update event");
      if (mounted) {
        // Add a small delay to ensure server has processed any updates
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _fetchLeaderboardData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print("LeaderboardScreen: dispose called");
    _refreshTimer?.cancel();
    _leaderboardSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLeaderboardData() async {
    if (!mounted) return;
    
    print("LeaderboardScreen: Fetching leaderboard data");
    
    // Only show loading indicator on first load
    if (_leaderboardData.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    
    try {
      print("LeaderboardScreen: Calling UserService().getLeaderboard()");
      final response = await UserService().getLeaderboard();
      print("LeaderboardScreen: Got response: $response");
      
      if (mounted) {
        if (response['success']) {
          print("LeaderboardScreen: Success response with data: ${response['data']}");
          
          try {
            final data = response['data'] as List;
            
            // Convert each item to a Map<String, dynamic>
            final List<Map<String, dynamic>> typedData = [];
            for (var item in data) {
              if (item is Map) {
                // Convert to Map<String, dynamic>
                final Map<String, dynamic> typedItem = {};
                item.forEach((key, value) {
                  typedItem[key.toString()] = value;
                });
                typedData.add(typedItem);
              }
            }
            
            setState(() {
              _leaderboardData = typedData;
              _isLoading = false;
              _errorMessage = '';
            });
            print("LeaderboardScreen: Loaded ${_leaderboardData.length} users");
            
            // Debug print each user
            for (var user in _leaderboardData) {
              print("LeaderboardScreen: User: ${user['username']}, points: ${user['points']}, rank: ${user['rank']}");
            }
          } catch (e) {
            print("LeaderboardScreen: Error processing data: $e");
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error processing leaderboard data: $e';
            });
          }
        } else {
          print("LeaderboardScreen: Failed response with message: ${response['message']}");
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] ?? 'Failed to load leaderboard';
          });
          print("LeaderboardScreen: Error: $_errorMessage");
        }
      }
    } catch (e) {
      print("LeaderboardScreen: Exception caught: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
      print("LeaderboardScreen: Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    _buildCount++;
    print("LeaderboardScreen: build #$_buildCount called, isLoading: $_isLoading, errorMessage: '$_errorMessage', data length: ${_leaderboardData.length}");
    
    // Force a refresh if we've built the screen but have no data and no error
    if (_buildCount > 1 && !_isLoading && _errorMessage.isEmpty && _leaderboardData.isEmpty) {
      print("LeaderboardScreen: No data after build, forcing refresh");
      // Use a post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchLeaderboardData();
        }
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Eco Champions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchLeaderboardData,
            tooltip: 'Refresh Leaderboard',
          ),
          // Debug button to add a fake user
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () {
              setState(() {
                _leaderboardData.add({
                  'rank': _leaderboardData.length + 1,
                  'username': 'Debug User ${_leaderboardData.length + 1}',
                  'points': 100 - _leaderboardData.length * 10,
                  'badge': '🐣 Green Beginner',
                  'badge_color': '#D0F0C0',
                  'total_items_recycled': 5,
                  'is_current_user': false,
                });
              });
              print("LeaderboardScreen: Added debug user, now have ${_leaderboardData.length} users");
            },
            tooltip: 'Add Debug User',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade100,
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    print("LeaderboardScreen: _buildContent called, isLoading: $_isLoading, errorMessage: '$_errorMessage', data length: ${_leaderboardData.length}");
    
    if (_isLoading) {
      print("LeaderboardScreen: Showing loading indicator");
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      print("LeaderboardScreen: Showing error message: $_errorMessage");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLeaderboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    if (_leaderboardData.isEmpty) {
      print("LeaderboardScreen: No users found");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No users found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLeaderboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    print("LeaderboardScreen: Showing leaderboard with ${_leaderboardData.length} users");
    return Column(
      children: [
        _buildLeaderboardHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchLeaderboardData,
            color: Colors.green.shade700,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _leaderboardData.length,
              itemBuilder: (context, index) {
                final user = _leaderboardData[index];
                return _buildLeaderboardItem(user, index);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLeaderboardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          const Text(
            '🌍 Global Leaderboard 🌍',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recycling Champions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (_leaderboardData.isNotEmpty)
            _buildTopThree(),
        ],
      ),
    );
  }
  
  Widget _buildTopThree() {
    print("LeaderboardScreen: Building top three with ${_leaderboardData.length} users");
    
    // Handle cases with fewer than 3 users
    if (_leaderboardData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (if available)
          if (_leaderboardData.length >= 2)
            _buildTopUserAvatar(
              _leaderboardData[1],
              size: 80,
              rank: 2,
              borderColor: Colors.grey.shade300,
            )
          else
            const SizedBox(width: 80),
          
          const SizedBox(width: 8),
          
          // 1st Place (always available if we have at least one user)
          _buildTopUserAvatar(
            _leaderboardData[0],
            size: 100,
            rank: 1,
            borderColor: Colors.amber,
          ),
          
          const SizedBox(width: 8),
          
          // 3rd Place (if available)
          if (_leaderboardData.length >= 3)
            _buildTopUserAvatar(
              _leaderboardData[2],
              size: 70,
              rank: 3,
              borderColor: Colors.brown.shade300,
            )
          else
            const SizedBox(width: 70),
        ],
      ),
    );
  }
  
  Widget _buildTopUserAvatar(Map<String, dynamic> user, {
    required double size,
    required int rank,
    required Color borderColor,
  }) {
    print("LeaderboardScreen: Building top user avatar for rank $rank: $user");
    
    // Extract values with safe fallbacks
    final String badge = user['badge']?.toString() ?? '🐣 Green Beginner';
    final String badgeEmoji = _extractEmoji(badge);
    
    final dynamic isCurrentUserValue = user['is_current_user'];
    final bool isCurrentUser = (isCurrentUserValue is bool) ? isCurrentUserValue : false;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Badge background
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HexColor(user['badge_color']?.toString() ?? '#D0F0C0'),
                border: Border.all(
                  color: borderColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            // Badge emoji
            Text(
              badgeEmoji,
              style: TextStyle(
                fontSize: size * 0.5,
              ),
            ),
            // Rank indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getRankColor(rank),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.18,
                    ),
                  ),
                ),
              ),
            ),
            // Current user indicator
            if (isCurrentUser)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Username
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.green.shade700 : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user['username'] ?? 'User',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Points
        Text(
          '${user['points'] ?? 0} pts',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLeaderboardItem(Map<String, dynamic> user, int index) {
    print("LeaderboardScreen: Building item for user: $user");
    
    // Extract values with safe fallbacks
    final dynamic rankValue = user['rank'];
    final int rank = (rankValue is int) ? rankValue : (index + 1);
    
    final String username = user['username']?.toString() ?? 'User';
    
    final dynamic pointsValue = user['points'];
    final int points = (pointsValue is int) ? pointsValue : 0;
    
    final String badge = user['badge']?.toString() ?? '🐣 Green Beginner';
    final String badgeColor = user['badge_color']?.toString() ?? '#D0F0C0';
    
    final dynamic isCurrentUserValue = user['is_current_user'];
    final bool isCurrentUser = (isCurrentUserValue is bool) ? isCurrentUserValue : false;
    
    final String badgeEmoji = _extractEmoji(badge);
    
    print("LeaderboardScreen: Processed user - rank: $rank, username: $username, points: $points");
    
    // Skip the top 3 users as they're displayed separately
    if (rank <= 3) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.green.shade50.withOpacity(0.9)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isCurrentUser
            ? Border.all(color: Colors.green.shade700, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            // Rank container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRankColor(rank),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isCurrentUser)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          username,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Total Items: ${user['total_items_recycled'] ?? 0}',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HexColor(badgeColor.toString()),
              ),
              child: Text(
                badgeEmoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$points pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade300;
    return Colors.green.shade700;
  }
  
  String _extractEmoji(String badgeName) {
    // Extract the emoji from the badge name (assuming it's the first character)
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
}