import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../screens/education_screen.dart';
import '../screens/points_screen.dart';
import '../screens/profile_screen.dart';
import '../services/local_storage_service.dart';
import '../services/user_service.dart';
import '../services/event_bus.dart';

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
    _username = widget.initialUsername;
    _points = widget.initialPoints;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load from local storage to ensure we have the latest data
    final username = await LocalStorageService.getUsername();
    final points = await LocalStorageService.getPoints();
    
    setState(() {
      _username = username ?? _username;
      _points = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeContent(username: _username, initialPoints: _points),
      EducationScreen(),
      const PointsScreen(),
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
          // If we're switching to the Points tab, refresh user data
          if (index == 2 && _currentIndex != 2) {
            _loadUserData();
          }
          setState(() => _currentIndex = index);
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Education'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Points'),
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

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _points = widget.initialPoints;
    _loadPoints();
  }

  Future<String?> _getToken() async {
    return LocalStorageService.getToken();
  }

  Future<void> _loadPoints() async {
    try {
      final points = await LocalStorageService.getPoints();
      print("HomeScreen: Loaded points = $points");
      setState(() {
        _points = points;
      });
    } catch (e) {
      print("HomeScreen: Error loading points: $e");
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
          
          // Update the UI with server value
          setState(() {
            _points = serverPoints;
          });
          
          // Emit an event to notify other screens
          EventBus().emitPointsUpdated(serverPoints);
          
          print("HomeScreen: Updated points from server: $serverPoints and emitted event");
        } else {
          // Fallback to local update if server doesn't return points
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

  Future<void> _pickAndAnalyzeImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    print("HomeScreen: Starting image analysis, setting _isLoading = true");
    setState(() {
      _showResult = false;
      _isLoading = true;
    });

    final uri = Uri.parse("http://192.168.1.222:8000/ml/predict"); // IP address of the server on the network
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
