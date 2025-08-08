import 'package:ednect/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reality Public School',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8ac63e)),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Start with splash screen
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}
