import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/weight_model.dart';
import '../utils/helpers.dart';
import '../providers/user_provider.dart'; // Import UserProvider

class WeightProvider with ChangeNotifier {
  WeightModel _weight = WeightModel();

  WeightModel get weight => _weight;

  Future<void> loadWeight() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('weights')
        .doc(uid)
        .get();
    if (doc.exists) {
      _weight = WeightModel.fromJson(doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<void> updateWeight(WeightModel newWeight) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    // Lấy height từ UserProvider
    final userProvider = UserProvider();
    await userProvider.loadUser();
    newWeight.bmi = calculateBMI(
      newWeight.currentWeight,
      userProvider.user.height,
    );
    await FirebaseFirestore.instance
        .collection('weights')
        .doc(uid)
        .set(newWeight.toJson());
    _weight = newWeight;
    notifyListeners();
  }
}
