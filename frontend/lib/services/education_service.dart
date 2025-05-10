import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EducationService {
  final String _endpoint = 'https://api.jsonbin.io/v3/b/6818f51a8561e97a500e5329';
  final String _apiKey = r'''$2a$10$0MnoHzd6xnEXQL59c4Giu.bce4Gi5E40Y.0cyOsa35i1/9hzbkspu''';

  Future<List<Map<String, dynamic>>> fetchFacts() async {
    try {
      final response = await http.get(
        Uri.parse(_endpoint),
        headers: {
          'X-Master-Key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allFacts = data['record']; // Adjusted based on jsonbin response

        // Shuffle and pick 7 random facts
        allFacts.shuffle(Random());
        final randomFacts = allFacts.take(7).cast<Map<String, dynamic>>().toList();

        return randomFacts;
      } else {
        throw Exception('Failed to fetch facts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching facts: $e');
    }
  }
}
