// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:zimax/src/auth/signin.dart';
import 'package:zimax/src/models/chat_item_hive.dart';
import 'package:zimax/src/services/notificationservice.dart';

/// Background notification handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(' Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Firebase
  await Firebase.initializeApp();

  /// Initialize Supabase (must come before using Supabase.instance anywhere)
  await Supabase.initialize(
    url: 'https://kldaeoljhumowuegwjyq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtsZGFlb2xqaHVtb3d1ZWd3anlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4OTY2MjAsImV4cCI6MjA4MDQ3MjYyMH0.OrqMl6ejtoa8m41Y1MWJm1oAz3S3iKc0UXlW07qyG3A',
  );

  await Hive.initFlutter();
  Hive.registerAdapter(ChatItemHiveAdapter());
  await Hive.openBox('settings');
  await Hive.openBox<ChatItemHive>('chatBox');

  await NotificationService.init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(child: ZimaxApp()),
  );
}

/// ROOT APP
class ZimaxApp extends StatelessWidget {
  const ZimaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      home: const SplashScreen(),
    );
  }
}

/// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Signin()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bgimg1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color.fromARGB(82, 0, 0, 0),
                    Color.fromARGB(240, 0, 0, 0),
                  ],
                  stops: [0.0, 0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/logo.png', width: 170, height: 170),
                  const SizedBox(height: 10),
                  Text(
                    'Zimax',
                    style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Communication and Information dispersal at it's finest",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  LoadingAnimationWidget.threeArchedCircle(
                      color: Colors.white, size: 35),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
