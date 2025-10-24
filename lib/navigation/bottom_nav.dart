import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/weight_screen.dart';
import '../screens/water_screen.dart';
import '../screens/profile_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StepsScreen(),
    WeightScreen(),
    WaterScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade400,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Bước chân',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.scale), label: 'Cân nặng'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_drink),
            label: 'Nước uống',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hộ sơ'),
        ],
      ),
    );
  }
}
