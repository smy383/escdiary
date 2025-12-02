import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:upgrader/upgrader.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'providers/record_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko');

  // 앱 시작 이벤트 로깅
  AnalyticsService().logAppOpen();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '방탈출 다이어리',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: UpgradeAlert(
              upgrader: Upgrader(
                languageCode: 'ko',
                durationUntilAlertAgain: const Duration(days: 1),
              ),
              child: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
