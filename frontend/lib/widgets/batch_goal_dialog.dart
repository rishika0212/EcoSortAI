import 'package:flutter/material.dart';

/// A dialog that shows a congratulatory message when a batch goal is reached
class BatchGoalDialog extends StatelessWidget {
  final String plasticType;
  final int batchCount;
  final String badgeEmoji;
  final String badgeName;
  final String badgeColor; // Color for the badge (used for level badges)
  final bool isPlasticTypeBadge; // Indicates if this is a plastic-specific badge or a level badge

  const BatchGoalDialog({
    super.key,
    required this.plasticType,
    required this.batchCount,
    required this.badgeEmoji,
    required this.badgeName,
    this.badgeColor = '#D0F0C0', // Default color for plastic badges
    this.isPlasticTypeBadge = false, // Default to level badge
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  // Helper method to clean badge name by removing emoji
  String _cleanBadgeName(String name) {
    // Remove emoji and trim
    final cleanName = name.replaceAll(RegExp(r'[\uD800-\uDBFF][\uDC00-\uDFFF]|[^\x00-\x7F]'), '').trim();
    
    // If the name starts with a space, it likely had an emoji at the beginning
    if (cleanName.startsWith(' ')) {
      return cleanName.trim();
    }
    
    return cleanName;
  }

  Widget _buildDialogContent(BuildContext context) {
    // Convert hex color to Flutter color
    Color dialogColor;
    try {
      // Parse the hex color
      final hexValue = badgeColor.replaceAll('#', '');
      dialogColor = Color(int.parse('FF$hexValue', radix: 16));
    } catch (e) {
      // Fallback to a default color if parsing fails
      dialogColor = Colors.pink[100]!;
    }
    
    // For both badge types, use the provided badge color
    final backgroundColor = dialogColor.withOpacity(0.9);
    
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display emoji in a separate Text widget with larger font size
                  Text(
                    badgeEmoji,
                    style: const TextStyle(
                      fontSize: 32, // Larger size for emoji
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Display the text in a separate widget
                  Flexible(
                    child: Text(
                      isPlasticTypeBadge
                          ? 'Plastic Badge Earned!'
                          : 'Level Badge Achieved!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Congratulations!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isPlasticTypeBadge
                    ? 'You\'ve recycled $batchCount $plasticType items in this batch!'
                    : 'You\'ve reached $batchCount total points!',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: dialogColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPlasticTypeBadge
                      ? 'You\'ve earned the "${_cleanBadgeName(badgeName)}" badge for recycling $plasticType!'
                      : 'You\'ve reached the "${_cleanBadgeName(badgeName)}" level!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Keep up the great work! Your recycling efforts are making a real difference for our planet.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      // Use the dialog color for both badge types
                      color: dialogColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}