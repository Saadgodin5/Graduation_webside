import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/login_page.dart';
import 'dashboard/dashboard_page.dart';

/// Entry point of the Flutter application.
/// Initializes Supabase and then starts the root `MyApp` widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Supabase project URL and public anonymous key for this app.
    // These values must match the project you created in Supabase.
    url: 'https://utztollqwglvmtzfccwv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0enRvbGxxd2dsdm10emZjY3d2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0NTQyNjMsImV4cCI6MjA4NjAzMDI2M30.xquaCEsuwWyk18K-0lEzbRynyM983kIfeRzffM7GINk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Global theme and colors for the whole app.
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    );

    return MaterialApp(
      // App title shown in the browser tab.
      title: 'Graduation Web App',
      debugShowCheckedModeBanner: false,
      theme: theme,
      // `AuthGate` decides whether to show login or dashboard.
      home: const AuthGate(),
    );
  }
}

/// Shows the login page when the user is signed out, and the dashboard when
/// the user has an active Supabase session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return DashboardPage(session: session);
      },
    );
  }
}

