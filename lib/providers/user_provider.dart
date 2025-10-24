import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel _user = UserModel(
    name: '',
    email: '',
    gender: '',
    age: 0,
    height: 0,
  );

  UserModel get user => _user;

  Future<void> loadUser() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      _user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<void> updateUser(UserModel newUser) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(newUser.toJson());
    _user = newUser;
    notifyListeners();
  }
}
