import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
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
          // Nếu doc không tồn tại, tạo user mặc định và lưu vào Firestore
          _user = UserModel(
            name: currentUser.displayName ?? 'Tên người dùng',
            email: currentUser.email ?? '',
            gender: 'Chưa cập nhật',
            age: 0,
            height: 0,
            avatarUrl: currentUser.photoURL,
          );
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set(_user.toJson());
          notifyListeners();
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

  // Upload avatar lên Firebase Storage (Mobile)
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Xóa ảnh cũ nếu có
      if (_user.avatarUrl != null && _user.avatarUrl!.isNotEmpty) {
        try {
          await deleteOldAvatar(_user.avatarUrl!);
        } catch (e) {
          if (kDebugMode) {
            print('Could not delete old avatar: $e');
          }
        }
      }

      // Tạo reference cho file mới
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatars/${currentUser.uid}_$timestamp.jpg';
      final ref = _storage.ref().child(fileName);

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      if (kDebugMode) {
        print('Avatar uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar: $e');
      }
      rethrow;
    }
  }

  // Upload avatar lên Firebase Storage (Web)
  Future<String> uploadAvatarWeb(Uint8List imageBytes) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Xóa ảnh cũ nếu có
      if (_user.avatarUrl != null && _user.avatarUrl!.isNotEmpty) {
        try {
          await deleteOldAvatar(_user.avatarUrl!);
        } catch (e) {
          if (kDebugMode) {
            print('Could not delete old avatar: $e');
          }
        }
      }

      // Tạo reference cho file mới
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatars/${currentUser.uid}_$timestamp.jpg';
      final ref = _storage.ref().child(fileName);

      // Upload bytes (for web)
      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      if (kDebugMode) {
        print('Avatar uploaded successfully (Web): $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar (Web): $e');
      }
      rethrow;
    }
  }

  // --- PHẦN HOÀN THIỆN ---

  // Update user avatar URL trong Firestore
  Future<void> updateUserAvatar(String avatarUrl) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      // Cập nhật lại field 'avatarUrl' trong Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'avatarUrl': avatarUrl});

      // Cập nhật lại state của provider
      _user = _user.copyWith(avatarUrl: avatarUrl);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating avatar URL: $e');
      }
      rethrow;
    }
  }

  // Xóa avatar cũ trên Firebase Storage
  Future<void> deleteOldAvatar(String oldUrl) async {
    try {
      // Chỉ xóa nếu URL là của Firebase Storage
      if (oldUrl.contains('firebasestorage.googleapis.com')) {
        final ref = _storage.refFromURL(oldUrl);
        await ref.delete();
        if (kDebugMode) {
          print('Old avatar deleted successfully.');
        }
      }
    } catch (e) {
      // Bỏ qua lỗi nếu file không tồn tại (ví dụ: đã bị xóa thủ công)
      if (e is FirebaseException && e.code == 'object-not-found') {
        if (kDebugMode) {
          print('Old avatar not found, skipping delete.');
        }
      } else {
        rethrow;
      }
    }
  }
}
