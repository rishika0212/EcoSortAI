import 'package:flutter/material.dart';
import '/services/user_service.dart';
import '/utils/hexcolor.dart';
import '/services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/event_bus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  int totalPoints = 0;
  String badgeName = '🐣 Green Beginner';
  String badgeEmoji = '🐣';
  String badgeColorHex = '#D0F0C0';
  Map<String, int> scanCounts = {
    'PET': 0,
    'HDPE': 0,
    'LDPE': 0,
    'PP': 0,
    'PS': 0,
  };
  bool isLoading = true;
  Timer? _refreshTimer;
  StreamSubscription? _pointsSubscription;
  
  // Store previous badge to detect changes
  String _previousBadge = '🐣 Green Beginner';
  // Store previous scan counts to detect changes
  Map<String, int> _previousScanCounts = {
    'PET': 0,
    'HDPE': 0,
    'LDPE': 0,
    'PP': 0,
    'PS': 0,
  };
  
  // Track which plastic types were recently updated
  Map<String, bool> _recentlyUpdated = {
    'PET': false,
    'HDPE': false,
    'LDPE': false,
    'PP': false,
    'PS': false,
  };
  
  // Timer to reset the recently updated indicators
  Timer? _highlightTimer;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    print("PointsScreen: initState called");
    
    // Set loading state
    setState(() {
      isLoading = true;
    });
    
    // Load local data immediately
    _loadLocalData();
    
    // Force refresh from server after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        print("PointsScreen: Forcing initial refresh");
        fetchUserStats();
      }
    });
    
    // Set up a periodic refresh every 30 seconds (reduced frequency to improve performance)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        print("PointsScreen: Timer tick ${timer.tick}");
        fetchUserStats();
      }
    });
    
    // Subscribe to points update events
    _pointsSubscription = EventBus().onPointsUpdated.listen((points) {
      print("PointsScreen: Received points update event with $points points");
      if (mounted) {
        print("PointsScreen: Updating UI with new points: $points");
        setState(() {
          totalPoints = points;
          isLoading = false; // Ensure we're not stuck in loading state
        });
        
        // Force refresh to get updated scan counts and badge
        print("PointsScreen: Forcing refresh after points update event");
        
        // Add a small delay before fetching to ensure the server has processed the update
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            // Use fetchUserStats to ensure complete refresh
            fetchUserStats();
          }
        });
      } else {
        print("PointsScreen: Not mounted, can't update UI with points: $points");
      }
    });
  }
  
  // Load data from local storage
  Future<void> _loadLocalData() async {
    try {
      print("PointsScreen: Loading local data");
      
      // Get points from LocalStorageService
      final localPoints = await LocalStorageService.getPoints();
      print("PointsScreen: Local points: $localPoints");
      
      // Get plastic counts from LocalStorageService
      final localCounts = await LocalStorageService.getPlasticCounts();
      print("PointsScreen: Local counts: $localCounts");
      
      // Get badge info from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final localBadgeName = prefs.getString('badge_name') ?? '🐣 Green Beginner';
      final localBadgeColor = prefs.getString('badge_color') ?? '#D0F0C0';
      
      if (mounted) {
        setState(() {
          totalPoints = localPoints;
          scanCounts = Map.from(localCounts);
          badgeName = localBadgeName;
          badgeEmoji = _extractEmoji(localBadgeName);
          badgeColorHex = localBadgeColor;
          isLoading = false;
        });
      }
      
      print("PointsScreen: Loaded local data - Points: $localPoints, Badge: $localBadgeName");
      print("PointsScreen: Loaded local counts: $localCounts");
      
      // Initialize previous values
      _previousBadge = localBadgeName;
      _previousScanCounts = Map.from(localCounts);
      
      // Don't emit an event here to avoid potential circular updates
      // EventBus().emitPointsUpdated(localPoints);
    } catch (e) {
      print("PointsScreen: Error loading local data: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    print("PointsScreen: dispose called");
    _refreshTimer?.cancel();
    _highlightTimer?.cancel();
    _pointsSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("PointsScreen: App resumed, refreshing data");
      // Use fetchUserStats for a complete refresh
      fetchUserStats();
    }
  }

  // This will be called when the screen becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("PointsScreen: Dependencies changed, refreshing data");
    // Use fetchUserStats for a complete refresh
    fetchUserStats();
  }

  Future<void> fetchUserStats() async {
    if (!mounted) return;
    
    print("PointsScreen: fetchUserStats called");
    
    // Set loading state to true to show loading indicator
    setState(() {
      isLoading = true;
    });
    
    // Add a small delay to ensure loading indicator is shown
    await Future.delayed(const Duration(milliseconds: 100));
    
    // First get local points and scan counts to show immediately
    try {
      final localPoints = await LocalStorageService.getPoints();
      final localCounts = await LocalStorageService.getPlasticCounts();
      
      // Get badge info from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final localBadgeName = prefs.getString('badge_name') ?? '🐣 Green Beginner';
      final localBadgeColor = prefs.getString('badge_color') ?? '#D0F0C0';
      
      if (mounted) {
        setState(() {
          totalPoints = localPoints;
          scanCounts = Map.from(localCounts); // Create a new map to ensure UI updates
          badgeName = localBadgeName;
          badgeEmoji = _extractEmoji(localBadgeName);
          badgeColorHex = localBadgeColor;
          // Keep isLoading true until we get server data
        });
      }
      
      print("PointsScreen: Loaded local data - Points: $localPoints, Badge: $localBadgeName, Counts: $localCounts");
    } catch (e) {
      print("PointsScreen: Error getting local data: $e");
      // Don't set isLoading to false yet, we'll still try to get server data
    }
    
    // Check if user is logged in before trying to fetch from server
    final isLoggedIn = await AuthService().isLoggedIn();
    if (!isLoggedIn) {
      print("PointsScreen: User is not logged in, skipping server refresh");
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }
    
    // Then refresh from server
    try {
      // Get fresh data from server
      final response = await UserService().getUserProfile();
      print("PointsScreen: getUserProfile response: $response");

      if (mounted && response['success']) {
        final data = response['data'];
        print("PointsScreen: Processing data from server: $data");
        
        // Update local storage with latest points
        final serverPoints = data['points'] ?? 0;
        await LocalStorageService.savePoints(serverPoints);
        
        // Get badge info
        final String newBadgeName = data['badge'] ?? '🐣 Green Beginner';
        final String newBadgeColor = data['badge_color'] ?? '#D0F0C0';
        
        // Save badge info to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('badge_name', newBadgeName);
        await prefs.setString('badge_color', newBadgeColor);
        
        // Get scan counts
        final Map<String, int> newScanCounts = {
          'PET': data['pet_count'] ?? 0,
          'HDPE': data['hdpe_count'] ?? 0,
          'LDPE': data['ldpe_count'] ?? 0,
          'PP': data['pp_count'] ?? 0,
          'PS': data['ps_count'] ?? 0,
        };
        
        // Save the updated scan counts
        await LocalStorageService.savePlasticCounts(newScanCounts);
        
        // Store the last update time
        await prefs.setInt('last_profile_update', DateTime.now().millisecondsSinceEpoch);
        
        if (mounted) {
          // Always update state with the latest data from server
          setState(() {
            totalPoints = serverPoints;
            badgeName = newBadgeName;
            badgeEmoji = _extractEmoji(badgeName);
            badgeColorHex = newBadgeColor;
            scanCounts = Map.from(newScanCounts); // Create a new map to ensure UI updates
            isLoading = false;
          });
          
          print("PointsScreen: Updated from server - Points: $serverPoints, Badge: $newBadgeName");
          
          // Check if badge has changed
          if (_previousBadge != newBadgeName) {
            _showBadgeEarnedDialog(newBadgeName);
            _previousBadge = newBadgeName;
          }
          
          // Check if any scan count has increased
          bool anyCountUpdated = false;
          
          for (final entry in newScanCounts.entries) {
            final String plasticType = entry.key;
            final int newCount = entry.value;
            final int oldCount = _previousScanCounts[plasticType] ?? 0;
            
            if (newCount > oldCount) {
              // Mark this plastic type as recently updated
              _recentlyUpdated[plasticType] = true;
              anyCountUpdated = true;
              print("PointsScreen: $plasticType count increased from $oldCount to $newCount");
              
              // If count increased and reached a multiple of 10, show material badge earned
              if (newCount % 10 == 0 && newCount > 0) {
                final String badgeLabel = _getMaterialBadgeLabel(plasticType);
                _showMaterialBadgeEarnedDialog(badgeLabel);
              }
            }
          }
          
          // If any count was updated, start a timer to reset the highlights
          if (anyCountUpdated) {
            // Cancel existing timer if there is one
            _highlightTimer?.cancel();
            
            // Set a new timer to clear the highlights after 3 seconds
            _highlightTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  for (final key in _recentlyUpdated.keys) {
                    _recentlyUpdated[key] = false;
                  }
                });
              }
            });
          }
          
          // Update previous scan counts
          _previousScanCounts = Map.from(newScanCounts);
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          print("PointsScreen: Failed to fetch user data: ${response['message']}");
        }
      }
    } catch (e) {
      print("PointsScreen: Error fetching user stats: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  
  // Get the badge label for a material type
  String _getMaterialBadgeLabel(String plasticType) {
    return _getBadgeLabels()[plasticType] ?? 'Badge';
  }
  
  // Centralized method for badge labels to avoid duplication
  Map<String, String> _getBadgeLabels() {
    return {
      'PET': '🧴 PET Pro',
      'HDPE': '🚰 HDPE Hero',
      'LDPE': '📦 LDPE Legend',
      'PP': '🍱 PP Pioneer',
      'PS': '☕ PS Slayer',
    };
  }
  
  // Show a dialog when a new badge is earned
  void _showBadgeEarnedDialog(String badge) {
    if (!mounted) return;
    
    final emoji = _extractEmoji(badge);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Container(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'New Badge Earned!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Congratulations! You\'ve earned:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      badge.substring(badge.indexOf(' ') + 1),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Keep recycling to earn more badges!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    });
  }
  
  // Show a dialog when a material badge is earned
  void _showMaterialBadgeEarnedDialog(String badge) {
    if (!mounted) return;
    
    final emoji = _extractEmoji(badge);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Container(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Material Badge Earned!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Congratulations! You\'ve earned:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      badge.substring(badge.indexOf(' ') + 1),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'You\'ve reached the recycling goal for this material!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _extractEmoji(String text) {
    if (text.isEmpty) return '🏆';
    
    // Map of known badge names to emojis to ensure consistent display
    final Map<String, String> knownEmojis = {
      // Material badges
      'PET Pro': '🧴',
      'HDPE Hero': '🚰',
      'LDPE Legend': '📦',
      'PP Pioneer': '🍱',
      'PS Slayer': '☕',
      
      // Point-based badges
      'Green Beginner': '🐣',
      'Bin Rookie': '🔄',
      'Plastic Pro': '🧴',
      'Environment Hero': '🚰',
      'Nature Legend': '📦',
      'Green Guardian': '🍱',
      'Trash Transformer': '☕',
      'Sort Scout': '🔍',
      'Precision Recycler': '🎯',
      'Eco Explorer': '🌱',
      'Sort Sensei': '🧠',
      'Streak Saver': '🔥',
      'Plastic Defender': '🛡️',
      'Eco Royalty': '👑',
      'Guardian of Green': '🛰️',
      'Planet Protector': '🚀',
    };
    
    // First try: direct extraction of emoji from the beginning of the text
    if (text.isNotEmpty) {
      // This regex matches emoji characters at the start of the string
      // More comprehensive regex to match emoji sequences
      final emojiMatch = RegExp(r'^([\p{Emoji}\u{FE0F}\u{1F3FB}-\u{1F3FF}]+)', unicode: true).firstMatch(text);
      if (emojiMatch != null && emojiMatch.group(0) != null) {
        return emojiMatch.group(0)!;
      }
    }
    
    // Second try: check if this is a known badge name
    for (final entry in knownEmojis.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Third try: extract the first character if it's an emoji
    if (text.isNotEmpty) {
      final firstChar = text.characters.first;
      // Check if the first character is likely an emoji
      if (firstChar.length > 1 || firstChar.codeUnitAt(0) > 127) {
        return firstChar;
      }
    }
    
    // Fourth try: extract the first word if it contains non-ASCII characters
    if (text.contains(' ')) {
      final firstPart = text.split(' ')[0].trim();
      if (firstPart.isNotEmpty && firstPart.codeUnits.any((c) => c > 127)) {
        return firstPart;
      }
    }
    
    // Default emoji if nothing else works
    return '🏆';
  }

  Widget _circleStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _badgeProgress(String label, int current, int goal, Color color) {
    // Extract plastic type from the badge label more reliably
    String plasticType = '';
    
    // Common plastic types to look for in the label
    final plasticTypes = ['PET', 'HDPE', 'LDPE', 'PP', 'PS'];
    
    // Find which plastic type is in the label
    for (final type in plasticTypes) {
      if (label.contains(type)) {
        plasticType = type;
        break;
      }
    }
    
    // Fallback if no type was found
    if (plasticType.isEmpty) {
      plasticType = label.split(' ').last.replaceAll(RegExp(r'[^A-Z]'), '');
    }
    
    // Check if this plastic type was recently updated
    final bool isUpdated = _recentlyUpdated[plasticType] ?? false;
    
    // Calculate progress percentage
    final double percent = (current / goal).clamp(0, 1);
    final bool isComplete = percent >= 1;
    
    print("Badge Progress: $label - Current: $current, Goal: $goal, Updated: $isUpdated");
    
    return ListTile(
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isUpdated ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isComplete ? Icons.emoji_events : Icons.emoji_events_outlined, 
          color: isComplete ? Colors.green : (isUpdated ? Colors.amber : Colors.grey),
          size: 28,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              label, 
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUpdated) 
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Updated',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isComplete 
              ? 'Badge earned! ($current/$goal items)' 
              : 'Scan ${goal - current} more items to earn this badge',
            style: TextStyle(
              color: isComplete ? Colors.green : (isUpdated ? Colors.amber.shade800 : null),
              fontWeight: isComplete ? FontWeight.w500 : null,
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              // Background progress bar
              LinearProgressIndicator(
                value: 1.0, 
                backgroundColor: Colors.grey[300],
                color: Colors.grey[300],
                minHeight: 10,
              ),
              // Animated progress bar
              TweenAnimationBuilder<double>(
                key: ValueKey('progress-$plasticType-$current'), // Force rebuild when count changes
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(
                  begin: 0,
                  end: percent,
                ),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value, 
                    color: isComplete ? Colors.green : (isUpdated ? Colors.amber : color), 
                    backgroundColor: Colors.transparent,
                    minHeight: 10,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isComplete 
            ? Colors.green.withOpacity(0.2) 
            : (isUpdated ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$current/$goal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isComplete 
              ? Colors.green 
              : (isUpdated ? Colors.amber.shade800 : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final themeColor = HexColor(badgeColorHex);
    final totalItems = scanCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: themeColor.withOpacity(0.1),
      appBar: AppBar(
        title: const Text('Points'),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print("PointsScreen: Manual refresh button pressed");
              fetchUserStats();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUserStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          badgeEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Eco Impact',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _circleStat('Points', '$totalPoints', themeColor),
                        _circleStat('Items Recycled', '$totalItems', themeColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Show breakdown of recycled items
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.recycling, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Recycling Breakdown',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Use a Wrap widget to prevent overflow
                            Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              spacing: 8, // horizontal spacing
                              runSpacing: 8, // vertical spacing
                              children: scanCounts.entries.map((entry) {
                                final bool isUpdated = _recentlyUpdated[entry.key] ?? false;
                                return SizedBox(
                                  width: 65, // Fixed width to ensure consistent sizing
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: entry.value.toDouble(),
                                    ),
                                    builder: (context, value, child) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isUpdated ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: isUpdated 
                                            ? Border.all(color: Colors.green, width: 2) 
                                            : null,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${value.round()}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isUpdated ? Colors.green : null,
                                                  ),
                                                ),
                                                if (isUpdated) 
                                                  const Icon(
                                                    Icons.arrow_upward, 
                                                    color: Colors.green, 
                                                    size: 14,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                entry.key,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isUpdated ? Colors.green : Colors.grey[700],
                                                  fontWeight: isUpdated ? FontWeight.bold : null,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // Total items count with animation
                            Center(
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(
                                  begin: 0,
                                  end: totalItems.toDouble(),
                                ),
                                builder: (context, value, child) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Total: ${value.round()} items',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              badgeEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Current Badge: ${badgeName.substring(badgeName.indexOf(' ') + 1)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.emoji_events, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  'Material Badges',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...scanCounts.entries.map((entry) {
                              final labels = _getBadgeLabels();
                              final bool isUpdated = _recentlyUpdated[entry.key] ?? false;
                              
                              // Use a key to force rebuild when count changes
                              return KeyedSubtree(
                                key: ValueKey('badge-${entry.key}-${entry.value}'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isUpdated ? themeColor.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _badgeProgress(labels[entry.key] ?? '${entry.key} Badge', entry.value, 10, themeColor),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
