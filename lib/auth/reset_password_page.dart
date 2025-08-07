import 'dart:convert';
import 'package:K_Skill/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isOTPSent = false;
  bool isOTPVerified = false;
  bool isLoading = false;

  final String baseUrl = ApiConfig.baseUrl; // Replace with your API

  Future<void> sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("Please enter your email");
      return;
    }

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/send-otp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _emailController.text.trim()}),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      setState(() => isOTPSent = true);
      _showSnackBar("OTP sent to your email");
    } else {
      _showSnackBar("Failed to send OTP");
    }
  }

  Future<void> verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar("Please enter OTP");
      return;
    }

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/verify-otp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'otp': _otpController.text.trim(),
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      setState(() => isOTPVerified = true);
      _showSnackBar("OTP verified. Enter your new password.");
    } else {
      // Reset flow to email entry
      setState(() {
        isOTPSent = false;
        isOTPVerified = false;
        _otpController.clear(); // Clear OTP field
      });
      _showSnackBar("OTP incorrect, please try again.");
    }
  }

  Future<void> resetPassword() async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar("Please enter a new password");
      return;
    }

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/reset-password"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'newPassword': _passwordController.text.trim(),
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      _showSnackBar("Password updated successfully.");
      Navigator.pop(context);
    } else {
      _showSnackBar("Password update failed");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildEmailInput() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : sendOtp,
          child: Text("Send OTP"),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : verifyOtp,
          child: Text("Verify OTP"),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : resetPassword,
          child: Text("Update Password"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (!isOTPSent) _buildEmailInput(),
            if (isOTPSent && !isOTPVerified) _buildOtpInput(),
            if (isOTPVerified) _buildPasswordInput(),
          ],
        ),
      ),
    );
  }
}
