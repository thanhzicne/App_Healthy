import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/weight_model.dart';
import '../utils/helpers.dart';

class WeightProvider with ChangeNotifier {
  List<WeightModel> _weights = [];
  WeightModel _currentWeight = WeightModel();

  List<WeightModel> get weights => _weights;
  WeightModel get weight => _currentWeight;

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
        // Sort theo dateTime tăng dần
        _weights.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _currentWeight = _weights.isNotEmpty ? _weights.last : WeightModel();
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

      // Calculate BMI
      newWeight.bmi = calculateBMI(newWeight.currentWeight, userHeight);

      // Update history
      _weights.add(newWeight);
      // Sort lại
      _weights.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _currentWeight = newWeight;

      await FirebaseFirestore.instance
          .collection('weights')
          .doc(uid)
          .set({'history': _weights.map((w) => w.toJson()).toList()});

      notifyListeners();
    } catch (e) {
      print('Error updating weight: $e');
      rethrow;
    }
  }
}
