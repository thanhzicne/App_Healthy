import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_model.dart';

class ChartWidget extends StatelessWidget {
  final List<WeightModel> weights;
  final bool isDaily; // True: biểu đồ trong ngày, False: biểu đồ 7 ngày

  const ChartWidget({
    super.key,
    required this.weights,
    this.isDaily = false,
  });

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const Center(child: Text('Không có dữ liệu.'));
    }

    // Tìm min, max cho trục Y
    final minY =
        weights.map((w) => w.currentWeight).reduce((a, b) => a < b ? a : b) - 2;
    final maxY =
        weights.map((w) => w.currentWeight).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY.floorToDouble(),
        maxY: maxY.ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: Color(0xffe7e7e7), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(color: Color(0xffe7e7e7), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: leftTitleWidgets)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: bottomTitleWidgets,
                  interval: 1)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xffe7e7e7), width: 1)),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade300]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade600.withOpacity(0.3),
                  Colors.orange.shade300.withOpacity(0.1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final weight = weights[spot.spotIndex];
                final formattedDate = isDaily
                    ? DateFormat('HH:mm').format(weight.dateTime)
                    : DateFormat('dd/MM').format(weight.dateTime);

                return LineTooltipItem(
                  '${weight.currentWeight.toStringAsFixed(1)} kg\n',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: formattedDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // Lấy danh sách các điểm để vẽ
  List<FlSpot> _getSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < weights.length; i++) {
      // Trục X sẽ là index, giá trị sẽ được format ở bottom titles
      spots.add(FlSpot(i.toDouble(), weights[i].currentWeight));
    }
    return spots;
  }

  // Widget cho tiêu đề trục Y (bên trái)
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (value == meta.max || value == meta.min) {
      return Container(); // Bỏ giá trị min/max để đỡ rối
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}kg',
          style: const TextStyle(color: Colors.grey, fontSize: 10)),
    );
  }

  // Widget cho tiêu đề trục X (bên dưới)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    String text;

    if (index < 0 || index >= weights.length) {
      return Container();
    }

    if (isDaily) {
      // Hiển thị giờ:phút cho biểu đồ trong ngày
      text = DateFormat('HH:mm').format(weights[index].dateTime);
    } else {
      // Hiển thị ngày/tháng cho biểu đồ 7 ngày
      text = DateFormat('dd/MM').format(weights[index].dateTime);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child:
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    );
  }
}
