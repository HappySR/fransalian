import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController usernameController = TextEditingController();
  bool isStudent = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleForgotPassword() async {
    if (usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your username';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      Map<String, dynamic>? result;
      String username = usernameController.text.trim();

      if (isStudent) {
        result = await ApiService.getStudentRegisteredMobile(username);
      } else {
        result = await ApiService.getEmployeeRegisteredMobile(username);
      }

      if (result != null) {
        // Check if the API returned success and mobile number
        if (result['statusCode'] == 'Success' || result['responseValue'] == 1) {
          String? mobileNumber = result['mobile'] ?? result['mobileNo'] ?? result['mobile_no'];
          String? userId = result['sid'] ?? result['empid'] ?? result['id'];

          if (mobileNumber != null && userId != null) {
            // Generate OTP
            Map<String, dynamic>? otpResult = await ApiService.generateOTP(username, mobileNumber, isStudent);

            if (otpResult != null && otpResult['responseString'] != null) {
              // Navigate to OTP verification screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPVerificationScreen(
                    username: username,
                    mobileNumber: mobileNumber,
                    userId: userId,
                    isStudent: isStudent,
                    otpHash: otpResult['responseString'],
                  ),
                ),
              );
            } else {
              setState(() {
                _errorMessage = 'Failed to send OTP. Please try again.';
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Mobile number not found for this username';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Username not found. Please check and try again.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch user details. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please check your connection and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1b375c),
      body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.035),

              Container(
                width: 180,
                height: 100,
                child: Image.asset(
                  'assets/fransalian_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: screenHeight * 0.045),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Enter your username to reset password',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Student/Employee Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isStudent = true;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isStudent ? const Color(0xFF8ac63e) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                'STUDENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isStudent = false;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: !isStudent ? const Color(0xFF8ac63e) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                'EMPLOYEE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // User Name Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.014),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: usernameController,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your username',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Error/Success Message
              if (_errorMessage != null || _successMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _errorMessage != null
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _errorMessage != null
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3)
                      ),
                    ),
                    child: Text(
                      _errorMessage ?? _successMessage ?? '',
                      style: TextStyle(
                        color: _errorMessage != null ? Colors.red : Colors.green,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              SizedBox(height: screenHeight * 0.04),

              // Back and Continue Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'BACK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8ac63e),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                            'CONTINUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Spacer(),

              // EDNECT Logo
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
    );
  }
}
