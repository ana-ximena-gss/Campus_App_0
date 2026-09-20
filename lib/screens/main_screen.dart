import 'package:campus_app/models/activity.dart';
import 'package:campus_app/screens/activities/list_of_activities_screen.dart';
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
  int _selectedIndex = 0;

  Activity? _selectedActivity;

  // This changes every time an activity is selected from the list.
  // MapScreen uses it to know that it should move to a new activity.
  int _mapFocusRequest = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showActivityOnMap(Activity activity) {
    setState(() {
      _selectedActivity = activity;

      // Tell MapScreen that there is a new activity to focus on.
      _mapFocusRequest++;

      // Switch to the Map tab.
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MapScreen(
            selectedActivity: _selectedActivity,
            focusRequest: _mapFocusRequest,
          ),

          ActivityListScreen(
            onViewOnMap: _showActivityOnMap,
          ),

          const SettingsScreen(),

          const UserScreen(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Activities',
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