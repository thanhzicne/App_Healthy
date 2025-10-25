import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weight_provider.dart';
import '../providers/user_provider.dart';
import '../models/weight_model.dart';
import '../widgets/chart_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen>
    with SingleTickerProviderStateMixin {
  final weightController = TextEditingController();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeightProvider>().loadWeight();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    weightController.dispose();
    super.dispose();
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final weightProvider = context.watch<WeightProvider>();
    final weight = weightProvider.weight;
    final targetWeight = weightProvider.targetWeight;
    final weights = weightProvider.weights; // Lấy danh sách cân nặng

    final bmiCategory = _getBMICategory(weight.bmi);
    final bmiColor = _getBMIColor(weight.bmi);

    final now = DateTime.now();
    final todayWeights = weights
        .where((w) =>
            w.dateTime.year == now.year &&
            w.dateTime.month == now.month &&
            w.dateTime.day == now.day)
        .toList();

    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final recent =
        weights.where((w) => !w.dateTime.isBefore(sevenDaysAgo)).toList();
    final dailyLast = <String, WeightModel>{};
    for (final w in recent) {
      final dayKey = DateFormat('yyyy-MM-dd').format(w.dateTime);
      dailyLast[dayKey] = w;
    }
    final sevenDayWeights = dailyLast.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final double currentWeight = weight.currentWeight;

    String goalLabel;
    double weightDifference;
    IconData goalIcon;
    Color goalColor;

    if (currentWeight > 0 && currentWeight > targetWeight) {
      goalLabel = 'Cần giảm';
      weightDifference = currentWeight - targetWeight;
      goalIcon = Icons.trending_down;
      goalColor = Colors.red;
    } else if (currentWeight > 0 && currentWeight < targetWeight) {
      goalLabel = 'Cần tăng';
      weightDifference = targetWeight - currentWeight;
      goalIcon = Icons.trending_up;
      goalColor = Colors.green;
    } else {
      goalLabel = 'Đạt mục tiêu';
      weightDifference = 0;
      goalIcon = Icons.check_circle_outline;
      goalColor = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cân nặng',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent, // Nền trong suốt
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade600, // Màu cam đậm
                Colors.amber.shade500 // Màu vàng hổ phách
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Lịch sử cân nặng',
            onPressed: () {
              // --- TOÀN BỘ LOGIC HIỂN THỊ LỊCH SỬ NẰM Ở ĐÂY ---

              // Lấy provider (đã có sẵn trong hàm build)
              final weightProvider = context.read<WeightProvider>();
              final allWeights = weightProvider.weights;

              // Sắp xếp danh sách, mới nhất lên trước
              allWeights.sort((a, b) => b.dateTime.compareTo(a.dateTime));

              // Lấy 5 mục gần nhất
              final recentWeights = allWeights.take(5).toList();

              // Hiển thị Bottom Sheet
              showModalBottomSheet(
                context: context, // Sử dụng context có sẵn từ hàm build
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext bottomSheetContext) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch sử cân nặng (5 lần gần nhất)',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (recentWeights.isEmpty)
                          Center(
                            child: Text(
                              'Chưa có dữ liệu nào.',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            itemCount: recentWeights.length,
                            itemBuilder: (context, index) {
                              final weightEntry = recentWeights[index];
                              // Định dạng ngày tháng
                              final formattedDate =
                                  DateFormat('dd/MM/yyyy - hh:mm a')
                                      .format(weightEntry.dateTime);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(Icons.monitor_weight_outlined,
                                      color: Colors.orange.shade800),
                                ),
                                title: Text(
                                  '${weightEntry.currentWeight.toStringAsFixed(1)} kg',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                          ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            child: Text(
                              'Đóng',
                              style: GoogleFonts.poppins(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
              // --- KẾT THÚC LOGIC HIỂN THỊ LỊCH SỬ ---
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FadeTransition(
                opacity: _staggerAnimations[0], child: _buildMainCard(weight)),

            // <<< THAY ĐỔI: KIỂM TRA ĐỂ ẨN/HIỆN THẺ BMI VÀ MỤC TIÊU >>>
            // Chỉ hiển thị các thẻ này nếu đã có dữ liệu cân nặng
            if (weights.isNotEmpty) ...[
              FadeTransition(
                  opacity: _staggerAnimations[1],
                  child: _buildBMICard(bmiCategory, bmiColor, weight.bmi)),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _staggerAnimations[2],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showTargetDialog(context),
                          borderRadius: BorderRadius.circular(16),
                          child: _buildInfoCard(
                              Icons.flag_outlined,
                              'Mục tiêu',
                              '${targetWeight.toStringAsFixed(1)} kg',
                              Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildInfoCard(
                              goalIcon,
                              goalLabel,
                              '${weightDifference.toStringAsFixed(1)} kg',
                              goalColor)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            FadeTransition(
              opacity: _staggerAnimations[3],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showWeightDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Cập nhật cân nặng',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _staggerAnimations[4],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.timeline,
                          color: Colors.orange.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text('Biểu đồ trong ngày',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: todayWeights.isEmpty
                          ? const Center(
                              child: Text(
                                  'Chưa có dữ liệu hôm nay\n(Cập nhật để xem biểu đồ)',
                                  textAlign: TextAlign.center))
                          : ChartWidget(weights: todayWeights, isDaily: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _staggerAnimations[5],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.bar_chart,
                          color: Colors.orange.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text('Biểu đồ 7 ngày',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: sevenDayWeights.isEmpty
                          ? const Center(
                              child: Text(
                                  'Chưa có dữ liệu 7 ngày\n(Cập nhật nhiều ngày để xem)',
                                  textAlign: TextAlign.center))
                          : ChartWidget(
                              weights: sevenDayWeights, isDaily: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Các hàm build UI và dialog không thay đổi so với phiên bản trước
  Widget _buildMainCard(WeightModel weight) {
    return SlideTransition(
      position:
          Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.orange.shade300, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('Cân nặng hiện tại',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(
                  begin:
                      weight.currentWeight > 0 ? weight.currentWeight - 5 : 0,
                  end: weight.currentWeight),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) => Text(
                  '${value.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(height: 8),
            const Text('kg',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBMICard(String category, Color color, double bmi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2)),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chỉ số BMI',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: bmi > 2 ? bmi - 2 : 0, end: bmi),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) => Text(
                      '${value.toStringAsFixed(1)}',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ]),
              Container(
                decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(category,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (bmi / 40).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                )),
            const SizedBox(height: 10),
            const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thiếu cân',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                  Text('Bình thường',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                  Text('Thừa cân',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                  Text('Béo phì',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 10),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ]),
    );
  }

  void _showTargetDialog(BuildContext context) {
    final weightProvider = context.read<WeightProvider>();
    final userProvider = context.read<UserProvider>();

    final targetController = TextEditingController();
    targetController.text = weightProvider.targetWeight.toStringAsFixed(1);

    final double userHeight = userProvider.user.height;

    Widget suggestionWidget = const SizedBox.shrink();
    if (userHeight > 0) {
      final double heightInMeters = userHeight / 100;
      final double lowerBound = 18.5 * (heightInMeters * heightInMeters);
      final double upperBound = 24.9 * (heightInMeters * heightInMeters);
      final double idealWeight = 22.0 * (heightInMeters * heightInMeters);

      suggestionWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gợi ý: Cân nặng lý tưởng của bạn là từ ${lowerBound.toStringAsFixed(1)} kg đến ${upperBound.toStringAsFixed(1)} kg.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: Icon(Icons.lightbulb_outline, size: 16),
              label: Text('Áp dụng mục tiêu lý tưởng'),
              onPressed: () {
                targetController.text = idealWeight.toStringAsFixed(1);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                alignment: Alignment.center,
              ),
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.flag_outlined, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          const Text('Đặt mục tiêu cân nặng')
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetController,
                decoration: InputDecoration(
                  labelText: 'Mục tiêu (kg)',
                  prefixIcon:
                      Icon(Icons.scale_outlined, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.blue.shade600, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              suggestionWidget,
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Hủy', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () {
              final newTarget = double.tryParse(targetController.text) ??
                  weightProvider.targetWeight;

              weightProvider.updateTargetWeight(newTarget);

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final weightProvider = context.read<WeightProvider>();
    final userProvider = context.read<UserProvider>();
    weightController.text = weightProvider.weight.currentWeight > 0
        ? weightProvider.weight.currentWeight.toStringAsFixed(1)
        : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.scale, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          const Text('Cập nhật cân nặng')
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: weightController,
            decoration: InputDecoration(
              labelText: 'Cân nặng (kg)',
              prefixIcon:
                  Icon(Icons.scale_outlined, color: Colors.orange.shade600),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.orange.shade600, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Nhập cân nặng hiện tại của bạn',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade700))),
            ]),
          ),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Hủy', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () {
              final newWeightValue =
                  double.tryParse(weightController.text) ?? 0;
              if (newWeightValue > 0) {
                final newWeight = WeightModel(currentWeight: newWeightValue);
                weightProvider.updateWeight(
                    newWeight, userProvider.user.height);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Cập nhật thành công',
                        style: TextStyle(fontWeight: FontWeight.w600))
                  ]),
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: const Text('Lưu',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
