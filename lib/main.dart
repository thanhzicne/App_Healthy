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
import 'firebase_options.dart'; // Đảm bảo tạo file này từ Firebase

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black87),
          ),
          useMaterial3: true,
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              Provider.of<UserProvider>(context, listen: false).loadUser();
              Provider.of<WaterProvider>(context, listen: false).loadWater();
              Provider.of<WeightProvider>(context, listen: false).loadWeight();
              Provider.of<StepsProvider>(context, listen: false).loadSteps();
              return const BottomNav();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
