import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String username;
  final String mobileNumber;
  final String userId;
  final bool isStudent;

  const ResetPasswordScreen({
    Key? key,
    required this.username,
    required this.mobileNumber,
    required this.userId,
    required this.isStudent,
  }) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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

  Future<void> _handleResetPassword() async {
    if (newPasswordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in both password fields';
        _successMessage = null;
      });
      return;
    }

    if (newPasswordController.text.length < 5) {
      setState(() {
        _errorMessage = 'Password must be at least 5 characters long';
        _successMessage = null;
      });
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
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
      String newPassword = newPasswordController.text.trim();

      if (widget.isStudent) {
        result = await ApiService.changeStudentPassword(
          widget.username,
          newPassword,
          widget.userId,
        );
      } else {
        result = await ApiService.changeEmployeePassword(
          widget.username,
          newPassword,
          widget.userId,
        );
      }

      if (result != null) {
        if (result['statusCode'] == 'Success' || result['responseValue'] == 1) {
          setState(() {
            _successMessage =
                'Password changed successfully! You can now login with your new password.';
          });

          // Navigate back to login after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        } else {
          setState(() {
            _errorMessage =
                result?['message'] ??
                'Failed to change password. Please try again.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to change password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An error occurred. Please check your connection and try again.';
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
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

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
                  child: Column(
                    children: [
                      Text(
                        '${widget.isStudent ? 'Student' : 'Employee'}: ${widget.username}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mobile: $maskedMobile',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // New Password Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Password',
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
                        controller: newPasswordController,
                        obscureText: _obscureNewPassword,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Confirm Password Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm Password',
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
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
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

              // Back and Reset Buttons
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
                          onPressed: _isLoading
                              ? null
                              : () {
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
                          onPressed: _isLoading ? null : _handleResetPassword,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'RESET PASSWORD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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
                child: Image.asset('assets/vasp.png', fit: BoxFit.contain),
              ),
            ],
          ),
      ),
    );
  }
}
