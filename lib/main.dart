import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'styles/theme.dart';
import 'models/discount_provider.dart';
import 'services/auth_service.dart';
import 'components/animated_loading.dart';
import 'utils/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'services/contentful_service.dart';
import 'providers/category_provider.dart';
import 'providers/stores_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.dotenv.load(fileName: ".env");
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase, the app can still show UI
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => StoresProvider()),
      ],
      child: MaterialApp(
        title: 'Discount Hub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of<AuthService>(context).authStateChanges,
      builder: (context, snapshot) {
        // If Firebase or auth service throws an error, still show the login screen
        if (snapshot.hasError) {
          print('Auth stream error: ${snapshot.error}');
          return const LoginScreen();
        }
        
        // Show loading animation while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentTeal,
                          AppColors.accentMagenta,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      size: 64,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Loading animation
                  const AnimatedLoading(
                    animationType: 'loading',
                    size: 60,
                    color: AppColors.accentTeal,
                    message: 'Loading Discount Hub...',
                  ),
                ],
              ),
            ),
          );
        }
        
        // Check if user is signed in
        if (snapshot.hasData) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// Custom theme settings for the app
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.backgroundColor,
      cardColor: AppColors.cardColor,
      primaryColor: AppColors.primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.surfaceColor,
        error: AppColors.errorColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Poppins',
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
} 