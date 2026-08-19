import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'screens/auth_gate.dart';
import 'providers/home_setup_provider.dart';
import 'providers/room_provider.dart';
import 'providers/appliance_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/insights_provider.dart';
import 'providers/report_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeSetupProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => ApplianceProvider()),
        ChangeNotifierProvider(create: (_) => InsightsProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OORJA',
      debugShowCheckedModeBanner: false, // hides the red DEBUG banner
      theme: AppTheme.darkTheme, // <-- this was the bug: your custom theme was never applied
      home: const AuthGate(),
    );
  }
}