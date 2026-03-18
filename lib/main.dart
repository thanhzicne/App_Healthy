import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/water_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/steps_provider.dart';
import 'providers/theme_provider.dart';
import 'navigation/bottom_nav.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/water_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo locale cho intl (BẮT BUỘC)
  await initializeDateFormatting('vi_VN', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => StepsProvider()),
      ],
      child: const _AppLifecycleWrapper(),
    );
  }
}

class _AppLifecycleWrapper extends StatefulWidget {
  const _AppLifecycleWrapper();

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  DateTime _lastNotifUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo notification sớm để kịp show khi app ra nền.
    NotificationService().initialize();

    // Lắng nghe StepsProvider để cập nhật notification khi app đang ở nền (debounce nhẹ).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stepsProvider = context.read<StepsProvider>();
      stepsProvider.addListener(_onStepsChanged);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<StepsProvider>().removeListener(_onStepsChanged);
    super.dispose();
  }

  void _onStepsChanged() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      // Tránh update quá dày
      final now = DateTime.now();
      if (now.difference(_lastNotifUpdate).inMilliseconds < 1500) return;
      _lastNotifUpdate = now;

      final stepsProvider = context.read<StepsProvider>();
      NotificationService().showOrUpdateLiveStepsNotification(
        stepsToday: stepsProvider.steps.steps,
        goal: stepsProvider.steps.goal,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final stepsProvider = context.read<StepsProvider>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      // Khi app ra nền/đóng: show ongoing notification hiển thị bước chân.
      NotificationService().showOrUpdateLiveStepsNotification(
        stepsToday: stepsProvider.steps.steps,
        goal: stepsProvider.steps.goal,
      );
    }

    // Nếu muốn tắt notification khi quay lại app thì mở dòng dưới:
    // if (state == AppLifecycleState.resumed) {
    //   NotificationService().cancelLiveStepsNotification();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Health App',
          debugShowCheckedModeBanner: false,

          // ✅ Thêm localization delegates (BẮT BUỘC cho tiếng Việt)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
          locale: themeProvider.locale,

          theme: themeProvider.currentTheme,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const BottomNav(),
            '/steps': (context) => const StepsScreen(),
            '/weight': (context) => const WeightScreen(),
            '/water': (context) => const WaterScreen(),
          },
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _loadInitialData(BuildContext context) async {
    await Future.wait([
      Provider.of<WaterProvider>(context, listen: false).loadWater(),
      Provider.of<WeightProvider>(context, listen: false).loadWeight(),
      Provider.of<StepsProvider>(context, listen: false).loadData(),
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
          return FutureBuilder(
            future: _loadInitialData(context),
            builder: (context, loadSnapshot) {
              if (loadSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              if (loadSnapshot.hasError) {
                return ErrorScreen(error: loadSnapshot.error.toString());
              }
              return const BottomNav();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
