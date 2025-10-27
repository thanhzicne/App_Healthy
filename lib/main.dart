import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/water_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/steps_provider.dart';
import 'navigation/bottom_nav.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/water_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Xử lý lỗi nếu Firebase không khởi tạo được
    print('Lỗi khởi tạo Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _loadInitialData(BuildContext context) async {
    await Future.wait([
      Provider.of<WaterProvider>(context, listen: false).loadWater(),
      Provider.of<WeightProvider>(context, listen: false).loadWeight(),
      Provider.of<StepsProvider>(context, listen: false).loadData(), // Bỏ comment để tải dữ liệu
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
          // Người dùng đã đăng nhập, chờ dữ liệu ban đầu được tải
          return FutureBuilder(
            future: _loadInitialData(context),
            builder: (context, loadSnapshot) {
              if (loadSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              if (loadSnapshot.hasError) {
                return ErrorScreen(error: loadSnapshot.error.toString());
              }
              // Dữ liệu đã tải xong, chuyển sang trang chính
              return const BottomNav();
            },
          );
        }

        // Người dùng chưa đăng nhập, hiển thị màn hình login
        return const LoginScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              'Đã có lỗi xảy ra: $error',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Có thể thêm logic retry hoặc quay lại
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}