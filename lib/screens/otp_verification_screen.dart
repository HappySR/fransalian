import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String username;
  final String mobileNumber;
  final String userId;
  final bool isStudent;
  final String otpHash;

  const OTPVerificationScreen({
    Key? key,
    required this.username,
    required this.mobileNumber,
    required this.userId,
    required this.isStudent,
    required this.otpHash,
  }) : super(key: key);

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendTimer = 30;
  Timer? _timer;
  bool _canResend = false;
  String? _currentOtpHash;

  String get maskedMobile {
    // Handle multiple mobile numbers (comma separated)
    List<String> numbers = widget.mobileNumber.split(',');
    List<String> maskedNumbers = numbers.map((number) {
      String trimmedNumber = number.trim();
      if (trimmedNumber.length >= 4) {
        return trimmedNumber.replaceRange(
          2,
          trimmedNumber.length - 2,
          '*' * (trimmedNumber.length - 4),
        );
      }
      return trimmedNumber;
    }).toList();

    return maskedNumbers.join(', ');
  }

  @override
  void initState() {
    super.initState();
    _currentOtpHash = widget.otpHash;
    _initializeControllers();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (int i = 0; i < 6; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  String get _currentCode {
    return _controllers.map((controller) => controller.text).join();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _verifyOTP() async {
    String code = _currentCode;

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit OTP';
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
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      bool isValid = _validateOTPHash(code);

      if (isValid) {
        setState(() {
          _successMessage = 'OTP verified successfully!';
          _isLoading = false;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(
                  username: widget.username,
                  mobileNumber: widget.mobileNumber,
                  userId: widget.userId,
                  isStudent: widget.isStudent,
                ),
              ),
            );
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP. Please try again.';
          _isLoading = false;
        });
        _clearOTP();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
        _clearOTP();
      }
    }
  }

  bool _validateOTPHash(String enteredOTP) {
    if (enteredOTP.length != 6 || !RegExp(r'^\d{6}$').hasMatch(enteredOTP)) {
      return false;
    }

    // Generate SHA256 hash of entered OTP
    var bytes = utf8.encode(enteredOTP);
    var digest = sha256.convert(bytes);
    String enteredOTPHash = digest.toString();

    // Compare with the current hash
    return enteredOTPHash == _currentOtpHash;
  }

  void _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    _clearOTP();

    try {
      // Call the API to resend OTP
      Map<String, dynamic>? otpResult = await ApiService.generateOTP(
          widget.username,
          widget.mobileNumber,
          widget.isStudent
      );

      if (mounted) {
        if (otpResult != null && otpResult['responseString'] != null) {

          _currentOtpHash = otpResult['responseString'];

          setState(() {
            _isLoading = false;
            _successMessage = 'OTP resent successfully!';
          });
          _startResendTimer();

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _successMessage = null;
              });
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to resend OTP. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please check your connection and try again.';
        });
      }
    }
  }

  void _clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (_currentCode.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _verifyOTP();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1b375c),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
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
                        'Verify OTP',
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
                        'Enter the 6-digit code sent to $maskedMobile',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    // User Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.isStudent ? 'Student' : 'Employee'}: ${widget.username}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    // OTP Input Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 45,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _focusNodes[index].hasFocus
                                    ? const Color(0xFFA41034)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onChanged(value, index),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Resend OTP
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Didn\'t receive OTP? ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _canResend ? _resendOTP : null,
                            child: Text(
                              _canResend
                                  ? 'Resend'
                                  : 'Resend in ${_resendTimer}s',
                              style: TextStyle(
                                color: _canResend
                                    ? const Color(0xFFA41034)
                                    : Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                                  : Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage ?? _successMessage ?? '',
                            style: TextStyle(
                              color: _errorMessage != null
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.04),
                    // Back and Verify Buttons
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
                                color: const Color(0xFFA41034),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyOTP,
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
                                  'VERIFY',
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
                  ],
                ),
              ),
            ),
            // EDNECT Logo
            Container(
              width: 120,
              height: 80,
              child: Image.asset('assets/vasp.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
