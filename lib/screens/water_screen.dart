import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/water_intake_model.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../widgets/progress_ring.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen>
    with SingleTickerProviderStateMixin {
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
      6,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15,
            (index * 0.15) + 0.6 > 1.0 ? 1.0 : (index * 0.15) + 0.6,
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
    final waterProvider = Provider.of<WaterProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final water = waterProvider.water;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nước uống',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Progress Ring Section
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
                        colors: [Colors.blue.shade300, Colors.cyan.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          'Lượng nước hôm nay',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ProgressRing(
                          value:
                              (water.cupsDrunk / water.totalCups).clamp(0, 1),
                          label: '${water.cupsDrunk}/${water.totalCups}',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            'cốc',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Daily Goal Card
              FadeTransition(
                opacity: _staggerAnimations[1],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.blue.shade200, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.local_drink_rounded,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mục tiêu hôm nay',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${water.mlGoal.toInt()} ml (${water.totalCups} cốc)',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: water.cupsDrunk >= water.totalCups
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            water.cupsDrunk >= water.totalCups
                                ? '✓ Đạt'
                                : '${water.totalCups - water.cupsDrunk} cốc',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: water.cupsDrunk >= water.totalCups
                                  ? Colors.green.shade700
                                  : Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Add Buttons Header
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
                      Text(
                        'Thêm nước nhanh',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Add Buttons Grid
              FadeTransition(
                opacity: _staggerAnimations[3],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildWaterButton(
                        ml: 100,
                        icon: Icons.opacity,
                        color: Colors.blue,
                        onPressed: () => _addWaterWithFeedback(context, 100),
                      ),
                      _buildWaterButton(
                        ml: 200,
                        icon: Icons.water_drop,
                        color: Colors.cyan,
                        onPressed: () => _addWaterWithFeedback(context, 200),
                      ),
                      _buildWaterButton(
                        ml: 300,
                        icon: Icons.water_drop_outlined,
                        color: Colors.teal,
                        onPressed: () => _addWaterWithFeedback(context, 300),
                      ),
                      _buildWaterButton(
                        ml: 500,
                        icon: Icons.local_drink,
                        color: Colors.indigo,
                        onPressed: () => _addWaterWithFeedback(context, 500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Hourly Chart Section
              FadeTransition(
                opacity: _staggerAnimations[4],
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
                          Text(
                            'Thống kê theo giờ (Hôm nay)',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 200,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 200,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()} ml',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 4,
                                  getTitlesWidget: (value, meta) {
                                    final hour = value.toInt();
                                    return Text(
                                      '$hour:00',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _generateHourlySpots(water.hourlyIntake),
                                isCurved: true,
                                color: Colors.blue.shade600,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.blue.shade800,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade600.withOpacity(0.3),
                                      Colors.blue.shade600.withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Colors.blue.shade800,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toInt()} ml\n${spot.x.toInt()}:00',
                                      GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            minX: 0,
                            maxX: 23,
                            minY: 0,
                            maxY: _getMaxY(water.hourlyIntake.values),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Daily Chart Section (7 days)
              FadeTransition(
                opacity: _staggerAnimations[5],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Thống kê theo ngày (7 ngày gần nhất)',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.blue.shade50],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: water.mlGoal / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.blue.shade100,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: water.mlGoal / 5,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()} ml',
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue.shade600,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final dayIndex = value.toInt();
                                    final date = DateTime.now()
                                        .subtract(Duration(days: 6 - dayIndex));
                                    return Text(
                                      '${date.day}/${date.month}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue.shade600,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _generateDailySpots(water.dailyIntake),
                                isCurved: true,
                                color: Colors.blue.shade600,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.blue.shade800,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade600.withOpacity(0.3),
                                      Colors.blue.shade600.withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: water.mlGoal * 1.5,
                                  color: Colors.red.shade600,
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(
                                        top: 10, right: 10),
                                    style: GoogleFonts.poppins(
                                      color: Colors.red.shade600,
                                      fontSize: 12,
                                    ),
                                    labelResolver: (line) =>
                                        'Vượt mức: ${(water.mlGoal * 1.5).toInt()} ml',
                                  ),
                                ),
                                HorizontalLine(
                                  y: water.mlGoal,
                                  color: Colors.green.shade600,
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(
                                        top: 10, right: 10),
                                    style: GoogleFonts.poppins(
                                      color: Colors.green.shade600,
                                      fontSize: 12,
                                    ),
                                    labelResolver: (line) =>
                                        'Mục tiêu: ${water.mlGoal.toInt()} ml',
                                  ),
                                ),
                                HorizontalLine(
                                  y: water.mlGoal * 0.75,
                                  color: Colors.orange.shade600,
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(
                                        top: 10, right: 10),
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade600,
                                      fontSize: 12,
                                    ),
                                    labelResolver: (line) =>
                                        'Gần đạt: ${(water.mlGoal * 0.75).toInt()} ml',
                                  ),
                                ),
                              ],
                            ),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Colors.blue.shade800,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final dayIndex = spot.x.toInt();
                                    final date = DateTime.now()
                                        .subtract(Duration(days: 6 - dayIndex));
                                    return LineTooltipItem(
                                      '${spot.y.toInt()} ml\n${date.day}/${date.month}/${date.year}',
                                      GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: _getMaxDailyY(
                                water.dailyIntake.values, water.mlGoal),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Detailed Statistics
              FadeTransition(
                opacity: _staggerAnimations[5],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDetailedStatistics(waterProvider, water),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStatistics(
      WaterProvider waterProvider, WaterIntakeModel water) {
    final dailyStats = waterProvider.getDailyStats(DateTime.now());
    final monthlyStats = waterProvider.getMonthlyStats(
        DateTime.now().year, DateTime.now().month);

    final intake = dailyStats['intake'] ?? 0.0;
    final goal = dailyStats['goal'] ?? water.mlGoal;
    String dailyStatus;
    Color dailyStatusColor;
    if (intake > goal * 1.5) {
      dailyStatus = 'Vượt mức';
      dailyStatusColor = Colors.red;
    } else if (intake >= goal) {
      dailyStatus = 'Đạt';
      dailyStatusColor = Colors.green;
    } else if (intake >= goal * 0.75) {
      dailyStatus = 'Gần đạt';
      dailyStatusColor = Colors.orange;
    } else {
      dailyStatus = 'Chưa đạt';
      dailyStatusColor = Colors.grey;
    }

    final goalAchievement = monthlyStats['goalAchievement'] ?? 0.0;
    final averageDaily = monthlyStats['averageDaily'] ?? 0.0;
    Color monthlyColor =
        (goalAchievement >= 100) ? Colors.green : Colors.purple;
    if (averageDaily > goal * 1.5) {
      monthlyColor = Colors.red;
    }
    bool isTracking = (monthlyStats['daysTracked'] ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_outlined, color: Colors.deepPurple.shade400),
            const SizedBox(width: 8),
            Text(
              'Thống kê chi tiết',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.today, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text('Hôm nay',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Chip(
                    label: Text(dailyStatus,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: dailyStatusColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsInfoCard(
                        'Lượng nước',
                        '${intake.toInt()} ml',
                        Icons.local_drink,
                        (intake > goal * 1.5) ? Colors.red : Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsInfoCard('Mục tiêu', '${goal.toInt()} ml',
                        Icons.flag, Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.purple.shade400),
                  const SizedBox(width: 8),
                  Text('Tháng này',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Chip(
                    label: Text(
                        isTracking
                            ? '${goalAchievement.toStringAsFixed(1)}%'
                            : 'Chưa theo dõi',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: isTracking ? monthlyColor : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _buildStatsInfoCard(
                      'Tổng lượng',
                      '${monthlyStats['totalIntake'].toInt()} ml',
                      Icons.opacity,
                      Colors.deepPurple),
                  _buildStatsInfoCard(
                      'Trung bình/ngày',
                      '${averageDaily.toInt()} ml',
                      Icons.trending_up,
                      (averageDaily > goal * 1.5) ? Colors.red : Colors.pink),
                  _buildStatsInfoCard(
                      'Số ngày theo dõi',
                      '${monthlyStats['daysTracked']} ngày',
                      Icons.event_available,
                      Colors.orange),
                  _buildStatsInfoCard(
                      'Tỷ lệ mục tiêu',
                      '${goalAchievement.isNaN ? 0.0 : goalAchievement.toStringAsFixed(1)}%',
                      Icons.pie_chart,
                      Colors.teal),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatsInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.lerp(color, Colors.black, 0.4)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<FlSpot> _generateHourlySpots(Map<String, int> hourlyIntake) {
    List<FlSpot> spots = [];
    for (int i = 0; i < 24; i++) {
      String hourKey = '${i.toString().padLeft(2, '0')}:00';
      double ml = (hourlyIntake[hourKey] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), ml));
    }
    return spots;
  }

  List<FlSpot> _generateDailySpots(Map<String, int> dailyIntake) {
    List<FlSpot> spots = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toString().substring(0, 10);
      double ml = (dailyIntake[dateStr] ?? 0).toDouble();
      if (i == 0) {
        ml = _water.hourlyIntake.values
            .fold(0, (sum, val) => sum + val)
            .toDouble();
      }
      spots.add(FlSpot((6 - i).toDouble(), ml));
    }
    return spots;
  }

  WaterIntakeModel get _water =>
      Provider.of<WaterProvider>(context, listen: false).water;

  double _getMaxY(Iterable<int> values) {
    double maxY = 500;
    if (values.isNotEmpty) {
      maxY =
          values.reduce((curr, next) => curr > next ? curr : next).toDouble();
    }
    return (maxY / 200).ceil() * 200;
  }

  double _getMaxDailyY(Iterable<int> values, double goal) {
    double maxVal = goal * 1.6;
    if (values.isNotEmpty) {
      maxVal = max(
          maxVal,
          values.reduce((curr, next) => curr > next ? curr : next).toDouble() *
              1.1);
    }
    final interval = goal / 5;
    return (maxVal / interval).ceil() * interval;
  }

  Widget _buildWaterButton({
    required int ml,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  '+$ml',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ml',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addWaterWithFeedback(BuildContext context, int ml) {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    waterProvider.addWater(ml);
    HapticFeedback.mediumImpact();

    final dailyStats = waterProvider.getDailyStats(DateTime.now());
    final intake = dailyStats['intake'] ?? 0.0;
    final goal = dailyStats['goal'] ?? waterProvider.water.mlGoal;

    Color bgColor = Colors.blue.shade600;
    String message = 'Đã thêm $ml ml nước';
    IconData icon = Icons.check_circle;
    if (intake > goal * 1.5) {
      bgColor = Colors.red.shade600;
      message = 'Cảnh báo: Bạn đã vượt quá lượng nước khuyến nghị!';
      icon = Icons.warning;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
