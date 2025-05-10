import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';

void main() {
  runApp(const EcoSortApp());
}

class EcoSortApp extends StatelessWidget {
  const EcoSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSortAI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Roboto',
        ),
      ),
      home: const AuthChecker(),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool? isLoggedIn;
  String? username;
  int points = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final loggedIn = await AuthService().isLoggedIn();
    print("AuthChecker: User is logged in: $loggedIn");

    if (loggedIn) {
      try {
        // Always refresh from server first to ensure we have the latest data
        print("AuthChecker: Refreshing user data from server");
        await AuthService().refreshUserData();
        
        // Get the fresh data
        final freshUsername = await LocalStorageService.getUsername();
        final freshPoints = await LocalStorageService.getPoints();
        
        if (mounted) {
          setState(() {
            isLoggedIn = true;
            username = freshUsername ?? 'User';
            points = freshPoints;
          });
          print("AuthChecker: Initialized with fresh data - username: $freshUsername, points: $freshPoints");
        }
      } catch (e) {
        print("AuthChecker: Error refreshing user data: $e");
        
        // Fallback to local data if server refresh fails
        final uname = await LocalStorageService.getUsername();
        final pts = await LocalStorageService.getPoints();
        
        if (mounted) {
          setState(() {
            isLoggedIn = true;
            username = uname ?? 'User';
            points = pts;
          });
          print("AuthChecker: Initialized with local data - username: $uname, points: $pts");
        }
      }
    } else {
      // Clear any stale data if not logged in
      await LocalStorageService.clearAllUserData();
      
      setState(() {
        isLoggedIn = false;
        username = null;
        points = 0;
      });
      print("AuthChecker: User not logged in, cleared all data");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (isLoggedIn!) {
      return HomeScreen(initialUsername: username ?? 'User', initialPoints: points);
    } else {
      return const LoginScreen();
    }
  }
}
