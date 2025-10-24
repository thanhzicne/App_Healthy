import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steps_provider.dart';
import '../models/steps_model.dart';
import '../widgets/chart_widget.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen>
    with SingleTickerProviderStateMixin {
  final stepsController = TextEditingController();
  late AnimationController _animationController;
  late List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggerAnimations = List.generate(
      4,
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
    stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = Provider.of<StepsProvider>(context).steps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bước chân'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Goal Card Header
            FadeTransition(
              opacity: _staggerAnimations[0],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  ),
                ),
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
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: steps.steps),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Text(
                            '$value / ${steps.goal}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'bước',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${((steps.steps / steps.goal) * 100).toStringAsFixed(0)}% hoàn thành',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              '${(steps.steps / steps.goal > 1 ? steps.steps - steps.goal : steps.goal - steps.steps)} bước',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Distance Card
            FadeTransition(
              opacity: _staggerAnimations[1],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.map_outlined,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quãng đường',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: steps.distance),
                              duration: const Duration(milliseconds: 1000),
                              builder: (context, value, child) {
                                return Text(
                                  '${value.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: const Text(
                          'Thống kê',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Update Button
            FadeTransition(
              opacity: _staggerAnimations[2],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStepsDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Cập nhật bước chân',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Chart Section
            FadeTransition(
              opacity: _staggerAnimations[3],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Thống kê chi tiết',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      // child: ChartWidget(
                      //  chart: const SizedBox(),
                      //  title: 'Thống kê chi tiết',
                    ),
                    //),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showStepsDialog(BuildContext context) {
    final stepsProvider = Provider.of<StepsProvider>(context, listen: false);
    stepsController.text = stepsProvider.steps.steps.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent:
                ModalRoute.of(context)?.controller ?? AlwaysStoppedAnimation(1),
            curve: Curves.elasticOut,
          ),
        ),
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.purple.shade600),
              const SizedBox(width: 8),
              const Text('Cập nhật bước chân'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: stepsController,
                  decoration: InputDecoration(
                    labelText: 'Số bước',
                    prefixIcon: Icon(
                      Icons.directions_walk_outlined,
                      color: Colors.purple.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.purple.shade600,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhập số bước bạn đã bước hôm nay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                final newSteps = StepsModel(
                  steps: int.parse(stepsController.text),
                  goal: stepsProvider.steps.goal,
                  distance: stepsProvider.steps.distance,
                );
                stepsProvider.updateSteps(newSteps);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
