// lib/providers/user_provider.dart
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  // ... (UserModel _user, getters, Firestore/Storage/Auth instances) ...
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

  // ... (loadUser and updateUser methods remain the same) ...
  Future<void> loadUser() async {
    // ... (implementation from previous step)
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists && doc.data() != null) {
          _user = UserModel.fromJson(doc.data()!);

          // FIX: Kiểm tra xem avatarUrl có phải là URL hợp lệ (bắt đầu bằng http) hay không
          if (_user.avatarUrl != null &&
              _user.avatarUrl!.isNotEmpty &&
              !_user.avatarUrl!.startsWith('http')) {
            if (kDebugMode) {
              print(
                  'Invalid or non-Firebase Storage URL detected, clearing: ${_user.avatarUrl}');
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
            avatarUrl: currentUser.photoURL, // Giữ ảnh gốc từ provider
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

  // Cập nhật thông tin người dùng (cho các trường như tên, tuổi, chiều cao)
  Future<void> updateUser(UserModel newUser) async {
    // ... (implementation from previous step)
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

  // Internal upload function - always takes bytes
  Future<String> _internalUploadAvatar(
      Uint8List imageBytes, String originalFileName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final oldAvatarUrl = _user.avatarUrl; // Store old URL

    final fileExtension = p.extension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'avatars/${currentUser.uid}_$timestamp$fileExtension';
    final ref = _storage.ref().child(fileName);

    if (kDebugMode) {
      print('Uploading to: $fileName'); // You are seeing this log
    }

    final metadata = SettableMetadata(
      contentType: 'image/${fileExtension.substring(1)}',
    );

    UploadTask uploadTask = ref.putData(imageBytes, metadata);

    // *** ADDED: Listen to task events for detailed logging ***
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (kDebugMode) {
        print(
            'Upload Task State: ${snapshot.state} (${snapshot.bytesTransferred}/${snapshot.totalBytes})');
      }
    }, onError: (Object error) {
      // This will catch errors specifically during the upload process
      if (kDebugMode) {
        print('!!! Upload Task Error: $error');
      }
      // Consider propagating this error or handling it appropriately
    });

    try {
      if (kDebugMode) {
        print('Awaiting upload completion...');
      }
      // Await completion of the upload task
      final TaskSnapshot snapshot =
          await uploadTask; // Wait for upload to finish

      if (kDebugMode) {
        print('Upload complete. State: ${snapshot.state}');
      }

      if (snapshot.state == TaskState.success) {
        if (kDebugMode) {
          print('Getting download URL...');
        }
        final downloadUrl = await snapshot.ref.getDownloadURL();
        if (kDebugMode) {
          print('Download URL obtained: $downloadUrl');
          print('Updating Firestore...');
        }

        await updateUserAvatar(
            downloadUrl); // Update Firestore and notify listeners

        if (kDebugMode) {
          print('Firestore update successful.');
        }

        // Delete old avatar *after* successful update
        if (oldAvatarUrl != null &&
            oldAvatarUrl.isNotEmpty &&
            oldAvatarUrl.contains('firebasestorage.googleapis.com')) {
          if (kDebugMode) {
            print('Attempting to delete old avatar: $oldAvatarUrl');
          }
          // Run deletion in background, don't await, catch errors
          deleteOldAvatar(oldAvatarUrl).catchError((e) {
            if (kDebugMode) {
              print('Error deleting old avatar (non-critical): $e');
            }
          });
        }
        return downloadUrl; // Return the new URL on success
      } else {
        // Handle cases where the upload finished but wasn't successful (paused, canceled)
        throw FirebaseException(
          plugin: 'UserProvider',
          code: 'upload-failed',
          message: 'Upload task finished with state: ${snapshot.state}',
        );
      }
    } catch (e) {
      // Catch errors from await uploadTask, getDownloadURL, updateUserAvatar
      if (kDebugMode) {
        print('!!! Error during upload/update process: $e');
      }
      // Check for specific Firebase exceptions like permission errors
      if (e is FirebaseException) {
        print('Firebase Error Code: ${e.code}');
        print('Firebase Error Message: ${e.message}');
      }
      rethrow; // Rethrow to be caught by UI layer
    }
  }

  // Public function for Mobile
  Future<String> uploadAvatar(io.File imageFile, String fileName) async {
    Uint8List imageBytes = await imageFile.readAsBytes();
    return _internalUploadAvatar(imageBytes, fileName);
  }

  // Public function for Web
  Future<String> uploadAvatarWeb(Uint8List imageBytes, String fileName) async {
    return _internalUploadAvatar(imageBytes, fileName);
  }

  // Update user avatar URL in Firestore
  Future<void> updateUserAvatar(String avatarUrl) async {
    // ... (implementation remains the same)
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
      notifyListeners(); // This should trigger UI update
    } catch (e) {
      if (kDebugMode) {
        print('!!! Error updating Firestore avatar URL: $e');
        if (e is FirebaseException) {
          print('Firestore Error Code: ${e.code}');
          print('Firestore Error Message: ${e.message}');
        }
      }
      rethrow;
    }
  }

  // Delete old avatar from Storage
  Future<void> deleteOldAvatar(String oldUrl) async {
    // ... (implementation remains the same)
    if (oldUrl.contains('firebasestorage.googleapis.com')) {
      try {
        final ref = _storage.refFromURL(oldUrl);
        await ref.delete();
        if (kDebugMode) {
          print('Old avatar deleted successfully: $oldUrl');
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          if (kDebugMode) {
            print('Old avatar not found, skipping delete: $oldUrl');
          }
        } else {
          if (kDebugMode) {
            print('Could not delete old avatar: $e');
          }
        }
      }
    } else {
      if (kDebugMode) {
        print('Skipping delete - URL is not a Firebase Storage URL: $oldUrl');
      }
    }
  }
}
