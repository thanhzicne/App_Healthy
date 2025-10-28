import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/steps_provider.dart';
import '../services/notification_service.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _waterNotifications = true;
  bool _stepsNotifications = true;
  bool _weightNotifications = true;
  bool _darkMode = false;
  String _language = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cài đặt',
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
              colors: [Colors.blue.shade600, Colors.lightBlue.shade400],
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔔 PHẦN THÔNG BÁO
          _buildSectionHeader(
            icon: Icons.notifications_active,
            title: 'Thông báo',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(),

          const SizedBox(height: 24),

          // 🎯 PHẦN MỤC TIÊU
          _buildSectionHeader(
            icon: Icons.flag,
            title: 'Mục tiêu',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildGoalsCard(),

          const SizedBox(height: 24),

          // 🎨 PHẦN GIAO DIỆN
          _buildSectionHeader(
            icon: Icons.palette,
            title: 'Giao diện',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildAppearanceCard(),

          const SizedBox(height: 24),

          // 💾 PHẦN DỮ LIỆU
          _buildSectionHeader(
            icon: Icons.storage,
            title: 'Dữ liệu',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildDataCard(),

          const SizedBox(height: 24),

          // ℹ️ PHẦN THÔNG TIN
          _buildSectionHeader(
            icon: Icons.info_outline,
            title: 'Thông tin',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ✅ WIDGET: Section Header
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required MaterialColor color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.shade300, color.shade500],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // 🔔 CARD THÔNG BÁO
  Widget _buildNotificationCard() {
    final weightProvider = context.watch<WeightProvider>();
    final stepsProvider = context.watch<StepsProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Nhắc nhở uống nước',
            subtitle: 'Nhận thông báo định kỳ',
            value: _waterNotifications,
            onChanged: (value) {
              setState(() => _waterNotifications = value);
              if (value) {
                context.read<WaterProvider>().initializeDailyReminders();
                _showSnackBar('✅ Đã bật nhắc nhở uống nước');
              } else {
                context.read<WaterProvider>().cancelAllNotifications();
                _showSnackBar('❌ Đã tắt nhắc nhở uống nước');
              }
            },
            icon: Icons.water_drop,
            color: Colors.blue,
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            title: 'Thông báo bước chân',
            subtitle: 'Cập nhật tiến độ bước chân',
            value: _stepsNotifications, // (Tạm thời vẫn dùng biến local, xem ghi chú)
            onChanged: (value) {
              setState(() => _stepsNotifications = value);
              final notificationService = NotificationService(); // <-- Thêm
              if (value) {
                // Hẹn lịch nhắc nhở (ví dụ)
                notificationService.scheduleDailyStepsReminders(); // <-- Thêm
                _showSnackBar('✅ Đã bật thông báo bước chân');
              } else {
                // Hủy lịch nhắc nhở
                notificationService.cancelStepsReminders(); // <-- Thêm
                _showSnackBar('❌ Đã tắt thông báo bước chân');
              }
            },
            icon: Icons.directions_walk,
            color: Colors.purple,
          ),
          const Divider(height: 1),

          _buildSwitchTile(
            title: 'Nhắc nhở cân nặng',
            subtitle: 'Nhắc đo cân hàng tuần',
            value: weightProvider.isReminderEnabled, // <-- Sửa: Dùng provider
            onChanged: (value) {
              // Lấy cân nặng và mục tiêu (cần cho hàm toggle)
              final currentWeight = context.read<WeightProvider>().weight.currentWeight;
              final targetWeight = context.read<WeightProvider>().targetWeight;

              // Gọi hàm toggle từ provider
              context.read<WeightProvider>().toggleWeeklyReminder(
                  currentWeight,
                  targetWeight
              );

              // SnackBar sẽ được hiển thị từ weight_screen,
              // nhưng nếu muốn, bạn vẫn có thể hiện 1 SnackBar ở đây
              _showSnackBar(
                  value ? '✅ Đã bật nhắc nhở cân nặng' : '❌ Đã tắt nhắc nhở cân nặng'
              );
            },
            icon: Icons.monitor_weight,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  // 🎯 CARD MỤC TIÊU
  Widget _buildGoalsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionTile(
            title: 'Mục tiêu nước',
            subtitle: 'Đặt lượng nước cần uống',
            icon: Icons.local_drink,
            color: Colors.blue,
            onTap: () => _showWaterGoalDialog(),
          ),
          const Divider(height: 1),
          _buildOptionTile(
            title: 'Mục tiêu bước chân',
            subtitle: 'Số bước mỗi ngày',
            icon: Icons.directions_run,
            color: Colors.purple,
            onTap: () => _showStepsGoalDialog(),
          ),
          const Divider(height: 1),
          _buildOptionTile(
            title: 'Mục tiêu cân nặng',
            subtitle: 'Cân nặng mục tiêu',
            icon: Icons.flag,
            color: Colors.orange,
            onTap: () => _showWeightGoalDialog(),
          ),
        ],
      ),
    );
  }

  // 🎨 CARD GIAO DIỆN
  Widget _buildAppearanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Chế độ tối',
            subtitle: 'Giao diện tối dễ nhìn',
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _showSnackBar('🌙 Chức năng đang phát triển');
            },
            icon: Icons.dark_mode,
            color: Colors.indigo,
          ),
          const Divider(height: 1),
          _buildOptionTile(
            title: 'Ngôn ngữ',
            subtitle: _language,
            icon: Icons.language,
            color: Colors.teal,
            onTap: () => _showLanguageDialog(),
          ),
        ],
      ),
    );
  }

  // 💾 CARD DỮ LIỆU
  Widget _buildDataCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionTile(
            title: 'Xuất dữ liệu',
            subtitle: 'Sao lưu dữ liệu của bạn',
            icon: Icons.download,
            color: Colors.green,
            onTap: () => _showExportDialog(),
          ),
          const Divider(height: 1),
          _buildOptionTile(
            title: 'Xóa tất cả dữ liệu',
            subtitle: 'Không thể hoàn tác',
            icon: Icons.delete_forever,
            color: Colors.red,
            onTap: () => _showDeleteConfirmation(),
          ),
        ],
      ),
    );
  }

  // ℹ️ CARD THÔNG TIN
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionTile(
            title: 'Giới thiệu ứng dụng',
            subtitle: 'Về HealthTracker',
            icon: Icons.info,
            color: Colors.blue,
            onTap: () => _showAboutDialog(),
          ),
          const Divider(height: 1),
          _buildOptionTile(
            title: 'Điều khoản sử dụng',
            subtitle: 'Chính sách và điều khoản',
            icon: Icons.description,
            color: Colors.blueGrey,
            onTap: () => _showTermsDialog(),
          ),
          const Divider(height: 1),
          _buildOptionTile(
            title: 'Phiên bản',
            subtitle: 'v1.0.0',
            icon: Icons.code,
            color: Colors.grey,
            onTap: null,
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET: Switch Tile
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  required MaterialColor color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  // ✅ WIDGET: Option Tile
  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
          : null,
      onTap: onTap,
    );
  }

  // 🎯 DIALOG: Mục tiêu nước
  void _showWaterGoalDialog() {
    final waterProvider = context.read<WaterProvider>();
    final controller = TextEditingController(
      text: waterProvider.water.mlGoal.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mục tiêu nước'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Lượng nước (ml)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text) ?? 2000;
              waterProvider.updateGoal(newGoal);
              // Cập nhật mục tiêu nước
              _showSnackBar('✅ Đã cập nhật mục tiêu nước');
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // 🎯 DIALOG: Mục tiêu bước chân
  void _showStepsGoalDialog() {
    final stepsProvider = context.read<StepsProvider>();
    final controller = TextEditingController(
      text: stepsProvider.steps.goal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mục tiêu bước chân'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số bước',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text) ?? 10000;
              stepsProvider.updateGoal(newGoal);
              _showSnackBar('✅ Đã cập nhật mục tiêu bước chân');
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // 🎯 DIALOG: Mục tiêu cân nặng
  void _showWeightGoalDialog() {
    final weightProvider = context.read<WeightProvider>();
    final controller = TextEditingController(
      text: weightProvider.targetWeight.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mục tiêu cân nặng'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cân nặng (kg)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = double.tryParse(controller.text) ?? 60.0;
              weightProvider.updateTargetWeight(newGoal);
              _showSnackBar('✅ Đã cập nhật mục tiêu cân nặng');
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // 🌐 DIALOG: Ngôn ngữ
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'Tiếng Việt',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
                _showSnackBar('✅ Đã chuyển sang Tiếng Việt');
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
                _showSnackBar('✅ Changed to English');
              },
            ),
          ],
        ),
      ),
    );
  }

  // 📤 DIALOG: Xuất dữ liệu
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất dữ liệu'),
        content: const Text('Xuất dữ liệu sang file JSON hoặc CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('📥 Đã xuất dữ liệu thành công');
            },
            child: const Text('Xuất'),
          ),
        ],
      ),
    );
  }

  // 🗑️ DIALOG: Xóa dữ liệu
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Cảnh báo'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa TẤT CẢ dữ liệu?\n\nHành động này không thể hoàn tác!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Xóa tất cả dữ liệu
              await context.read<WaterProvider>().clearAllData();
              await context.read<StepsProvider>().clearAllData();
              await context.read<WeightProvider>().clearAllData();

              if (!mounted) return;
              Navigator.pop(context);
              _showSnackBar('🗑️ Đã xóa tất cả dữ liệu');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ℹ️ DIALOG: Giới thiệu
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Về HealthTracker'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏥 HealthTracker v1.0.0',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ứng dụng theo dõi sức khỏe toàn diện với các tính năng:',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('💧 Theo dõi lượng nước uống'),
              _buildFeatureItem('👟 Đếm bước chân'),
              _buildFeatureItem('⚖️ Quản lý cân nặng'),
              _buildFeatureItem('📊 Thống kê chi tiết'),
              _buildFeatureItem('🔔 Nhắc nhở thông minh'),
              const SizedBox(height: 16),
              Text(
                '© 2025 HealthTracker Team',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // 📄 DIALOG: Điều khoản
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều khoản sử dụng'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Quyền riêng tư\n'
                'Chúng tôi cam kết bảo mật dữ liệu của bạn.\n\n'
                '2. Sử dụng dữ liệu\n'
                'Dữ liệu chỉ được sử dụng cho mục đích theo dõi sức khỏe.\n\n'
                '3. Trách nhiệm\n'
                'Ứng dụng chỉ mang tính chất tham khảo, không thay thế ý kiến bác sĩ.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}