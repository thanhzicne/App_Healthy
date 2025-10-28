// steps_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/steps_provider.dart';
import '../models/steps_model.dart';
import '../screens/steps_history_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StepsProvider>(
      builder: (context, stepsProvider, child) {
        final stepsData = stepsProvider.steps;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Bước chân',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.deepPurple.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              //Thêm IconButton cho thông báo
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () async {
                  // Gọi NotificationService để gửi thông báo
                  await NotificationService().checkStepsGoalAndNotify(
                    currentSteps: stepsData.steps,
                    goal: stepsData.goal,
                  );
                },
                tooltip: 'Gửi thông báo bước chân',
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StepsHistoryScreen(
                        dailySteps: stepsProvider.dailySteps,
                      ),
                    ),
                  );
                },
                tooltip: 'Lịch sử bước chân',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Goal Card Header
                Container(
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
                      Text(
                        '${stepsData.steps} / ${stepsData.goal}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                          value: (stepsData.steps / stepsData.goal).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hiển thị Calo và Quãng đường
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildInfoCard(
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orange,
                        title: 'Calo đốt cháy',
                        value: '${stepsData.calories.toStringAsFixed(0)} kcal',
                      ),
                      const SizedBox(width: 16),
                      _buildInfoCard(
                        icon: Icons.map_outlined,
                        color: Colors.blue,
                        title: 'Quãng đường',
                        value: '${stepsData.distance.toStringAsFixed(2)} km',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Biểu đồ hoạt động trong ngày
                _buildChartContainer(
                  title: 'Hoạt động trong ngày',
                  chart: TodayChart(data: stepsProvider.hourlySteps),
                ),

                const SizedBox(height: 24),

                // Biểu đồ tổng kết 7 ngày
                _buildChartContainer(
                  title: 'Tổng kết 7 ngày qua',
                  chart: WeeklyChart(data: stepsProvider.dailySteps),
                ),

                const SizedBox(height: 24),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget chart}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: chart,
          ),
        ],
      ),
    );
  }
}

// Widget cho biểu đồ hoạt động trong ngày (biểu đồ cột)
class TodayChart extends StatelessWidget {
  final List<HourlySteps> data;
  const TodayChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${group.x}h: ${rod.toY.round()} bước',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // ✅ Hiển thị mỗi 4 giờ: 0h, 4h, 8h, 12h, 16h, 20h
                if (value.toInt() % 4 == 0) {
                  return Text(
                    '${value.toInt()}h',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // ✅ Luôn tạo 24 cột cho 24 giờ
        barGroups: List.generate(24, (index) {
          // Tìm số bước cho giờ này trong data
          int steps = 0;
          for (var d in data) {
            if (d.hour.hour == index) {
              steps = d.steps;
              break;
            }
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: steps.toDouble(),
                color:
                    steps > 0 ? Colors.purple.shade300 : Colors.grey.shade300,
                width: 6,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// Widget cho biểu đồ tổng kết 7 ngày (biểu đồ đường)
class WeeklyChart extends StatelessWidget {
  final List<DailySteps> data;
  const WeeklyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // ✅ Tạo danh sách 7 ngày gần nhất (từ 6 ngày trước đến hôm nay)
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
    });

    // ✅ Map dữ liệu theo ngày
    final Map<String, int> stepsMap = {};
    for (var dailyStep in data) {
      final dateKey =
          '${dailyStep.date.year}-${dailyStep.date.month}-${dailyStep.date.day}';
      stepsMap[dateKey] = dailyStep.steps;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < 7) {
                  final date = last7Days[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E', 'vi_VN').format(date),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(7, (index) {
              final date = last7Days[index];
              final dateKey = '${date.year}-${date.month}-${date.day}';
              final steps = stepsMap[dateKey] ?? 0;
              return FlSpot(index.toDouble(), steps.toDouble());
            }),
            isCurved: true,
            color: Colors.green.shade400,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green.shade400,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          )
        ],
      ),
    );
  }
}
