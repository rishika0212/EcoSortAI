import 'package:flutter/material.dart';
import '../models/recycling_center.dart';
import '../services/recycling_center_service.dart';
import '../utils/constants.dart';

class RecyclingMapScreen extends StatefulWidget {
  const RecyclingMapScreen({super.key});

  @override
  State<RecyclingMapScreen> createState() => _RecyclingMapScreenState();
}

class _RecyclingMapScreenState extends State<RecyclingMapScreen> {
  final RecyclingCenterService _recyclingCenterService = RecyclingCenterService();
  List<RecyclingCenter> _recyclingCenters = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadRecyclingCenters();
  }
  
  Future<void> _loadRecyclingCenters() async {
    try {
      final centers = await _recyclingCenterService.getNearbyRecyclingCenters();
      if (mounted) {
        setState(() {
          _recyclingCenters = centers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recycling centers: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycling Centers'),
        backgroundColor: AppColors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dummy map container
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: Stack(
                    children: [
                      // Map background with grid lines to simulate a map
                      CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: MapGridPainter(),
                      ),
                      
                      // Map pins for recycling centers
                      for (var center in _recyclingCenters)
                        Positioned(
                          // Calculate position based on latitude and longitude
                          // This is just a simple calculation for demonstration
                          // Adjusted for Bangalore coordinates (around 12.97° N, 77.59° E)
                          left: ((center.longitude - 77.5) * 300) % MediaQuery.of(context).size.width,
                          top: ((13.1 - center.latitude) * 300) % 180,
                          child: GestureDetector(
                            onTap: () => _showCenterDetails(center),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ),
                      
                      // Current location indicator
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      
                      // Map overlay with instructions
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'Tap on a pin to view details',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // List of recycling centers
                Expanded(
                  child: ListView.builder(
                    itemCount: _recyclingCenters.length,
                    itemBuilder: (context, index) {
                      final center = _recyclingCenters[index];
                      return _buildRecyclingCenterCard(center);
                    },
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildRecyclingCenterCard(RecyclingCenter center) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCenterDetails(center),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.recycling,
                      color: AppColors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          center.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hours: ${center.operatingHours}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: center.acceptedMaterials.map((material) {
                  return Chip(
                    label: Text(
                      material,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getMaterialColor(material),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PET':
        return Colors.blue.shade100;
      case 'HDPE':
        return Colors.green.shade100;
      case 'LDPE':
        return Colors.amber.shade100;
      case 'PP':
        return Colors.orange.shade100;
      case 'PS':
        return Colors.red.shade100;
      case 'Paper':
        return Colors.brown.shade100;
      case 'Glass':
        return Colors.cyan.shade100;
      case 'Metal':
        return Colors.grey.shade300;
      case 'Electronics':
        return Colors.purple.shade100;
      case 'E-waste':
        return Colors.deepPurple.shade100;
      case 'Computer Parts':
        return Colors.indigo.shade200;
      case 'Batteries':
        return Colors.indigo.shade100;
      case 'Organic Waste':
        return Colors.lightGreen.shade100;
      case 'Industrial Plastics':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
  
  void _showCenterDetails(RecyclingCenter center) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      center.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                center.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.location_on, center.address),
              _detailRow(Icons.access_time, center.operatingHours),
              _detailRow(Icons.phone, center.contactNumber),
              const SizedBox(height: 16),
              const Text(
                'Accepted Materials:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: center.acceptedMaterials.map((material) {
                  return Chip(
                    label: Text(material),
                    backgroundColor: _getMaterialColor(material),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // In a real app, this would open maps with directions
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening directions (simulated)')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Get Directions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw a grid that simulates a map
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Draw horizontal lines
    for (var i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
    
    // Draw vertical lines
    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    
    // Draw some "roads"
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    
    // Horizontal roads
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      roadPaint,
    );
    
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      roadPaint,
    );
    
    // Vertical roads
    canvas.drawLine(
      Offset(size.width / 4, 0),
      Offset(size.width / 4, size.height),
      roadPaint,
    );
    
    canvas.drawLine(
      Offset(size.width * 3 / 4, 0),
      Offset(size.width * 3 / 4, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}