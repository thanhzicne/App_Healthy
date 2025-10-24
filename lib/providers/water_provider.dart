import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/water_intake_model.dart';

class WaterProvider with ChangeNotifier {
  WaterIntakeModel _water = WaterIntakeModel();

  WaterIntakeModel get water => _water;

  Future<void> loadWater() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('water_intakes')
        .doc(uid)
        .get();
    if (doc.exists) {
      _water = WaterIntakeModel.fromJson(doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<void> addWater(int ml) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    _water.cupsDrunk += (ml / 250).floor();
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('water_intakes')
        .doc(uid)
        .set(_water.toJson());
    notifyListeners();
  }
}
