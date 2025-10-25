import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io; // Use prefix 'io'
import 'dart:typed_data';

import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  XFile? _pickedFile;
  Uint8List? _webImage;

  bool _isLoadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb && source == ImageSource.camera) {
      _showErrorSnackBar('Camera không khả dụng trên trình duyệt web.');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        if (kIsWeb) {
          _webImage = await image.readAsBytes();
        }
        // Thêm kiểm tra mounted trước khi gọi setState
        if (!mounted) return;
        setState(() {
          _pickedFile = image;
        });
        _showImagePreviewDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  void _showAvatarPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ảnh đại diện'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue.shade600),
                title: const Text('Chụp ảnh từ camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: Icon(Icons.image, color: Colors.blue.shade600),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreviewDialog() {
    if (_pickedFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận ảnh'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.memory(_webImage!)
              : Image.file(io.File(_pickedFile!.path)), // Use io.File
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Thêm kiểm tra mounted trước khi gọi setState
              if (!mounted) return;
              setState(() {
                _pickedFile = null;
                _webImage = null;
              });
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadAvatarToFirebase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Lưu ảnh'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAvatarToFirebase() async {
    if (_pickedFile == null || _isLoadingImage) return;

    // Thêm kiểm tra mounted trước khi gọi setState
    if (!mounted) return;
    setState(() {
      _isLoadingImage = true;
    });

    try {
      // Use context.read safely here as it's before await
      final userProvider = context.read<UserProvider>();
      final String fileName = _pickedFile!.name;

      if (kIsWeb) {
        final Uint8List imageBytes = await _pickedFile!.readAsBytes();
        await userProvider.uploadAvatarWeb(imageBytes, fileName);
      } else {
        await userProvider.uploadAvatar(
            io.File(_pickedFile!.path), fileName); // Use io.File
      }

      // *** ADD MOUNTED CHECK HERE ***
      if (!mounted) return;
      setState(() {
        _pickedFile = null;
        _webImage = null;
      });

      _showSuccessSnackBar('Cập nhật ảnh đại diện thành công!');
    } catch (e) {
      // *** ADD MOUNTED CHECK HERE ***
      if (!mounted) return;
      _showErrorSnackBar('Lỗi khi tải lên ảnh: $e');
    } finally {
      // *** ADD MOUNTED CHECK HERE ***
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    // Check mounted at the beginning of the function
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    // Check mounted at the beginning of the function
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAnimatedInfoCard(
      String title, String value, IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: Colors.blue.shade600, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: foregroundColor),
      label: Text(label,
          style:
              TextStyle(color: foregroundColor, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: backgroundColor.withOpacity(0.4),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final nameController = TextEditingController(text: userProvider.user.name);
    final genderController =
        TextEditingController(text: userProvider.user.gender);
    final ageController = TextEditingController(
      text: userProvider.user.age > 0 ? userProvider.user.age.toString() : '',
    );
    final heightController = TextEditingController(
      text: userProvider.user.height > 0
          ? userProvider.user.height.toString()
          : '',
    );

    showDialog(
      context: context,
      // Store the context from the builder to use after await
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField(
                controller: nameController,
                label: 'Tên',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildEditTextField(
                controller: genderController,
                label: 'Giới tính',
                icon: Icons.wc_outlined,
              ),
              const SizedBox(height: 12),
              _buildEditTextField(
                controller: ageController,
                label: 'Tuổi',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildEditTextField(
                controller: heightController,
                label: 'Chiều cao (cm)',
                icon: Icons.height,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Use dialogContext
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Make onPressed async
              final int age =
                  int.tryParse(ageController.text) ?? userProvider.user.age;
              final double height = double.tryParse(heightController.text) ??
                  userProvider.user.height;

              final newUser = userProvider.user.copyWith(
                name: nameController.text.trim(),
                gender: genderController.text.trim(),
                age: age,
                height: height,
              );

              try {
                // Await the update operation
                await userProvider.updateUser(newUser);

                // *** ADD MOUNTED CHECK (for the main screen state) ***
                if (!mounted) return;

                _showSuccessSnackBar('Cập nhật thông tin thành công!');
                Navigator.pop(
                    dialogContext); // Close dialog using dialogContext
              } catch (error) {
                // *** ADD MOUNTED CHECK (for the main screen state) ***
                if (!mounted) return;
                _showErrorSnackBar('Cập nhật thất bại: $error');
                // Consider not closing the dialog on error, or provide specific feedback
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    ImageProvider? backgroundImage;
    if (_pickedFile != null) {
      if (kIsWeb) {
        if (_webImage != null) {
          backgroundImage = MemoryImage(_webImage!);
        }
      } else {
        backgroundImage = FileImage(io.File(_pickedFile!.path)); // Use io.File
      }
    } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(user.avatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ sơ',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.lightBlue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              print("Cài đặt!");
            },
            tooltip: 'Cài đặt',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Profile Card
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                // ... (Container decoration remains the same)
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar with Edit Button
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: backgroundImage,
                            child: (backgroundImage == null)
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade600,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Edit Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              if (_isLoadingImage) return;
                              if (_pickedFile != null) {
                                _showImagePreviewDialog();
                              } else {
                                _showAvatarPickerDialog();
                              }
                            },
                            child: Container(
                              // ... (Edit button decoration remains the same)
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: _isLoadingImage
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.blue.shade600,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _pickedFile != null
                                          ? Icons.check
                                          : Icons.camera_alt,
                                      color: Colors.blue.shade600,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Info Cards
          _buildAnimatedInfoCard(
            'Giới tính',
            user.gender.isNotEmpty ? user.gender : 'Chưa cập nhật',
            Icons.person_outline,
            0,
          ),
          _buildAnimatedInfoCard(
            'Tuổi',
            user.age > 0 ? '${user.age} tuổi' : 'Chưa cập nhật',
            Icons.cake_outlined,
            1,
          ),
          _buildAnimatedInfoCard(
            'Chiều cao',
            user.height > 0 ? '${user.height} cm' : 'Chưa cập nhật',
            Icons.height,
            2,
          ),
          const SizedBox(height: 30),

          // Action Buttons
          _buildActionButton(
            onPressed: () => _showEditDialog(context),
            label: 'Sửa thông tin',
            icon: Icons.edit_outlined,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            onPressed: () async {
              // Store context before showing dialog
              final BuildContext currentContext = context;
              final confirm = await showDialog<bool>(
                context: currentContext, // Use stored context
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              // *** ADD MOUNTED CHECK HERE ***
              if (!mounted) return;

              if (confirm == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Ideally, navigate to login screen after logout
                  // Consider using Navigator.of(currentContext)... if needed
                } catch (e) {
                  // Use _showErrorSnackBar which already checks mounted
                  _showErrorSnackBar('Đăng xuất thất bại: $e');
                }
              }
            },
            label: 'Đăng xuất',
            icon: Icons.logout_outlined,
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red,
          ),
          const SizedBox(height: 80), // Add space at the bottom
        ],
      ),
    );
  }
}
