import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/water_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/steps_provider.dart';
import 'navigation/bottom_nav.dart'; // Giả sử bạn có file này để quản lý BottomNavigationBar
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/water_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // *** THAY ĐỔI Ở ĐÂY: Bắt đầu tải dữ liệu ngay khi provider được tạo ***
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => StepsProvider()),
      ],
      child: MaterialApp(
        title: 'Health App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const BottomNav(),
          '/steps': (context) => const StepsScreen(),
          '/weight': (context) => const WeightScreen(),
          '/water': (context) => const WaterScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

// Widget này sẽ lắng nghe trạng thái đăng nhập
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Hàm helper để tải tất cả dữ liệu ban đầu một cách an toàn
  Future<void> _loadInitialData(BuildContext context) async {
    // Dữ liệu người dùng đã bắt đầu tải từ trước
    // Giờ chúng ta chỉ cần tải các dữ liệu phụ thuộc
    await Future.wait([
      Provider.of<WaterProvider>(context, listen: false).loadWater(),
      Provider.of<WeightProvider>(context, listen: false).loadWeight(),
      Provider.of<StepsProvider>(context, listen: false).loadSteps(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData) {
          // Người dùng đã đăng nhập -> Dùng FutureBuilder để chờ dữ liệu được load
          return FutureBuilder(
            future: _loadInitialData(context),
            builder: (context, loadSnapshot) {
              if (loadSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              // Nếu load dữ liệu lỗi (có thể hiển thị màn hình lỗi)
              if (loadSnapshot.hasError) {
                return ErrorScreen(error: loadSnapshot.error.toString());
              }
              // Load xong -> Vào trang chính
              return const BottomNav();
            },
          );
        }

        // Người dùng chưa đăng nhập -> Về màn hình Login
        return const LoginScreen();
      },
    );
  }
}

// Các widget tiện ích (có thể đặt trong file riêng)
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Đã có lỗi xảy ra: $error')));
}
