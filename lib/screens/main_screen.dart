// 1. --- IMPORT HIVE and other necessary packages ---
import 'dart:io';

import 'package:book_store/screens/my_library.dart';
import 'package:book_store/screens/profile_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart';
import '../models/book_model.dart';
import 'explore_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _navigateToExplore() {
    setState(() {
      _selectedIndex = 2; // Index of ExploreScreen
    });
  }

  List<Widget> _buildScreenOptions() {
    return [
      HomeScreen(onNavigateToExplore: _navigateToExplore),
      const CartScreen(),
      const ExploreScreen(),
      const ProfileScreen(),
    ];
  }

  static const List<String> _screenTitles = [
    'Home',
    'My Cart',
    'Explore',
    'Profile',
  ];

  void _onDrawerItemTapped(int index) {
    // If the profile screen is selected, we don't want to change the main scaffold's state,
    // as the ProfileScreen has its own AppBar. This prevents title/button conflicts.
    // We navigate to it as a separate route instead.
    if (index == 3) {
      Navigator.pop(context); // Close the drawer
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
      Navigator.pop(context);
    }
  }

  Future<void> _signOut() async {
    // Also clear local data on sign out for a clean slate
    await Hive.box<Book>('wishlist_books').clear();
    await Hive.box('user_profile').clear();

    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreenOptions();

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        actions: [
          // --- 2. WRAP the CircleAvatar in a ValueListenableBuilder ---
          ValueListenableBuilder(
            // Listen to changes in the 'user_profile' box
            valueListenable: Hive.box('user_profile').listenable(),
            builder: (context, Box box, _) {
              // Get the saved image path from Hive
              final imagePath = box.get('imagePath');

              // Determine the correct image provider
              ImageProvider? backgroundImage;
              if (!kIsWeb && imagePath != null) {
                backgroundImage = FileImage(File(imagePath));
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: backgroundImage,
                  // Show a placeholder icon if no image is set
                  child: backgroundImage == null
                      ? const Icon(Icons.person, size: 22)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Book Explorer',
                style: Theme.of(context).primaryTextTheme.headlineMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () => _onDrawerItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: const Text('My Cart'),
              selected: _selectedIndex == 1,
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: const Text('Explore'),
              selected: _selectedIndex == 2,
              onTap: () => _onDrawerItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              selected: _selectedIndex == 3,
              onTap: () => _onDrawerItemTapped(3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: screens.elementAt(_selectedIndex),
    );
  }
}
