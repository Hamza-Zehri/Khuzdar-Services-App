import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/firestore_service.dart';
import 'core/services/messaging_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp();

    // Enable Firestore offline persistence (disk cache for speed)
    FirestoreService.initializeSettings();

    // FCM initialization
    final messaging = MessagingService();
    await messaging.initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
    // We continue so the app can at least show the UI/Login screen
  }

  final languageProvider = LanguageProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthAppProvider(languageProvider: languageProvider)),
        ChangeNotifierProvider(create: (_) => ChatAppProvider()),
        ChangeNotifierProvider(create: (_) => NotificationAppProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: const KhuzdarMarketplaceApp(),
    ),
  );
}
