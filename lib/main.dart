import 'dart:async';

import 'package:book_store/models/book_model.dart'; // Import the book model
import 'package:book_store/screens/auth/login_screen.dart';
import 'package:book_store/screens/auth/signup_screen.dart';
import 'package:book_store/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:supabase_flutter/supabase_flutter.dart';

// --- MAIN: App Initialization ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. HIVE INITIALIZATION ---
  await Hive.initFlutter();
  // Register the adapter for our custom Book object
  // This line requires the 'book_model.g.dart' file to have been generated
  Hive.registerAdapter(BookAdapter());
  // Open the boxes we will use throughout the app
  await Hive.openBox<Book>('wishlist_books');
  await Hive.openBox('user_profile');
  await Hive.openBox<int>('cart_quantities');
  // --- END HIVE INITIALIZATION ---

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pclxusyaukdwdliloirj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjbHh1c3lhdWtkd2RsaWxvaXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3MDI5NzksImV4cCI6MjA3MDI3ODk3OX0.bW6TZW7K0V8ZvIHAmiQWNXdKmM8aVYFaj9xYKef4xyg',
  );
  runApp(const MyApp());
}

// Helper to get Supabase instance
final supabase = Supabase.instance.client;

// --- APP: Theme and Routing ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E7C65);
    const backgroundColor = Color(0xFFF3F7F5);
    const textColor = Color(0xFF212121);

    return MaterialApp(
      title: 'Book Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // (Your theme data is correct and unchanged)
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          background: backgroundColor,
          primary: primaryColor,
          onPrimary: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: textColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const MainScreen(),
        // Note: The '/explore' route is not needed since ExploreScreen is
        // handled by MainScreen, but it doesn't hurt to leave it.
      },
    );
  }
}

// --- SPLASH PAGE: Handles Auth Redirection ---
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          Icons.book_online_outlined,
          size: 120,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
