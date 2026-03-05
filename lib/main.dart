import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/word_of_the_day_page.dart';
import 'services/notification_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Amharic
  await initializeDateFormatting('am', null);

  // Ads only on mobile platforms
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
    await NotificationService().init();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'የቀኑ ቃል',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WordOfTheDayPage(),
    );
  }
}
