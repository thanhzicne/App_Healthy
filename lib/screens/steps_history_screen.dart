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
      body: widget.dailySteps.isEmpty
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.dailySteps.length,
              itemBuilder: (context, index) {
                final data = widget.dailySteps[index];
                return _buildDayCard(data);
              },
            ),
    );
  }

  Widget _buildDayCard(DailySteps data) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'vi_VN').format(data.date);

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
                                  Text(
                                    '${hourly.steps} bước',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
