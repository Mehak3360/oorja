import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../repositories/home_repository.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home_setup_screen.dart';
import 'rooms_screen.dart';
import 'dashboard_screen.dart';
import 'main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds, then move to routing logic
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    final authProvider = context.watch<app_auth.AuthProvider>();

    // Not logged in -> show placeholder Login screen
    if (authProvider.currentUser == null) {
      return const LoginScreen();
    }

    // Logged in -> check if home setup is complete
    return FutureBuilder<bool>(
      future: HomeRepository().isSetupComplete(authProvider.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final setupDone = snapshot.data ?? false;

        if (!setupDone) {
          return const HomeSetupScreen();
        }

       return const MainNavigation();
      },
    );
  }
}