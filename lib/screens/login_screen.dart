import 'package:ednect/screens/forgot_password_screen.dart';
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
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.12),

                  // Reality Public School Logo
                  Container(
                    width: 200,
                    height: 120,
                    child: Image.asset(
                      'assets/reality_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.085),

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
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Username Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      width: double.infinity,
                      child: TextField(
                        controller: usernameController,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'User Name',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54, width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
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

                  SizedBox(height: screenHeight * 0.02),

                  // Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      width: double.infinity,
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54, width: 1),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

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

                  SizedBox(height: screenHeight * 0.02),

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
                          padding: EdgeInsets.only(top: screenHeight * 0.02),
                          child: Text(
                            isStudent ? 'Login as Employee? Click here' : 'Login as Student? Click here',
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

                  SizedBox(height: screenHeight * 0.08),

                  // EDNECT Logo
                  Container(
                    width: 120,
                    height: 80,
                    child: Image.asset(
                      'assets/ednect.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
