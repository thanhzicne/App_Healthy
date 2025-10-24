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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _staggerAnimations;
  final ValueNotifier<Set<int>> _hoveredButtons = ValueNotifier({});

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
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _hoveredButtons.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = Provider.of<StepsProvider>(context).steps;
    final weight = Provider.of<WeightProvider>(context).weight;
    final water = Provider.of<WaterProvider>(context).water;

    return Scaffold(
      body: Stack(
        children: [
          // Parallax Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _animationController.value)),
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/background_pattern.png',
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                );
              },
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.9),
                title: Text(
                  'Trang chủ',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                iconTheme: const IconThemeData(color: Colors.black87),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Goal Card with Glassmorphism
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _staggerAnimations[0],
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6A1B9A).withOpacity(0.6),
                                      const Color(0xFF1976D2).withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text(
                                      'Mục tiêu hôm nay',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 16,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.directions_walk,
                                          color: Colors.white,
                                          size: 32,
                                          semanticLabel: 'Bước chân',
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${steps.steps} / ${steps.goal}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontSize: 28,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            Text(
                                              'bước',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: (steps.steps /
                                                            steps.goal)
                                                        .clamp(0, 1) *
                                                    _animationController.value,
                                                child: Container(
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.greenAccent
                                                            .shade400,
                                                        Colors.greenAccent
                                                            .shade700,
                                                      ],
                                                      begin:
                                                          Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors
                                                            .greenAccent
                                                            .withOpacity(0.4),
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${((steps.steps / steps.goal) * 100).toStringAsFixed(0)}% hoàn thành',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Cards with Bounce Animation
                    FadeTransition(
                      opacity: _staggerAnimations[1],
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(0.2, 0.8,
                                curve: Curves.easeOutBack),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.scale,
                                  label: 'Cân nặng',
                                  value:
                                      '${weight.currentWeight.toStringAsFixed(1)} kg',
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.local_drink,
                                  label: 'Nước uống',
                                  value:
                                      '${water.cupsDrunk}/${water.totalCups}',
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
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
                              semanticLabel: 'Thao tác nhanh',
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thao tác nhanh',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Action Buttons with Neumorphism
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
                              onTap: () =>
                                  Navigator.pushNamed(context, '/water'),
                            ),
                            _buildQuickActionButton(
                              index: 1,
                              icon: Icons.scale_outlined,
                              label: 'Cân nặng',
                              color: Colors.orange,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/weight'),
                            ),
                            _buildQuickActionButton(
                              index: 2,
                              icon: Icons.directions_walk_outlined,
                              label: 'Bước chân',
                              color: Colors.purple,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/steps'),
                            ),
                            _buildQuickActionButton(
                              index: 3,
                              icon: Icons.notifications_outlined,
                              label: 'Nhắc nhở',
                              color: Colors.red,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('Tính năng đang phát triển'),
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
            ],
          ),
        ],
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
            child: Icon(icon, color: color, size: 22, semanticLabel: label),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
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
    return Flexible(
      child: ValueListenableBuilder<Set<int>>(
        valueListenable: _hoveredButtons,
        builder: (context, hoveredButtons, child) {
          final isHovered = hoveredButtons.contains(index);
          return MouseRegion(
            onEnter: (_) =>
                _hoveredButtons.value = {..._hoveredButtons.value, index},
            onExit: (_) => _hoveredButtons.value = {..._hoveredButtons.value}
              ..remove(index),
            child: GestureDetector(
              onTapDown: (_) =>
                  _hoveredButtons.value = {..._hoveredButtons.value, index},
              onTapUp: (_) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _hoveredButtons.value = {..._hoveredButtons.value}
                    ..remove(index);
                  onTap();
                });
              },
              onTapCancel: () => _hoveredButtons.value = {
                ..._hoveredButtons.value
              }..remove(index),
              child: AnimatedScale(
                scale: isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 10,
                              offset: const Offset(4, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 10,
                              offset: const Offset(-4, -4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 8,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: color,
                        size: isHovered ? 30 : 28,
                        semanticLabel: label,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight:
                                  isHovered ? FontWeight.w700 : FontWeight.w500,
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
          );
        },
      ),
    );
  }
}
