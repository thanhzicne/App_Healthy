import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/steps_provider.dart';
import '../models/steps_model.dart';

class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để tự động cập nhật UI khi có dữ liệu mới từ Provider
    return Consumer<StepsProvider>(
      builder: (context, stepsProvider, child) {
        final stepsData = stepsProvider.steps;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bước chân'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Goal Card Header (Giữ nguyên cấu trúc, chỉ cập nhật dữ liệu)
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
                      // Dữ liệu được cập nhật tự động
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

                // Thẻ hiển thị Calo và Quãng đường
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
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget helper để tạo các card thông tin (Calo, Quãng đường)
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

  // Widget helper để tạo khung chứa biểu đồ
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
    if (data.isEmpty) {
      return const Center(child: Text("Chưa có dữ liệu hoạt động hôm nay."));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} bước',
                const TextStyle(color: Colors.white),
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
                // Hiển thị giờ chẵn
                if (value.toInt() % 4 == 0) {
                  return Text('${value.toInt()}h',
                      style: const TextStyle(fontSize: 10));
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
        barGroups: List.generate(24, (index) {
          final hourlyData = data.firstWhere(
            (d) => d.hour.hour == index,
            orElse: () => HourlySteps(hour: DateTime.now(), steps: 0),
          );
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: hourlyData.steps.toDouble(),
                color: Colors.purple.shade300,
                width: 8,
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
    if (data.isEmpty) {
      return const Center(
          child: Text("Chưa đủ dữ liệu để hiển thị thống kê tuần."));
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
                if (value.toInt() < data.length) {
                  // Hiển thị tên các ngày trong tuần (T2, T3,...)
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E', 'vi_VN').format(data[value.toInt()].date),
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
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              return FlSpot(index.toDouble(), data[index].steps.toDouble());
            }),
            isCurved: true,
            color: Colors.green.shade400,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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
