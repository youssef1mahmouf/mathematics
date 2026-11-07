import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'database/database_setup.dart';
import 'screens/dashboard.dart';
import 'database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Installs the platform database factory before the first openDatabase():
  // `sqflite_common_ffi_web` on the browser, no-op on Android/iOS/Windows.
  await initDatabaseFactory();
  await initializeDateFormatting('ar', null);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام حضور الطلاب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        fontFamily: 'Cairo',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      locale: const Locale('ar', 'EG'),
      home: const DashboardScreen(),
    );
  }
}

final AppDatabase appDatabase = AppDatabase();
