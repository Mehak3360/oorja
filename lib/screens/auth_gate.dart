import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../repositories/home_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();

    // Not logged in -> show placeholder Login screen
    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('LOGIN SCREEN (placeholder)')),
      );
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
          return const Scaffold(
            body: Center(child: Text('HOME SETUP SCREEN (placeholder)')),
          );
        }

        return const Scaffold(
          body: Center(child: Text('DASHBOARD (placeholder)')),
        );
      },
    );
  }
}