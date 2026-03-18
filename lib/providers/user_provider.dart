// lib/providers/user_provider.dart
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  // ... (UserModel _user, getters, Firestore/Storage/Auth instances) ...
  UserModel _user = UserModel(
    name: 'User',
    email: '',
    username: '',
    gender: '',
    age: 0,
    height: 0,
    avatarUrl: null,
  );

  UserModel get user => _user;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Đăng ký người dùng mới với Username
  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // 1. Kiểm tra username đã tồn tại chưa
      final usernameDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameDoc.docs.isNotEmpty) {
        throw Exception('Tên đăng nhập đã tồn tại!');
      }

      // 2. Tạo tài khoản Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 3. Lưu thông tin bổ sung vào Firestore
        _user = UserModel(
          name: name,
          email: email,
          username: username,
          gender: 'Chưa cập nhật',
          age: 0,
          height: 0,
          avatarUrl: null,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(_user.toJson());

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering user: $e');
      }
      rethrow;
    }
  }

  // Đăng nhập bằng Email hoặc Username
  Future<void> loginUser({
    required String identifier, // Có thể là email hoặc username
    required String password,
  }) async {
    try {
      String email = identifier;

      // Nếu identifier không chứa '@', coi đó là username và tìm email tương ứng
      if (!identifier.contains('@')) {
        final userDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier)
            .get();

        if (userDoc.docs.isEmpty) {
          throw Exception('Tên đăng nhập không tồn tại!');
        }
        email = userDoc.docs.first.data()['email'];
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await loadUser();
    } catch (e) {
      if (kDebugMode) {
        print('Error logging in: $e');
      }
      rethrow;
    }
  }

  // Đăng nhập bằng Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Nếu người dùng mới đăng nhập bằng Google lần đầu
          _user = UserModel(
            name: user.displayName ?? 'Người dùng Google',
            email: user.email ?? '',
            username:
                user.email?.split('@')[0] ?? 'user_${user.uid.substring(0, 5)}',
            gender: 'Chưa cập nhật',
            age: 0,
            height: 0,
            avatarUrl: user.photoURL,
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(_user.toJson());
        } else {
          _user = UserModel.fromJson(doc.data()!);
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error Google sign in: $e');
      }
      rethrow;
    }
  }

  // Quên mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting password: $e');
      }
      rethrow;
    }
  }

  // Tải thông tin người dùng từ Firestore
  Future<void> loadUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists && doc.data() != null) {
          _user = UserModel.fromJson(doc.data()!);

          // Kiểm tra xem avatarUrl có phải là URL hợp lệ (bắt đầu bằng http) hay không
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
            name: currentUser.displayName ?? 'Người dùng',
            email: currentUser.email ?? '',
            username: currentUser.email?.split('@')[0] ?? 'user',
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

  // Internal upload function - always takes bytes
  Future<String> _internalUploadAvatar(
    Uint8List imageBytes,
    String originalFileName,
  ) async {
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
    uploadTask.snapshotEvents.listen(
      (TaskSnapshot snapshot) {
        if (kDebugMode) {
          print(
            'Upload Task State: ${snapshot.state} (${snapshot.bytesTransferred}/${snapshot.totalBytes})',
          );
        }
      },
      onError: (Object error) {
        // This will catch errors specifically during the upload process
        if (kDebugMode) {
          print('!!! Upload Task Error: $error');
        }
        // Consider propagating this error or handling it appropriately
      },
    );

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
          downloadUrl,
        ); // Update Firestore and notify listeners

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

  // Cập nhật URL ảnh đại diện trong Firestore
  Future<void> updateUserAvatar(String avatarUrl) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      // Cập nhật lại field 'avatarUrl' trong Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'avatarUrl': avatarUrl,
      });

      // Cập nhật lại state của provider
      _user = _user.copyWith(avatarUrl: avatarUrl);
      notifyListeners();
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

  // Xóa ảnh đại diện cũ khỏi Storage
  Future<void> deleteOldAvatar(String oldUrl) async {
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

  void clearAllData() {
    // Reset _user về trạng thái ban đầu
    _user = UserModel(
      name: 'User',
      email: '',
      username: '',
      gender: '',
      age: 0,
      height: 0,
      avatarUrl: null,
    );

    // Thông báo cho các widget đang lắng nghe về sự thay đổi này
    notifyListeners();
    if (kDebugMode) {
      print('UserProvider state cleared.');
    }
  }
}
