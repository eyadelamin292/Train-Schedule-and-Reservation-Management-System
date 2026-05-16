import 'package:flutter/material.dart';
import 'package:swe_project/pages/logIn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knuxdkvempphorusvulg.supabase.co',
    anonKey: 'sb_publishable_GwBOth7ug0paVA-aXZyZbg_TAPnC4uj',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14181B),
        primaryColor: const Color(0xFF10B981),

        // تنسيق الألوان الافتراضي للنصوص في الثيم الداكن
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: logIn(),
    );
  }
}
