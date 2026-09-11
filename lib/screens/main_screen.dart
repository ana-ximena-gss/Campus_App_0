// Basically the Bottom Nav Bar "Screen"
import 'package:flutter/material.dart';
import 'map_screen.dart'; 
import 'setting_screen.dart';
import 'user_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;   // starts at 0 to load the MapScreen first

  final List<Widget> _screens = [
    const MapScreen(),      //Index 0
    const SettingsScreen(), //Index 1
    const UserScreen(),     //Index 2
  ];

  void _onItemTapped(int index) {
    setState(() {
      // Updates the selected index when a bottom navigation item is tapped
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, 
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User',
          ),
        ],
      ),
    );
  }
}