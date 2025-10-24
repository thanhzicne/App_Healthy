// file: user_provider.dart

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

  // Tải dữ liệu người dùng từ Firestore
  Future<void> loadUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          _user = UserModel.fromJson(doc.data() ?? {});

          // FIX: Kiểm tra và sửa avatarUrl không hợp lệ
          if (_user.avatarUrl != null &&
              _user.avatarUrl!.isNotEmpty &&
              !_user.avatarUrl!.contains('firebasestorage.googleapis.com')) {
            if (kDebugMode) {
              print('Invalid avatarUrl detected, clearing: ${_user.avatarUrl}');
            }
            // Xóa avatarUrl không hợp lệ
            _user = _user.copyWith(avatarUrl: null);
            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .update({'avatarUrl': null});
          }

          notifyListeners();
        } else {
          // Nếu doc không tồn tại, tạo user mặc định và lưu vào Firestore
          _user = UserModel(
            name: currentUser.displayName ?? 'Tên người dùng',
            email: currentUser.email ?? '',
            gender: 'Chưa cập nhật',
            age: 0,
            height: 0,
            avatarUrl: null, // Không dùng photoURL từ Google
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

  // Cập nhật thông tin người dùng
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

  // --- PHẦN ĐÃ TÁI CẤU TRÚC (REFACTORED & FIXED) ---

  // Hàm private xử lý logic upload chung cho cả Mobile và Web
  Future<String> _internalUploadAvatar(
      {File? imageFile, Uint8List? imageBytes}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // DEBUG: In ra avatarUrl hiện tại
      if (kDebugMode) {
        print('Current avatarUrl before upload: ${_user.avatarUrl}');
      }

      // 1. Tạo reference cho file mới TRƯỚC
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatars/${currentUser.uid}_$timestamp.jpg';
      final ref = _storage.ref().child(fileName);

      if (kDebugMode) {
        print('Uploading to: $fileName');
      }

      // 2. Upload file tùy theo nền tảng
      if (kIsWeb && imageBytes != null) {
        // Upload cho Web
        await ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (!kIsWeb && imageFile != null) {
        // Upload cho Mobile
        await ref.putFile(imageFile);
      } else {
        throw Exception('Image data is missing or invalid for the platform.');
      }

      // 3. Lấy URL để tải về
      final downloadUrl = await ref.getDownloadURL();

      if (kDebugMode) {
        print('Avatar uploaded successfully: $downloadUrl');
      }

      // 4. XÓA ảnh cũ SAU KHI upload thành công
      // Chỉ xóa nếu có URL và URL hợp lệ
      if (_user.avatarUrl != null &&
          _user.avatarUrl!.isNotEmpty &&
          _user.avatarUrl!.contains('firebasestorage.googleapis.com')) {
        if (kDebugMode) {
          print('Attempting to delete old avatar: ${_user.avatarUrl}');
        }
        await deleteOldAvatar(_user.avatarUrl!);
      } else {
        if (kDebugMode) {
          print('No valid old avatar to delete');
        }
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar: $e');
      }
      rethrow;
    }
  }

  // Hàm public cho Mobile, gọi đến hàm xử lý chung
  Future<String> uploadAvatar(File imageFile) async {
    return _internalUploadAvatar(imageFile: imageFile);
  }

  // Hàm public cho Web, gọi đến hàm xử lý chung
  Future<String> uploadAvatarWeb(Uint8List imageBytes) async {
    return _internalUploadAvatar(imageBytes: imageBytes);
  }

  // Cập nhật URL avatar của người dùng trong Firestore
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
      // Chỉ xóa nếu URL là của Firebase Storage VÀ chứa đường dẫn avatars/
      if (oldUrl.contains('firebasestorage.googleapis.com') &&
          oldUrl.contains('avatars%2F')) {
        try {
          final ref = _storage.refFromURL(oldUrl);
          await ref.delete();
          if (kDebugMode) {
            print('Old avatar deleted successfully: $oldUrl');
          }
        } catch (deleteError) {
          if (deleteError is FirebaseException &&
              deleteError.code == 'object-not-found') {
            if (kDebugMode) {
              print('Old avatar not found, skipping: $oldUrl');
            }
          } else {
            if (kDebugMode) {
              print('Could not delete old avatar: $deleteError');
            }
          }
        }
      } else {
        if (kDebugMode) {
          print('Skipping delete - URL is not a Firebase Storage avatar: $oldUrl');
        }
      }
    } catch (e) {
      // Catch bất kỳ lỗi nào khác (ví dụ: refFromURL thất bại)
      if (kDebugMode) {
        print('Error in deleteOldAvatar (ignored): $e');
      }
    }
  }
}