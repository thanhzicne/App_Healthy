// weight_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/weight_model.dart';
import '../utils/helpers.dart';

class WeightProvider with ChangeNotifier {
  List<WeightModel> _weights = [];
  WeightModel _currentWeight = WeightModel();
  double _targetWeight = 0.0;

  // <<< THÊM MỚI: Cờ để xác định mục tiêu có phải do người dùng tự đặt không >>>
  bool _isTargetManuallySet = false;

  List<WeightModel> get weights => _weights;
  WeightModel get weight => _currentWeight;
  double get targetWeight => _targetWeight;
  // Getter để các nơi khác có thể đọc (không bắt buộc)
  bool get isTargetManuallySet => _isTargetManuallySet;

  Future<void> loadWeight() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('weights').doc(uid).get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        _weights = (data['history'] as List<dynamic>? ?? [])
            .map((json) => WeightModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _weights.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _currentWeight = _weights.isNotEmpty ? _weights.last : WeightModel();

        _targetWeight = (data['targetWeight'] as num? ?? 0.0).toDouble();

        // <<< THAY ĐỔI: Đọc cờ từ Firestore, nếu không có thì mặc định là false >>>
        _isTargetManuallySet = data['isTargetManuallySet'] ?? false;

        notifyListeners();
      }
    } catch (e) {
      print('Error loading weight: $e');
    }
  }

  Future<void> updateWeight(WeightModel newWeight, double userHeight) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      newWeight.bmi = calculateBMI(newWeight.currentWeight, userHeight);

      _weights.add(newWeight);
      _weights.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _currentWeight = newWeight;

      final Map<String, dynamic> dataToUpdate = {
        'history': _weights.map((w) => w.toJson()).toList()
      };

      // <<< THAY ĐỔI LOGIC: Chỉ tự động cập nhật mục tiêu nếu người dùng CHƯA TỰ ĐẶT >>>
      if (!_isTargetManuallySet && userHeight > 0) {
        final double heightInMeters = userHeight / 100;
        final double idealWeight = 22.0 * (heightInMeters * heightInMeters);
        _targetWeight = idealWeight; // Cập nhật state của provider
        dataToUpdate['targetWeight'] = idealWeight; // Thêm vào data để lưu
      }

      await FirebaseFirestore.instance.collection('weights').doc(uid).set(
            dataToUpdate,
            SetOptions(merge: true),
          );

      notifyListeners();
    } catch (e) {
      print('Error updating weight: $e');
      rethrow;
    }
  }

  // <<< THAY ĐỔI: Khi người dùng tự đặt mục tiêu, set cờ thành TRUE >>>
  Future<void> updateTargetWeight(double newTarget) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    if (newTarget <= 0) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      _targetWeight = newTarget;
      _isTargetManuallySet = true; // Đánh dấu là người dùng đã tự đặt

      await FirebaseFirestore.instance.collection('weights').doc(uid).set(
        {
          'targetWeight': newTarget,
          'isTargetManuallySet': true, // Lưu cờ vào Firestore
        },
        SetOptions(merge: true),
      );

      notifyListeners();
    } catch (e) {
      print('Error updating target weight: $e');
      rethrow;
    }
  }

  // <<< THÊM MỚI: Hàm để gọi khi chiều cao người dùng thay đổi >>>
  Future<void> updateIdealTargetAfterHeightChange(double newHeight) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    // Chỉ cập nhật nếu người dùng chưa tự đặt mục tiêu và chiều cao hợp lệ
    if (!_isTargetManuallySet && newHeight > 0) {
      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        final double heightInMeters = newHeight / 100;
        final double idealWeight = 22.0 * (heightInMeters * heightInMeters);

        _targetWeight = idealWeight; // Cập nhật state

        // Lưu mục tiêu mới vào Firestore
        await FirebaseFirestore.instance.collection('weights').doc(uid).set(
          {'targetWeight': idealWeight},
          SetOptions(merge: true),
        );
        notifyListeners();
      } catch (e) {
        print('Error updating ideal target after height change: $e');
      }
    }
  }
}
