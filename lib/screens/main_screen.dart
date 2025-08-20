import 'package:book_store/screens/my_library.dart';
import 'package:book_store/screens/profile_screen.dart';
import 'package:flutter/material.dart';

import '../main.dart'; // To access the supabase client
import 'explore_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // --- 1. NEW FUNCTION TO HANDLE NAVIGATION ---
  // This function changes the state to show the Explore screen (index 2).
  void _navigateToExplore() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  // --- 2. CONVERTED THE LIST TO A METHOD ---
  // This allows us to pass the function to HomeScreen when it's built.
  List<Widget> _buildScreenOptions() {
    return [
      HomeScreen(
        onNavigateToExplore: _navigateToExplore,
      ), // Pass the function here
      const MyLibraryScreen(),
      const ExploreScreen(),
      const ProfileScreen(),
    ];
  }

  // List of titles for the AppBar to match the screens
  static const List<String> _screenTitles = <String>[
    'Home',
    'My Library',
    'Explore',
    'Profile',
  ];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      // You can show a SnackBar here if sign-out fails
    } finally {
      if (mounted) {
        // Navigate back to the login screen and remove all previous routes
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Call the method to get our list of screens
    final screens = _buildScreenOptions();

    return Scaffold(
      // The AppBar is now part of this main screen, providing consistency
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]), // Title updates dynamically
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
      // The drawer provides navigation for the whole app
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
              title: const Text('My Library'),
              selected: _selectedIndex == 1,
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: const Text('Explore'),
              selected: _selectedIndex == 2,
              onTap: () => _onDrawerItemTapped(2),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _signOut,
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: const Text('Profile'),
              selected: _selectedIndex == 3,
              onTap: () => _onDrawerItemTapped(5),
            ),
          ],
        ),
      ),
      // The body of the Scaffold displays the currently selected screen
      body: screens.elementAt(_selectedIndex),
    );
  }
}
