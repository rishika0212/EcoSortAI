import 'package:flutter/material.dart';
import '../screens/education_screen.dart';
import '../screens/leaderboard_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/education': (context) => EducationScreen(),
  '/leaderboard': (context) => const LeaderboardScreen(),
  // other routes...
};
