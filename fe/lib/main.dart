import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/item_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
      ],
      child: MaterialApp(
        title: '카탈로깅',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // 스플래시 화면 표시 후 초기화
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 스플래시 화면을 최소 2초간 표시
    await Future.delayed(const Duration(seconds: 2));

    // 앱 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();

      // ItemProvider와 CatalogProvider 연동 설정
      final catalogProvider = context.read<CatalogProvider>();
      final itemProvider = context.read<ItemProvider>();

      itemProvider.setOnItemChangedCallback(catalogProvider.onItemChanged);
    });
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 스플래시 화면 표시
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 초기화 중
        if (authProvider.isLoading && !authProvider.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('앱을 초기화하는 중...'),
                ],
              ),
            ),
          );
        }

        // 로그인 상태에 따라 화면 분기
        return authProvider.isLoggedIn
            ? const MainNavigationScreen()
            : const LoginScreen();
      },
    );
  }
}
