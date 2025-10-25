import 'dart:ui';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _shimmerAnimationController;
  late List<Animation<double>> _staggerAnimations;
  final ValueNotifier<Set<int>> _hoveredButtons = ValueNotifier({});

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Pulse animation for goal card
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer animation for progress bar
    _shimmerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _staggerAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _mainAnimationController,
          curve: Interval(
            index * 0.12,
            (index * 0.12) + 0.65,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _hoveredButtons.dispose();
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _shimmerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = Provider.of<StepsProvider>(context).steps;
    final weight = Provider.of<WeightProvider>(context).weight;
    final water = Provider.of<WaterProvider>(context).water;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar with Glassmorphism
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.6),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.purple.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sức khỏe hôm nay',
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
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Enhanced Goal Card with Animated Gradient
                    FadeTransition(
                      opacity: _staggerAnimations[0],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _mainAnimationController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: _buildEnhancedGoalCard(steps),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Enhanced Stats Cards with 3D Effect
                    FadeTransition(
                      opacity: _staggerAnimations[1],
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _mainAnimationController,
                            curve: const Interval(0.2, 0.8,
                                curve: Curves.elasticOut),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildEnhancedStatCard(
                                icon: Icons.scale_rounded,
                                label: 'Cân nặng',
                                value:
                                    '${weight.currentWeight.toStringAsFixed(1)} kg',
                                color: Colors.orange,
                                gradient: [
                                  Colors.orange.shade400,
                                  Colors.deepOrange.shade600
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildEnhancedStatCard(
                                icon: Icons.water_drop_rounded,
                                label: 'Nước uống',
                                value: '${water.cupsDrunk}/${water.totalCups}',
                                color: Colors.blue,
                                gradient: [
                                  Colors.blue.shade400,
                                  Colors.cyan.shade600
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions Header with Animation
                    FadeTransition(
                      opacity: _staggerAnimations[2],
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (_pulseAnimationController.value * 0.1),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade300,
                                        Colors.orange.shade400,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thao tác nhanh',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced Quick Action Buttons Grid
                    FadeTransition(
                      opacity: _staggerAnimations[3],
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildModernQuickActionButton(
                            index: 0,
                            icon: Icons.water_drop,
                            label: 'Thêm nước',
                            gradient: [
                              Colors.blue.shade400,
                              Colors.cyan.shade600
                            ],
                            onTap: () => Navigator.pushNamed(context, '/water'),
                          ),
                          _buildModernQuickActionButton(
                            index: 1,
                            icon: Icons.monitor_weight_rounded,
                            label: 'Cân nặng',
                            gradient: [
                              Colors.orange.shade400,
                              Colors.deepOrange.shade600
                            ],
                            onTap: () =>
                                Navigator.pushNamed(context, '/weight'),
                          ),
                          _buildModernQuickActionButton(
                            index: 2,
                            icon: Icons.directions_walk,
                            label: 'Bước chân',
                            gradient: [
                              Colors.purple.shade400,
                              Colors.deepPurple.shade600
                            ],
                            onTap: () => Navigator.pushNamed(context, '/steps'),
                          ),
                          _buildModernQuickActionButton(
                            index: 3,
                            icon: Icons.notifications_active,
                            label: 'Nhắc nhở',
                            gradient: [
                              Colors.pink.shade400,
                              Colors.red.shade500
                            ],
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    '🔔 Tính năng đang phát triển',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: Colors.purple.shade400,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedGoalCard(dynamic steps) {
    final progress = (steps.steps / steps.goal).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.purple
                    .withOpacity(0.3 + (_pulseAnimationController.value * 0.1)),
                blurRadius: 20 + (_pulseAnimationController.value * 5),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.8),
                      const Color(0xFF764ba2).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🎯 Mục tiêu hôm nay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_walk,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${steps.steps}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'của ${steps.goal} bước',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Animated Progress Bar with Shimmer
                    Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _mainAnimationController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor:
                                  progress * _mainAnimationController.value,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.greenAccent.shade200,
                                      Colors.green.shade400,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Shimmer effect
                        AnimatedBuilder(
                          animation: _shimmerAnimationController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                    stops: [
                                      _shimmerAnimationController.value - 0.3,
                                      _shimmerAnimationController.value,
                                      _shimmerAnimationController.value + 0.3,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickActionButton({
    required int index,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: _hoveredButtons,
      builder: (context, hoveredButtons, child) {
        final isHovered = hoveredButtons.contains(index);
        return MouseRegion(
          onEnter: (_) =>
              _hoveredButtons.value = {..._hoveredButtons.value, index},
          onExit: (_) =>
              _hoveredButtons.value = {..._hoveredButtons.value}..remove(index),
          child: GestureDetector(
            onTapDown: (_) =>
                _hoveredButtons.value = {..._hoveredButtons.value, index},
            onTapUp: (_) {
              Future.delayed(const Duration(milliseconds: 150), () {
                _hoveredButtons.value = {..._hoveredButtons.value}
                  ..remove(index);
                onTap();
              });
            },
            onTapCancel: () => _hoveredButtons.value = {
              ..._hoveredButtons.value
            }..remove(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..scale(isHovered ? 1.05 : 1.0)
                ..rotateZ(isHovered ? -0.02 : 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHovered ? gradient : [Colors.white, Colors.white],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? gradient[0].withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: isHovered ? 20 : 10,
                    offset: Offset(0, isHovered ? 12 : 6),
                  ),
                ],
                border: Border.all(
                  color: isHovered ? Colors.transparent : Colors.grey.shade200,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isHovered ? Colors.white : gradient[0],
                    size: isHovered ? 44 : 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isHovered ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
