import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/weight_model.dart';
import '../utils/helpers.dart';

class WeightProvider with ChangeNotifier {
  WeightModel _weight = WeightModel();

  WeightModel get weight => _weight;

  Future<void> loadWeight() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('weights').doc(uid).get();

      if (doc.exists) {
        _weight = WeightModel.fromJson(doc.data() as Map<String, dynamic>);
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

      // Calculate BMI with provided height
      newWeight.bmi = calculateBMI(
        newWeight.currentWeight,
        userHeight,
      );

      await FirebaseFirestore.instance
          .collection('weights')
          .doc(uid)
          .set(newWeight.toJson());

      _weight = newWeight;
      notifyListeners();
    } catch (e) {
      print('Error updating weight: $e');
      rethrow;
    }
  }
}
