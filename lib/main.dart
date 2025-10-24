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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => StepsProvider()),
      ],
      child: MaterialApp(
        title: 'Health App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black87),
          ),
          useMaterial3: true,
        ),
        // Định nghĩa tất cả named routes
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const BottomNav(),
          '/steps': (context) => const StepsScreen(),
          '/weight': (context) => const WeightScreen(),
          '/water': (context) => const WaterScreen(),
        },
        // Xử lý route không tồn tại
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
        // StreamBuilder để kiểm tra trạng thái đăng nhập
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Đang load
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang tải...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Có lỗi
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Có lỗi xảy ra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Người dùng đã đăng nhập
            if (snapshot.hasData) {
              // Load tất cả provider data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Provider.of<UserProvider>(context, listen: false).loadUser();
                  Provider.of<WaterProvider>(
                    context,
                    listen: false,
                  ).loadWater();
                  Provider.of<WeightProvider>(
                    context,
                    listen: false,
                  ).loadWeight();
                  Provider.of<StepsProvider>(
                    context,
                    listen: false,
                  ).loadSteps();
                }
              });
              return const BottomNav();
            }

            // Người dùng chưa đăng nhập
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
