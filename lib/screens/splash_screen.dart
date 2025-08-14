import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'webview_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Get API key (will fetch from API if not stored)
      String? apiKey = await ApiService.getApiKey();
      print('API Key initialized: ${apiKey != null ? 'Success' : 'Failed'}');

      // Wait at least 3 seconds for splash screen
      await Future.delayed(const Duration(seconds: 3));

      // Check if user is already logged in
      if (ApiService.isLoggedIn()) {
        String? loginUrl = ApiService.getLoginUrl();
        if (loginUrl != null && loginUrl.isNotEmpty) {
          // Navigate to WebView with stored URL
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WebViewScreen(url: loginUrl),
            ),
          );
          return;
        }
      }

      // Navigate to login screen if not logged in or no URL stored
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('Error initializing app: $e');
      // Fallback to login screen on error
      await Future.delayed(const Duration(seconds: 3));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 150,
              child: Image.asset(
                'assets/fransalian_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA41034)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA41034),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
