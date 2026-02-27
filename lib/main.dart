import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
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
    );
  }
}
