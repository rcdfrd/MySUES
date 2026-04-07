import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/services/notification_service.dart';
import 'package:mysues/services/app_update_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mysues/services/widget_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_entry_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await WidgetService.updateWidget();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    "widgetUpdateTask",
    "updateWidget",
    frequency: const Duration(minutes: 15),
  );
  
  // Also update widget on app launch
  WidgetService.updateWidget();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadSettings();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());

  // Reschedule notifications after app is running to avoid blocking startup
  notificationService.rescheduleAll().catchError((e) {
    debugPrint('Failed to reschedule notifications: $e');
  });
  final appUpdateService = AppUpdateService.instance;
  if (appUpdateService.supportsUpdateCheck) {
    appUpdateService.syncOnAppStart().catchError((e) {
      debugPrint('Failed to sync app update info: $e');
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          title: '我的课表',
          themeMode: ThemeService().themeMode,
          theme: ThemeData(
            fontFamily: ThemeService().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          darkTheme: ThemeData(
            fontFamily: ThemeService().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          locale: const Locale('zh', 'CN'),
          // 切换到带底部导航的主界面
          home: ThemeService().splashAnimationEnabled
              ? const SplashScreen()
              : const MainEntryScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
