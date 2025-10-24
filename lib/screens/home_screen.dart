import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steps_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/water_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _staggerAnimations;

  // Track hover state cho quick action buttons
  final Set<int> _hoveredButtons = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggerAnimations = List.generate(
      5,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15,
            (index * 0.15) + 0.6,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = Provider.of<StepsProvider>(context).steps;
    final weight = Provider.of<WeightProvider>(context).weight;
    final water = Provider.of<WaterProvider>(context).water;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trang chủ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // Header Goal Card with Animation
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
              child: FadeTransition(
                opacity: _staggerAnimations[0],
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6A1B9A),
                        const Color(0xFF1976D2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A1B9A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Mục tiêu hôm nay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${steps.steps} / ${steps.goal}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'bước',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (steps.steps / steps.goal).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${((steps.steps / steps.goal) * 100).toStringAsFixed(0)}% hoàn thành',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            FadeTransition(
              opacity: _staggerAnimations[1],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.scale,
                        label: 'Cân nặng',
                        value: '${weight.currentWeight.toStringAsFixed(1)} kg',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.local_drink,
                        label: 'Nước uống',
                        value: '${water.cupsDrunk}/${water.totalCups}',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Quick Actions Header
            FadeTransition(
              opacity: _staggerAnimations[2],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      color: Colors.amber.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Action Buttons with Stagger
            FadeTransition(
              opacity: _staggerAnimations[3],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickActionButton(
                      index: 0,
                      icon: Icons.local_drink_outlined,
                      label: 'Thêm nước',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/water'),
                    ),
                    _buildQuickActionButton(
                      index: 1,
                      icon: Icons.scale_outlined,
                      label: 'Cân nặng',
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(context, '/weight'),
                    ),
                    _buildQuickActionButton(
                      index: 2,
                      icon: Icons.directions_walk_outlined,
                      label: 'Bước chân',
                      color: Colors.purple,
                      onTap: () => Navigator.pushNamed(context, '/steps'),
                    ),
                    _buildQuickActionButton(
                      index: 3,
                      icon: Icons.notifications_outlined,
                      label: 'Nhắc nhở',
                      color: Colors.red,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Tính năng đang phát triển'),
                            backgroundColor: Colors.blue.shade400,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredButtons.contains(index);

    return Flexible(
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hoveredButtons.add(index);
          });
        },
        onExit: (_) {
          setState(() {
            _hoveredButtons.remove(index);
          });
        },
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: isHovered ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? color.withOpacity(0.25)
                          : color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHovered
                            ? color.withOpacity(0.4)
                            : color.withOpacity(0.2),
                        width: isHovered ? 2 : 1.5,
                      ),
                      boxShadow: isHovered
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Icon(icon, color: color, size: isHovered ? 28 : 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                      color: isHovered ? color : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
