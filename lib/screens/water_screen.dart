import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final waterProvider = Provider.of<WaterProvider>(context);
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

              // Daily Chart Section (30 days)
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
                            'Thống kê theo ngày (30 ngày gần nhất)',
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
                              horizontalInterval: water.mlGoal / 5,
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
                                  interval: water.mlGoal / 5,
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
                                  interval: 5,
                                  getTitlesWidget: (value, meta) {
                                    final dayIndex = value.toInt();
                                    final date = DateTime.now().subtract(
                                        Duration(days: 29 - dayIndex));
                                    return Text(
                                      '${date.day}/${date.month}',
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
                              // Actual intake line
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
                                // Balanced goal line
                                HorizontalLine(
                                  y: water.mlGoal,
                                  color: Colors.green.shade600,
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    style: GoogleFonts.poppins(
                                      color: Colors.green.shade600,
                                      fontSize: 12,
                                    ),
                                    padding: const EdgeInsets.all(4.0),
                                  ),
                                ),
                                // Over standard warning line (goal + 20%)
                                HorizontalLine(
                                  y: water.mlGoal * 1.2,
                                  color: Colors.red.shade600,
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red.shade600,
                                      fontSize: 12,
                                    ),
                                    padding: const EdgeInsets.all(4.0),
                                  ),
                                ),
                                // Under standard warning line (goal - 20%)
                                HorizontalLine(
                                  y: water.mlGoal * 0.8,
                                  color: Colors.orange.shade600,
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade600,
                                      fontSize: 12,
                                    ),
                                    padding: const EdgeInsets.all(4.0),
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
                                    final date = DateTime.now().subtract(
                                        Duration(days: 29 - dayIndex));
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
                            maxX: 29,
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

              // Statistics Section
              FadeTransition(
                opacity: _staggerAnimations[5],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thống kê',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsCard('Hôm nay',
                          waterProvider.getDailyStats(DateTime.now())),
                      const SizedBox(height: 12),
                      _buildStatsCard(
                          'Tháng này',
                          waterProvider.getMonthlyStats(
                              DateTime.now().year, DateTime.now().month)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, Map<String, dynamic> stats) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (stats.containsKey('intake'))
            Text(
              'Lượng nước: ${stats['intake']} ml',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          if (stats.containsKey('goal'))
            Text(
              'Mục tiêu: ${stats['goal'].toInt()} ml',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          if (stats.containsKey('status'))
            Text(
              'Trạng thái: ${stats['status']}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          if (stats.containsKey('totalIntake'))
            Text(
              'Tổng lượng nước: ${stats['totalIntake'].toInt()} ml',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          if (stats.containsKey('averageDaily'))
            Text(
              'Trung bình ngày: ${stats['averageDaily'].toInt()} ml',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          if (stats.containsKey('daysTracked'))
            Text(
              'Số ngày theo dõi: ${stats['daysTracked']}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          if (stats.containsKey('goalAchievement'))
            Text(
              'Tỷ lệ đạt mục tiêu: ${stats['goalAchievement'].toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
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
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toString().substring(0, 10);
      double ml = (dailyIntake[dateStr] ?? 0).toDouble();
      spots.add(FlSpot((29 - i).toDouble(), ml));
    }
    return spots;
  }

  double _getMaxY(Iterable<int> values) {
    double maxY = 500;
    for (var value in values) {
      if (value > maxY) maxY = value.toDouble();
    }
    return (maxY / 200).ceil() * 200;
  }

  double _getMaxDailyY(Iterable<int> values, double goal) {
    double maxY = goal * 1.5;
    for (var value in values) {
      if (value > maxY) maxY = value.toDouble();
    }
    return (maxY / (goal / 5)).ceil() * (goal / 5);
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
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ml',
                  style: GoogleFonts.poppins(
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
    Provider.of<WaterProvider>(context, listen: false).addWater(ml);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Snackbar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Đã thêm $ml ml nước',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
