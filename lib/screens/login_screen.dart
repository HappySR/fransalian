import 'package:the_reality_public_school/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'webview_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? result;

      if (isStudent) {
        result = await ApiService.studentLogin(
          usernameController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        result = await ApiService.employeeLogin(
          usernameController.text.trim(),
          passwordController.text.trim(),
        );
      }

      if (result != null && result['responseValue'] == 1) {
        String loginUrl = result['responseString'];
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WebViewScreen(url: loginUrl),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please check your connection and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      // This prevents the screen from resizing when keyboard appears
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Fixed background that won't move
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1b375c),
              image: DecorationImage(
                image: AssetImage('assets/login.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Scrollable content overlay
          SafeArea(
            child: Column(
              children: [
                // Reality Public School Logo - Top half (40%)
                SizedBox(
                  height: screenHeight * 0.4,
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 120,
                      child: Image.asset(
                        'assets/fransalian_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Content starting from 60% height - Bottom half
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        // Student/Employee Label
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            width: double.infinity,
                            child: Text(
                              'The Reality Public School ! ${isStudent ? 'STUDENT' : 'EMPLOYEE'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Username Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            width: double.infinity,
                            child: TextField(
                              controller: usernameController,
                              cursorColor: const Color(0xFFff4181),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'User Name',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFff4181), width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            width: double.infinity,
                            child: TextField(
                              controller: passwordController,
                              cursorColor: const Color(0xFFff4181),
                              obscureText: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFff4181), width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Error Message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Forgot Password and Login Button Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8ac63e),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Employee/Student Toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white54, width: 1),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isStudent = !isStudent;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  isStudent
                                      ? 'Login as Employee? Click here'
                                      : 'Login as Student? Click here',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Spacer to push EDNECT logo to bottom
                        const Spacer(),

                        // EDNECT Logo - Positioned at bottom with no margin/padding
                        Container(
                          width: 120,
                          height: 80,
                          child: Image.asset(
                            'assets/vasp.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
