import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'data/services/billing_service.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase Core with static configs
  await Firebase.initializeApp(options: AppConstants.firebaseOptions);
  
  // Set Cloud Functions region
  FirebaseFunctions.instanceFor(region: 'europe-west1');

  // Initialize background and push notifications service
  await NotificationService.instance.initialize();

  // Initialize Billing and subscription APIs
  await BillingService.instance.initialize();

  runApp(
    const ProviderScope(
      child: YiyosaGelApp(),
    ),
  );
}

class YiyosaGelApp extends ConsumerWidget {
  const YiyosaGelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YiyosaGel',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const RootShell(),
    );
  }
}
