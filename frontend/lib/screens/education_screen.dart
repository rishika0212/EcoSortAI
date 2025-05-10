import 'dart:math';
import 'package:flutter/material.dart';
import '../services/education_service.dart';

class EducationScreen extends StatefulWidget {
  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final EducationService _service = EducationService();
  late Future<List<Map<String, dynamic>>> _factsFuture;

  final List<Color> _cardColors = [
    Color(0xFFD0F0C0), // light green
    Color(0xFFE6FFCC), // even lighter green
    Color(0xFFFFF9C4), // light yellow
    Color.fromARGB(255, 252, 241, 137), // stronger yellow
  ];

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  void _loadFacts() {
    setState(() {
      _factsFuture = _service.fetchFacts().then((allFacts) {
        allFacts.shuffle(Random());
        return allFacts.take(7).toList();
      });
    });
  }

  Future<void> _onRefresh() async {
    _loadFacts();
    await _factsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plastic Facts')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _factsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: CircularProgressIndicator());

            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));

            final facts = snapshot.data!;

            return ListView.builder(
              itemCount: facts.length,
              itemBuilder: (context, index) {
                final fact = facts[index];
                final bgColor = _cardColors[index % _cardColors.length];
                final text = fact['fact'];

                return Card(
                  color: bgColor,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      text,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
