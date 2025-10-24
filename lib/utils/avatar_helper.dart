import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel _user = UserModel(
    name: 'User',
    email: '',
    gender: '',
    age: 0,
    height: 0,
    avatarUrl: null,
  );

  UserModel get user => _user;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Load user data từ Firestore
  Future<void> loadUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          _user = UserModel.fromJson(doc.data() ?? {});
          notifyListeners();
        } else {
          // Nếu doc không tồn tại, tạo user mặc định
          _user = UserModel(
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            gender: '',
            age: 0,
            height: 0,
            avatarUrl: null,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user: $e');
      }
    }
  }

  // Update user info
  Future<void> updateUser(UserModel newUser) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(newUser.toJson(), SetOptions(merge: true));
        _user = newUser;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      rethrow;
    }
  }

  // Upload avatar lên Firebase Storage
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Xóa ảnh cũ nếu có
      if (_user.avatarUrl != null && _user.avatarUrl!.isNotEmpty) {
        await deleteOldAvatar(_user.avatarUrl!);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatars/${currentUser.uid}_$timestamp.jpg';

      final ref = _storage.ref().child(fileName);

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar: $e');
      }
      rethrow;
    }
  }

  // Update user avatar URL
  Future<void> updateUserAvatar(String avatarUrl) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({'avatarUrl': avatarUrl});

        _user = UserModel(
          name: _user.name,
          email: _user.email,
          gender: _user.gender,
          age: _user.age,
          height: _user.height,
          avatarUrl: avatarUrl,
        );

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating avatar: $e');
      }
      rethrow;
    }
  }

  // Delete old avatar
  Future<void> deleteOldAvatar(String avatarUrl) async {
    try {
      if (avatarUrl.isNotEmpty) {
        final ref = _storage.refFromURL(avatarUrl);
        await ref.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting old avatar: $e');
      }
    }
  }
}
