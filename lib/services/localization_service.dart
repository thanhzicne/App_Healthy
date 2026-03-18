import 'package:flutter/material.dart';

class LocalizationService {
  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      'settings': 'Cài đặt',
      'notifications': 'Thông báo',
      'water_reminder': 'Nhắc nhở uống nước',
      'water_subtitle': 'Nhận thông báo định kỳ',
      'steps_notification': 'Thông báo bước chân',
      'steps_subtitle': 'Cập nhật tiến độ bước chân',
      'weight_reminder': 'Nhắc nhở cân nặng',
      'weight_subtitle': 'Nhắc đo cân hàng tuần',
      'goals': 'Mục tiêu',
      'water_goal': 'Mục tiêu nước',
      'water_goal_subtitle': 'Đặt lượng nước cần uống',
      'steps_goal': 'Mục tiêu bước chân',
      'steps_goal_subtitle': 'Số bước mỗi ngày',
      'weight_goal': 'Mục tiêu cân nặng',
      'weight_goal_subtitle': 'Cân nặng mục tiêu',
      'appearance': 'Giao diện',
      'dark_mode': 'Chế độ tối',
      'dark_mode_subtitle': 'Giao diện tối dễ nhìn',
      'language': 'Ngôn ngữ',
      'data': 'Dữ liệu',
      'export_data': 'Xuất dữ liệu',
      'export_subtitle': 'Sao lưu dữ liệu của bạn',
      'delete_data': 'Xóa tất cả dữ liệu',
      'delete_subtitle': 'Không thể hoàn tác',
      'info': 'Thông tin',
      'about_app': 'Giới thiệu ứng dụng',
      'about_subtitle': 'Về HealthTracker',
      'terms': 'Điều khoản sử dụng',
      'terms_subtitle': 'Chính sách và điều khoản',
      'version': 'Phiên bản',
      'home': 'Trang chủ',
      'steps': 'Bước chân',
      'weight': 'Cân nặng',
      'water': 'Nước uống',
      'news': 'Tin tức',
      'profile': 'Hồ sơ',
    },
    'en': {
      'settings': 'Settings',
      'notifications': 'Notifications',
      'water_reminder': 'Water Reminder',
      'water_subtitle': 'Get periodic notifications',
      'steps_notification': 'Steps Notification',
      'steps_subtitle': 'Update steps progress',
      'weight_reminder': 'Weight Reminder',
      'weight_subtitle': 'Weekly weight reminder',
      'goals': 'Goals',
      'water_goal': 'Water Goal',
      'water_goal_subtitle': 'Set daily water intake',
      'steps_goal': 'Steps Goal',
      'steps_goal_subtitle': 'Daily steps target',
      'weight_goal': 'Weight Goal',
      'weight_goal_subtitle': 'Target weight',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'dark_mode_subtitle': 'Easy on the eyes',
      'language': 'Language',
      'data': 'Data',
      'export_data': 'Export Data',
      'export_subtitle': 'Backup your data',
      'delete_data': 'Delete All Data',
      'delete_subtitle': 'Cannot be undone',
      'info': 'Information',
      'about_app': 'About App',
      'about_subtitle': 'About HealthTracker',
      'terms': 'Terms of Use',
      'terms_subtitle': 'Policies and terms',
      'version': 'Version',
      'home': 'Home',
      'steps': 'Steps',
      'weight': 'Weight',
      'water': 'Water',
      'news': 'News',
      'profile': 'Profile',
    },
  };

  String translate(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ?? key;
  }
}

// Extension to make it easier to use
extension AppLocalizations on BuildContext {
  String tr(String key) => LocalizationService().translate(this, key);
}
