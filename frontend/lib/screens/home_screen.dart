import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../screens/education_screen.dart';
import '../screens/points_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../services/local_storage_service.dart';
import '../services/user_service.dart';
import '../services/event_bus.dart';
import '../services/auth_service.dart';
import '../widgets/batch_goal_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String initialUsername;
  final int initialPoints;
  
  const HomeScreen({
    super.key, 
    this.initialUsername = 'User',
    this.initialPoints = 0
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late String _username;
  late int _points;

  @override
  void initState() {
    super.initState();
    print("HomeScreen: initState called with initialUsername: ${widget.initialUsername}, initialPoints: ${widget.initialPoints}");
    _username = widget.initialUsername;
    _points = widget.initialPoints;
    
    // Load user data immediately to ensure we have the latest data
    _loadUserData();
    
    // Listen for points updates
    EventBus().listenToPointsUpdated((points) {
      print("HomeScreen: Received points update event with points: $points");
      if (mounted) {
        setState(() {
          _points = points;
        });
      }
    });
  }
  
  @override
  void dispose() {
    // Remove event listeners
    EventBus().offPointsUpdated();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print("HomeScreen: Loading user data");
    
    try {
      // First refresh from server to ensure we have the latest data
      print("HomeScreen: Refreshing user data from server");
      await AuthService().refreshUserData();
      
      // Then load from local storage
      final username = await LocalStorageService.getUsername();
      final points = await LocalStorageService.getPoints();
      
      if (mounted) {
        setState(() {
          _username = username ?? _username;
          _points = points;
        });
        print("HomeScreen: Updated with fresh data - username: $_username, points: $_points");
      }
    } catch (e) {
      print("HomeScreen: Error refreshing user data: $e");
      
      // Fallback to local storage if server refresh fails
      final username = await LocalStorageService.getUsername();
      final points = await LocalStorageService.getPoints();
      
      if (mounted) {
        setState(() {
          _username = username ?? _username;
          _points = points;
        });
        print("HomeScreen: Updated with local data - username: $_username, points: $_points");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeContent(username: _username, initialPoints: _points),
      EducationScreen(),
      const PointsScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print("HomeScreen: Tab changed from $_currentIndex to $index");
          // If we're switching to the Points tab, refresh user data
          if (index == 2 && _currentIndex != 2) {
            _loadUserData();
          }
          // If we're switching to the Leaderboard tab, emit a leaderboard update event
          if (index == 3 && _currentIndex != 3) {
            print("HomeScreen: Emitting leaderboard update event");
            EventBus().emitLeaderboardUpdated();
          }
          setState(() => _currentIndex = index);
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Required for more than 4 items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Education'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String username;
  final int initialPoints;
  
  const HomeContent({
    super.key, 
    required this.username,
    this.initialPoints = 0
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _predictedLabel;
  double? _confidence;
  bool _showResult = false;
  bool _isLoading = false;
  Map<String, dynamic> _extraInfo = {};
  late int _points;
  
  // Batch tracking - counts for the current session/batch
  final Map<String, int> _batchCounts = {
    'PET': 0,
    'HDPE': 0,
    'LDPE': 0,
    'PP': 0,
    'PS': 0,
  };
  
  // Batch goals - when these counts are reached, show the congratulatory message
  final Map<String, int> _batchGoals = {
    'PET': 10,
    'HDPE': 10,
    'LDPE': 10,
    'PP': 10,
    'PS': 10,
  };
  
  // Track which batch goals have been reached to avoid showing the dialog multiple times
  final Map<String, bool> _batchGoalsReached = {
    'PET': false,
    'HDPE': false,
    'LDPE': false,
    'PP': false,
    'PS': false,
  };

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _points = widget.initialPoints;
    _loadPoints();
    _resetBatchCountsIfNeeded();
    
    // Listen for points updates
    EventBus().listenToPointsUpdated((points) {
      print("HomeContent: Received points update event with points: $points");
      if (mounted) {
        setState(() {
          _points = points;
        });
      }
    }, this);
  }
  
  @override
  void dispose() {
    // Remove event listeners
    EventBus().offPointsUpdated(this);
    super.dispose();
  }
  
  // Reset batch counts if it's a new day or if they haven't been initialized yet
  Future<void> _resetBatchCountsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBatchReset = prefs.getInt('last_batch_reset') ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    
    // If it's a new day or if batch counts haven't been initialized yet, reset them
    if (lastBatchReset < today) {
      print("HomeScreen: Resetting batch counts for a new day");
      
      // Reset batch counts
      for (final key in _batchCounts.keys) {
        _batchCounts[key] = 0;
      }
      
      // Reset batch goals reached flags
      for (final key in _batchGoalsReached.keys) {
        _batchGoalsReached[key] = false;
        await prefs.setBool('batch_goal_reached_${key.toLowerCase()}', false);
      }
      
      // Save the reset time
      await prefs.setInt('last_batch_reset', today);
      
      // Save the batch counts
      await _saveBatchCounts();
    } else {
      // Load saved batch counts
      await _loadBatchCounts();
    }
  }
  
  // Save batch counts to SharedPreferences
  Future<void> _saveBatchCounts() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _batchCounts.entries) {
      await prefs.setInt('batch_${entry.key.toLowerCase()}', entry.value);
    }
    print("HomeScreen: Saved batch counts: $_batchCounts");
  }
  
  // Load batch counts from SharedPreferences
  Future<void> _loadBatchCounts() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _batchCounts.keys) {
      // Load the batch count
      _batchCounts[key] = prefs.getInt('batch_${key.toLowerCase()}') ?? 0;
      
      // Load the batch goal reached status
      _batchGoalsReached[key] = prefs.getBool('batch_goal_reached_${key.toLowerCase()}') ?? false;
      
      // Double-check if any batch goals have been reached but not marked
      if (_batchCounts[key]! >= _batchGoals[key]! && !_batchGoalsReached[key]!) {
        _batchGoalsReached[key] = true;
        await prefs.setBool('batch_goal_reached_${key.toLowerCase()}', true);
      }
    }
    print("HomeScreen: Loaded batch counts: $_batchCounts");
    print("HomeScreen: Batch goals reached status: $_batchGoalsReached");
  }

  Future<String?> _getToken() async {
    return LocalStorageService.getToken();
  }

  Future<void> _loadPoints() async {
    try {
      // First try to refresh from server
      print("HomeContent: Refreshing points from server");
      try {
        await AuthService().refreshUserData();
        print("HomeContent: Successfully refreshed user data from server");
      } catch (e) {
        print("HomeContent: Error refreshing from server, will use local data: $e");
      }
      
      // Then load from local storage
      final points = await LocalStorageService.getPoints();
      print("HomeContent: Loaded points = $points");
      
      if (mounted) {
        setState(() {
          _points = points;
        });
      }
    } catch (e) {
      print("HomeContent: Error loading points: $e");
    }
  }

  Future<void> _updatePoints(int increment) async {
    try {
      // Update points on the server first
      final plasticType = _predictedLabel ?? 'unknown';
      print("HomeScreen: Sending update to server - Points: $increment, Type: $plasticType");
      
      // We'll only increment the plastic count locally for immediate feedback
      // but we'll wait for the server to update the points to avoid double-counting
      await LocalStorageService.incrementPlasticCount(plasticType);
      
      print("HomeScreen: Incremented local plastic count for $plasticType");
      
      // Update batch count for this plastic type if it's a valid type
      if (_batchCounts.containsKey(plasticType)) {
        // Increment the batch count
        _batchCounts[plasticType] = (_batchCounts[plasticType] ?? 0) + 1;
        await _saveBatchCounts();
        print("HomeScreen: Updated batch count for $plasticType to ${_batchCounts[plasticType]}");
        
        // Check if batch goal is reached and not already shown
        if (_batchCounts[plasticType]! >= _batchGoals[plasticType]! && !_batchGoalsReached[plasticType]!) {
          // Mark this goal as reached
          _batchGoalsReached[plasticType] = true;
          
          // Save the updated status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('batch_goal_reached_${plasticType.toLowerCase()}', true);
          
          print("HomeScreen: Batch goal reached for $plasticType with count ${_batchCounts[plasticType]}");
          
          // Show batch goal reached dialog immediately
          if (mounted) {
            _showBatchGoalReachedDialog(plasticType, _batchCounts[plasticType]!);
          }
        }
      }
      
      // Then send to server
      final result = await UserService().updatePoints(increment, plasticType);
      
      // Log the server response
      if (result['success']) {
        print("HomeScreen: Server update successful: ${result['data']}");
        
        // Get the updated points from the server response
        if (result['data'] != null && result['data']['points'] != null) {
          final serverPoints = result['data']['points'] as int;
          
          // Update points in LocalStorageService with server value
          await LocalStorageService.savePoints(serverPoints);
          
          // Also update in SharedPreferences for backward compatibility
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('points', serverPoints);
          
          // Get the previous points before updating
          final previousPoints = _points;
          
          // Update the UI with server value
          setState(() {
            _points = serverPoints;
          });
          
          // Emit an event to notify other screens
          EventBus().emitPointsUpdated(serverPoints);
          
          // Check if user has reached a new level badge
          _checkForLevelBadgeAchievement(previousPoints, serverPoints);
          
          print("HomeScreen: Updated points from server: $serverPoints and emitted event");
        } else {
          // Fallback to local update if server doesn't return points
          final currentPoints = await LocalStorageService.getPoints();
          final newPoints = currentPoints + increment;
          
          await LocalStorageService.savePoints(newPoints);
          
          // Also update in SharedPreferences for backward compatibility
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('points', newPoints);
          
          // Get the previous points before updating
          final previousPoints = _points;
          
          // Update the UI
          setState(() {
            _points = newPoints;
          });
          
          // Emit an event to notify other screens
          EventBus().emitPointsUpdated(newPoints);
          
          // Check if user has reached a new level badge
          _checkForLevelBadgeAchievement(previousPoints, newPoints);
          
          print("HomeScreen: Updated points locally: $newPoints and emitted event");
        }
      } else {
        print("Failed to update points on server: ${result['message']}");
        
        // Fallback to local update if server update fails
        final currentPoints = await LocalStorageService.getPoints();
        final newPoints = currentPoints + increment;
        
        await LocalStorageService.savePoints(newPoints);
        
        // Also update in SharedPreferences for backward compatibility
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('points', newPoints);
        
        // Update the UI
        setState(() {
          _points = newPoints;
        });
        
        // Emit an event to notify other screens
        EventBus().emitPointsUpdated(newPoints);
        
        print("HomeScreen: Updated points locally after server error: $newPoints and emitted event");
      }
    } catch (e) {
      print("Error updating points: $e");
    }
  }
  
  // Show a dialog when a batch goal is reached for a specific plastic type
  void _showBatchGoalReachedDialog(String plasticType, int batchCount) {
    if (!mounted) return;
    
    // Get the appropriate emoji for the plastic type
    final String emoji = _getEmojiForPlasticType(plasticType);
    
    // Get the plastic-specific badge name
    final String badgeName = _getBadgeNameForPlasticType(plasticType);
    
    // Define colors for plastic-specific badges (these could be moved to a constants file)
    final Map<String, String> plasticColors = {
      'PET': '#B2EBF2',  // Light cyan
      'HDPE': '#81D4FA', // Light blue
      'LDPE': '#E0E0E0', // Light grey
      'PP': '#FFF59D',   // Light yellow
      'PS': '#F8BBD0',   // Light pink
    };
    
    // Get the color for this plastic type or use a default
    final String badgeColor = plasticColors[plasticType] ?? '#FFD0F0'; // Default pink
    
    // Show the dialog
    showDialog(
      context: context,
      builder: (context) => BatchGoalDialog(
        plasticType: plasticType,
        batchCount: batchCount,
        badgeEmoji: emoji,
        badgeName: badgeName,
        badgeColor: badgeColor,
        isPlasticTypeBadge: true, // Indicate this is a plastic-specific badge
      ),
    );
  }
  
  // Show a dialog when a level badge is achieved
  void _showLevelBadgeAchievedDialog(int points) {
    if (!mounted) return;
    
    // Get the badge name and color for this level
    final (String badgeName, String badgeColor) = _getBadgeNameAndColorForLevel(points);
    
    // Extract the emoji from the badge name
    final String emoji = badgeName.split(' ')[0];
    
    // Show the dialog
    showDialog(
      context: context,
      builder: (context) => BatchGoalDialog(
        plasticType: '', // Not relevant for level badges
        batchCount: points,
        badgeEmoji: emoji,
        badgeName: badgeName,
        badgeColor: badgeColor, // Pass the badge color
        isPlasticTypeBadge: false, // Indicate this is a level badge
      ),
    );
  }
  
  // Get the appropriate badge name for a plastic type (plastic-specific badges)
  String _getBadgeNameForPlasticType(String plasticType) {
    final badges = {
      'PET': '🧴 PET Pro',
      'HDPE': '🚰 HDPE Hero',
      'LDPE': '📦 LDPE Legend',
      'PP': '🍱 PP Pioneer',
      'PS': '☕ PS Slayer',
    };
    return badges[plasticType] ?? '♻️ Recycling Champion';
  }
  
  // Get the badge name based on points (level-based badges)
  (String, String) _getBadgeNameAndColorForLevel(int points) {
    final levelBadges = [
      (1000, "🚀 Planet Protector", "#388E3C"),
      (900, "🛰️ Guardian of Green", "#66BB6A"),
      (800, "👑 Eco Royalty", "#FFD700"),
      (700, "🛡️ Plastic Defender", "#90CAF9"),
      (600, "🔥 Streak Saver", "#EF9A9A"),
      (500, "🧠 Sort Sensei", "#CE93D8"),
      (450, "🌱 Eco Explorer", "#AED581"),
      (400, "🎯 Precision Recycler", "#FFCC80"),
      (350, "🔍 Sort Scout", "#A7FFEB"),
      (300, "☕ PS Slayer", "#F8BBD0"),
      (250, "🍱 PP Pioneer", "#FFF59D"),
      (200, "📦 LDPE Legend", "#E0E0E0"),
      (150, "🚰 HDPE Hero", "#81D4FA"),
      (100, "🧴 PET Pro", "#B2EBF2"),
      (50, "🔄 Bin Rookie", "#E6FFCC"),
      (10, "🐣 Green Beginner", "#D0F0C0"),
    ];
    
    for (final badge in levelBadges) {
      if (points >= badge.$1) {
        return (badge.$2, badge.$3);
      }
    }
    
    return ("🐣 Green Beginner", "#D0F0C0");
  }
  
  // Check if the user has reached a new level badge
  void _checkForLevelBadgeAchievement(int previousPoints, int newPoints) {
    // Define the badge thresholds
    final thresholds = [10, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 600, 700, 800, 900, 1000];
    
    // Find the highest threshold that was crossed
    int? highestCrossedThreshold;
    
    for (final threshold in thresholds) {
      // Check if this threshold was crossed with this points update
      if (previousPoints < threshold && newPoints >= threshold) {
        highestCrossedThreshold = threshold;
      }
    }
    
    // If a threshold was crossed, show the level badge dialog
    if (highestCrossedThreshold != null) {
      print("HomeScreen: Level badge threshold crossed: $highestCrossedThreshold");
      _showLevelBadgeAchievedDialog(highestCrossedThreshold);
    }
  }
  
  // Get the appropriate emoji for a plastic type
  String _getEmojiForPlasticType(String plasticType) {
    final emojis = {
      'PET': '🧴',
      'HDPE': '🚰',
      'LDPE': '📦',
      'PP': '🍱',
      'PS': '☕',
    };
    return emojis[plasticType] ?? '♻️';
  }

  Future<void> _pickAndAnalyzeImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    print("HomeScreen: Starting image analysis, setting _isLoading = true");
    setState(() {
      _showResult = false;
      _isLoading = true;
    });

    // Use the same base URL as defined in UserService
    final uri = Uri.parse("${UserService.baseUrl}/ml/predict");
    final token = await _getToken();

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      print("HomeScreen: Sending image for analysis...");
      final response = await request.send();
      final res = await http.Response.fromStream(response);
      print("HomeScreen: Received response with status code: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final String plasticType = data['label'];
        print("HomeScreen: Analysis successful - Plastic type: $plasticType");
        
        setState(() {
          _predictedLabel = plasticType;
          _confidence = (data['confidence'] as num).toDouble();
          _extraInfo = data['info'] ?? {};
          _showResult = true;
          _isLoading = false; // Explicitly set loading to false here
          print("HomeScreen: Analysis complete, setting _isLoading = false");
        });
        
        // Add points for successful scan
        const pointsToAdd = 10;
        
        // Make sure we have the plastic type before updating points
        if (plasticType.isNotEmpty) {
          print("HomeScreen: Updating points with plastic type: $plasticType");
          
          // Update points on server first (this will also update local storage)
          await _updatePoints(pointsToAdd);
          
          // Mark this plastic type as recently updated
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_updated_plastic', plasticType);
          await prefs.setInt('last_update_time', DateTime.now().millisecondsSinceEpoch);
          
          // Show confirmation
          _showSnackBar("Great job! You've recycled a $plasticType item and earned $pointsToAdd points.");
          
          // Force refresh user data to ensure everything is in sync
          await UserService().getUserProfile().then((response) async {
            if (response['success']) {
              final data = response['data'];
              
              // Update points in local storage
              if (data['points'] != null) {
                await LocalStorageService.savePoints(data['points']);
              }
              
              // Update plastic counts in local storage
              final scanCounts = {
                'PET': (data['pet_count'] ?? 0) as int,
                'HDPE': (data['hdpe_count'] ?? 0) as int,
                'LDPE': (data['ldpe_count'] ?? 0) as int,
                'PP': (data['pp_count'] ?? 0) as int,
                'PS': (data['ps_count'] ?? 0) as int,
              };
              
              await LocalStorageService.savePlasticCounts(scanCounts);
              print("HomeScreen: Updated scan counts from server: $scanCounts");
            }
          });
        } else {
          await _updatePoints(pointsToAdd);
          _showSnackBar("Great job! You've earned $pointsToAdd points.");
        }
        
        print("HomeScreen: Added $pointsToAdd points, new total: $_points");
      } else {
        print("HomeScreen: Prediction failed with status code: ${res.statusCode}");
        _showSnackBar("Prediction failed: ${res.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("HomeScreen: Error during image analysis: $e");
      _showSnackBar("Error: $e");
      setState(() => _isLoading = false);
    } finally {
      // Double-check that loading state is reset
      print("HomeScreen: In finally block, _isLoading = $_isLoading");
      if (_isLoading) {
        print("HomeScreen: Forcing loading state to false in finally block");
        setState(() {
          _isLoading = false;
          print("HomeScreen: Set _isLoading = false in finally block");
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAnalysisResult() {
    if (!_showResult || _predictedLabel == null || _confidence == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text("Analysis Result", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("Item Type", _predictedLabel!),
            _infoRow("Confidence", "${(_confidence! * 100).toStringAsFixed(1)}%"),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _confidence!,
                color: Colors.green,
                backgroundColor: Colors.grey.shade300,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            if (_extraInfo.isNotEmpty) ...[
              if (_extraInfo['found_in'] != null)
                _infoRow("Commonly Found In", _extraInfo['found_in']),
              if (_extraInfo['recyclable'] != null)
                _infoRow("Recyclable", _extraInfo['recyclable'].toString()),
              if (_extraInfo['what_to_do'] != null)
                _infoRow("Disposal Instructions", _extraInfo['what_to_do']),
              if (_extraInfo['impact'] != null)
                _infoRow("Environmental Impact", _extraInfo['impact']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: "$title: ",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                children: [TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("EcoSortAI"),
            backgroundColor: Colors.green.shade700,
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(30)),
                child: Text("$_points pts", style: const TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Hi, ${widget.username}!", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Welcome to EcoSortAI", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FeatureIcon(icon: Icons.camera_alt, label: "Snap"),
                  _FeatureIcon(icon: Icons.auto_fix_high, label: "Analyze"),
                  _FeatureIcon(icon: Icons.recycling, label: "Recycle"),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(onTap: _pickAndAnalyzeImage, child: const DottedBorderBox()),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickAndAnalyzeImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: const Text("Analyze Image"),
              ),
              _buildAnalysisResult(),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green), strokeWidth: 6.0),
                  SizedBox(height: 16),
                  Text("Analyzing...", style: TextStyle(color: Color.fromARGB(221, 2, 96, 5), fontSize: 18)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: Colors.green.shade100, child: Icon(icon, color: Colors.green)),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, style: BorderStyle.solid, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 40, color: Colors.green),
            SizedBox(height: 8),
            Text("Take a photo or select from gallery"),
          ],
        ),
      ),
    );
  }
}
