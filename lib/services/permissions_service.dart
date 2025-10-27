// lib/services/permissions_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  // Yêu cầu quyền ACTIVITY_RECOGNITION (Android 10+)
  static Future<bool> requestActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.request();

    String statusText;
    if (status.isGranted) {
      statusText = 'GRANTED';
    } else if (status.isDenied) {
      statusText = 'DENIED';
    } else if (status.isPermanentlyDenied) {
      statusText = 'PERMANENTLY_DENIED';
    } else {
      statusText = 'PENDING';
    }

    print("Activity Recognition Permission: $statusText");

    return status.isGranted;
  }

  // Kiểm tra trạng thái quyền
  static Future<bool> isActivityRecognitionGranted() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  // Yêu cầu tất cả quyền cần thiết
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    return statuses;
  }

  // Mở cài đặt ứng dụng
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}