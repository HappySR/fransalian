import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendTimer = 30;
  Timer? _timer;
  bool _canResend = false;

  String get maskedMobile {
    if (widget.mobileNumber.length >= 4) {
      return widget.mobileNumber.replaceRange(
        2,
        widget.mobileNumber.length - 2,
        '*' * (widget.mobileNumber.length - 4),
      );
    }
    return widget.mobileNumber;
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _listenToSMS();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _listenToSMS() {
    // This would typically use a plugin like sms_autofill
    // For now, we'll just show a placeholder
    // You can integrate sms_autofill plugin for automatic SMS detection
  }

  String _getEnteredOTP() {
    return otpControllers.map((controller) => controller.text).join();
  }

  void _onOTPDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (index == 5 && value.isNotEmpty) {
      String enteredOTP = _getEnteredOTP();
      if (enteredOTP.length == 6) {
        _verifyOTP();
      }
    }
  }

  void _verifyOTP() {
    String enteredOTP = _getEnteredOTP();

    if (enteredOTP.length != 6) {
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

    // For demonstration, we'll use a simple hash comparison
    // In a real app, you'd send the OTP back to server for verification
    Future.delayed(const Duration(seconds: 2), () {
      // Simple verification - in real implementation, send to server
      bool isValid = _validateOTPHash(enteredOTP);

      if (isValid) {
        setState(() {
          _successMessage = 'OTP verified successfully!';
          _isLoading = false;
        });

        // Navigate to reset password screen after 1 second
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

        // Clear OTP fields
        for (var controller in otpControllers) {
          controller.clear();
        }
        otpFocusNodes[0].requestFocus();
      }
    });
  }

  bool _validateOTPHash(String enteredOTP) {
    // This is a simplified validation
    // In a real app, you'd send the OTP to server for verification
    // For now, we'll accept any 6-digit OTP as valid
    return enteredOTP.length == 6 && RegExp(r'^\d{6}$').hasMatch(enteredOTP);
  }

  void _resendOTP() {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Clear current OTP
    for (var controller in otpControllers) {
      controller.clear();
    }

    // Simulate API call to resend OTP
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _successMessage = 'OTP resent successfully!';
      });
      _startResendTimer();

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _successMessage = null;
        });
      });
    });
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
                    // Reality Public School Logo
                    Container(
                      width: 180,
                      height: 100,
                      child: Image.asset(
                        'assets/reality_logo.png',
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
                    // OTP Input Fields
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
                                color: otpFocusNodes[index].hasFocus
                                    ? const Color(0xFF8ac63e)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: otpFocusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onOTPDigitChanged(index, value),
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
                                    ? const Color(0xFF8ac63e)
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
                                color: const Color(0xFF8ac63e),
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
            // EDNECT Logo at the very bottom with no margin/padding
            Container(
              width: 120,
              height: 80,
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              child: Image.asset('assets/ednect.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
