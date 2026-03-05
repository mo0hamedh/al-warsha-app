import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_wrapper.dart';
import 'screens/study_room_screen.dart';
import 'services/notification_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/user_model.dart';
import 'models/habit_model.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // تحميل الخطوط مسبقاً للويب لتحسين الأداء
  if (kIsWeb) {
    await GoogleFonts.pendingFonts([
      GoogleFonts.cairo(),
      GoogleFonts.tajawal(),
    ]);
  }
  
  // تفعيل الـ offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // تهيئة Hive للبيانات المحلية
  await Hive.initFlutter();
  await Hive.openBox('tasks');
  await Hive.openBox('habits');
  await Hive.openBox('settings');

  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, TaskProvider>(
          create: (context) => TaskProvider(context.read<AuthService>()),
          update: (context, auth, previous) => previous ?? TaskProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, PomodoroProvider>(
          create: (context) => PomodoroProvider(context.read<AuthService>()),
          update: (context, auth, previous) => previous ?? PomodoroProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // ── Global Streams Optimization ──
        StreamProvider<UserModel?>(
          create: (context) {
            final auth = context.read<AuthService>();
            if (auth.currentUser == null) return const Stream.empty();
            return DatabaseService().getUserProfile(auth.currentUser!.uid)
                .handleError((error) {
              debugPrint('Error loading user profile: $error');
              return null;
            });
          },
          initialData: null,
          catchError: (context, error) {
            debugPrint('StreamProvider caught error: $error');
            return null;
          },
        ),
        StreamProvider<List<HabitModel>>(
          create: (context) {
            final auth = context.read<AuthService>();
            if (auth.currentUser == null) return const Stream.empty();
            return DatabaseService().getUserHabits(auth.currentUser!.uid)
                .handleError((error) {
              debugPrint('Error loading user habits: $error');
              return <HabitModel>[];
            });
          },
          initialData: const [],
          catchError: (context, error) {
            debugPrint('StreamProvider caught error loading habits: $error');
            return <HabitModel>[];
          },
        ),
      ],
      child: const ElWarshaApp(),
    ),
  );
}

class ElWarshaApp extends StatelessWidget {
  const ElWarshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'الورشة',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        if (settings.name == '/study_room') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => StudyRoomScreen(
              roomCode: args['roomCode'],
              isHost: args['isHost'],
            ),
          );
        }
        return null;
      },
    );
  }
}
