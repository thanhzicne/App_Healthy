import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/steps_model.dart';

class StepsProvider with ChangeNotifier {
  StepsModel _steps = StepsModel();

  StepsModel get steps => _steps;

  Future<void> loadSteps() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('steps')
        .doc(uid)
        .get();
    if (doc.exists) {
      _steps = StepsModel.fromJson(doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<void> updateSteps(StepsModel newSteps) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('steps')
        .doc(uid)
        .set(newSteps.toJson());
    _steps = newSteps;
    notifyListeners();
  }
}
