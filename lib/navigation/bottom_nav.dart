import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/weight_screen.dart';
import '../screens/water_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/news_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late List<AnimationController> _iconAnimationControllers;

  final List<Widget> _screens = const [
    HomeScreen(),
    StepsScreen(),
    WeightScreen(),
    WaterScreen(),
    ProfileScreen(),
    NewsScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home,
      label: 'Trang chủ',
      color: Colors.blue,
    ),
    _NavItem(
      icon: Icons.directions_walk_rounded,
      activeIcon: Icons.directions_walk,
      label: 'Bước chân',
      color: Colors.purple,
    ),
    _NavItem(
      icon: Icons.monitor_weight_rounded,
      activeIcon: Icons.monitor_weight,
      label: 'Cân nặng',
      color: Colors.orange,
    ),
    _NavItem(
      icon: Icons.water_drop_rounded,
      activeIcon: Icons.water_drop,
      label: 'Nước uống',
      color: Colors.cyan,
    ),
    _NavItem(
      icon: Icons.person_rounded,
      activeIcon: Icons.person,
      label: 'Hồ sơ',
      color: Colors.green,
    ),
    _NavItem(
      icon: Icons.article_rounded,
      activeIcon: Icons.article,
      label: 'Tin tức',
      color: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconAnimationControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _iconAnimationControllers[0].forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _iconAnimationControllers[_selectedIndex].reverse();
      _iconAnimationControllers[index].forward();

      setState(() {
        _selectedIndex = index;
      });

      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildModernBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _iconAnimationControllers[index],
          builder: (context, child) {
            final scale = isSelected
                ? 1.0 + (_iconAnimationControllers[index].value * 0.2)
                : 1.0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background glow effect
                      if (isSelected)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                item.color.withOpacity(0.3 *
                                    _iconAnimationControllers[index].value),
                                item.color.withOpacity(0),
                              ],
                            ),
                          ),
                        ),

                      // Icon container
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      item.color.withOpacity(0.2),
                                      item.color.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color:
                                isSelected ? item.color : Colors.grey.shade500,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Label with animation
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isSelected ? 11 : 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? item.color : Colors.grey.shade600,
                      height: 1,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
