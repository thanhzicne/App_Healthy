// steps_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/steps_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepsHistoryScreen extends StatefulWidget {
  final List<DailySteps> dailySteps;

  const StepsHistoryScreen({
    super.key,
    required this.dailySteps,
  });

  @override
  State<StepsHistoryScreen> createState() => _StepsHistoryScreenState();
}

class _StepsHistoryScreenState extends State<StepsHistoryScreen> {
  Map<String, List<HourlySteps>> hourlyDataCache = {};
  String filterPeriod = 'week'; // week, month, all

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Lấy dữ liệu hourly cho một ngày cụ thể
  Future<List<HourlySteps>> _loadHourlyData(DateTime date) async {
    if (uid == null) return [];

    final dateKey = '${date.year}-${date.month}-${date.day}';

    // Kiểm tra cache
    if (hourlyDataCache.containsKey(dateKey)) {
      return hourlyDataCache[dateKey]!;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('stepsData')
          .doc('history')
          .collection('daily')
          .doc(dateKey)
          .collection('hourly')
          .orderBy('hour')
          .get();

      final hourlyData =
          snapshot.docs.map((doc) => HourlySteps.fromJson(doc.data())).toList();

      hourlyDataCache[dateKey] = hourlyData;
      return hourlyData;
    } catch (e) {
      print('Error loading hourly data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter dữ liệu theo khoảng thời gian
    List<DailySteps> filteredSteps = _filterStepsByPeriod();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch sử bước chân',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: filteredSteps.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu lịch sử',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Filter buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFilterButton('Tuần', 'week'),
                        _buildFilterButton('Tháng', 'month'),
                        _buildFilterButton('Tất cả', 'all'),
                      ],
                    ),
                  ),

                  // Statistics summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStatsSummary(filteredSteps),
                  ),

                  const SizedBox(height: 16),

                  // Daily list
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredSteps.length,
                    itemBuilder: (context, index) {
                      final data = filteredSteps[index];
                      return _buildDayCard(data);
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterButton(String label, String period) {
    final isActive = filterPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepPurple.shade400],
                )
              : null,
          color: isActive ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  List<DailySteps> _filterStepsByPeriod() {
    final now = DateTime.now();
    final sortedSteps = List<DailySteps>.from(widget.dailySteps)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (filterPeriod == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return sortedSteps.where((step) => step.date.isAfter(weekAgo)).toList();
    } else if (filterPeriod == 'month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return sortedSteps.where((step) => step.date.isAfter(monthAgo)).toList();
    }
    return sortedSteps;
  }

  Widget _buildStatsSummary(List<DailySteps> filteredSteps) {
    int totalSteps = 0;
    double totalCalories = 0.0;
    double totalDistance = 0.0;
    int daysWithGoal = 0;

    for (final step in filteredSteps) {
      totalSteps += step.steps;
      totalCalories += step.calories;
      totalDistance += step.distance;
      if (step.steps >= 10000) daysWithGoal++;
    }

    final avgSteps =
        filteredSteps.isEmpty ? 0 : (totalSteps / filteredSteps.length).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  'Tổng bước', '$totalSteps', Icons.directions_walk),
              _buildSummaryItem('TB/ngày', '$avgSteps', Icons.trending_up),
              _buildSummaryItem('Đạt mục tiêu',
                  '$daysWithGoal/${filteredSteps.length}', Icons.check_circle),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  'Calo',
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  Icons.local_fire_department),
              _buildSummaryItem('Quãng đường',
                  '${totalDistance.toStringAsFixed(2)} km', Icons.map),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DailySteps data) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'vi_VN').format(data.date);
    final progressPercent = (data.steps / 10000 * 100).clamp(0.0, 100.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade200,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: data.steps >= 10000
                            ? [Colors.green.shade400, Colors.teal.shade400]
                            : [Colors.amber.shade400, Colors.orange.shade400],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data.steps >= 10000 ? '✓ Đạt mục tiêu' : '○ Chưa đạt',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    data.steps >= 10000
                        ? Colors.green.shade400
                        : Colors.purple.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.steps} / 10,000 bước',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.directions_walk,
                      label: 'Bước chân',
                      value: '${data.steps}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Calo',
                      value: '${data.calories.toStringAsFixed(1)} kcal',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.map_outlined,
                      label: 'Quãng đường',
                      value: '${data.distance.toStringAsFixed(2)} km',
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            FutureBuilder<List<HourlySteps>>(
              future: _loadHourlyData(data.date),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Không có dữ liệu theo giờ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                final hourlyData = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        'Chi tiết theo giờ:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    ...hourlyData
                        .map((hourly) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(hourly.hour),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${hourly.steps} bước',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
