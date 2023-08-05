import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constants/color_constants.dart';
import '../auth_components/mobile_input.dart';
import '../auth_components/mobile_signup_btn.dart';
import '../auth_components/signup_login_link.dart';
import 'dart:developer' as devtools show log;

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? verificationId;
  bool isSignUp = false;

  @override
  void initState() {
    _countryCodeController.text = "+91";
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.authBackground,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 150),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 32,
                  color: ColorConstants.authText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 50),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(70, 0, 0, 10),
                    child: Text(
                      "Mobile",
                      style: TextStyle(
                        fontSize: 18,
                        color: ColorConstants.authText,
                      ),
                    ),
                  ),
                  buildMobileInput(_countryCodeController, _phoneController),
                ],
              ),
              const SizedBox(height: 20),
              // buildLoginUsingEmail(context), privacy t&C
              const SizedBox(height: 111),
              buildSignUpButton(
                  context, _phoneController, _verifyPhoneNumberForMobile),
              const SizedBox(height: 16),
              buildLogInLink(context),
              const SizedBox(height: 56),
              const Text(
                "Log In or Sign Up",
                style: TextStyle(
                  fontSize: 18,
                  color: ColorConstants.authText,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Image.asset(
                  'assets/google-logo.png',
                  width: 45,
                  height: 45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void loginOrSignup() async {
    String mobile = _phoneController.text.trim();
    // validate the mobile number (Indian format)
    RegExp mobilePattern = RegExp(r'^[789]\d{9}$');

    if (!mobilePattern.hasMatch(mobile)) {
      // If Mobile number is invalid
      devtools.log("Invalid mobile number");
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _verifyPhoneNumberForMobile(mobile);
      } else {
        throw UnimplementedError(
            "Phone number verification is not supported on this platform.");
      }
    } catch (e) {
      devtools.log('$e');
    }
  }

  Future<void> _verifyPhoneNumberForMobile(String mobile) async {
    try {
      verificationCompleted(PhoneAuthCredential credential) {
        devtools.log("Verification completed: $credential");
      }

      verificationFailed(FirebaseAuthException exception) {
        devtools.log("Verification failed: ${exception.message}");
      }

      codeSent(String verificationId, int? resendToken) async {
        devtools.log("Code sent: $verificationId");
        this.verificationId = verificationId;
        await _showOtpPage();
      }

      codeAutoRetrievalTimeout(String verificationId) {
        devtools.log("Auto retrieval timeout: $verificationId");
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: mobile,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      devtools.log('$e');
    }
  }

  Future<void> _showOtpPage() async {
    String? otpCode = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('ENTER OTP')),
          content: _buildOtpInput(),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _otpController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 36),
                elevation: 6,
                textStyle: const TextStyle(
                  fontSize: 14,
                  // color: ColorConstants.authText,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(50),
                  ),
                ),
              ),
              child: const Text('VERIFY'),
            ),
          ],
        );
      },
    );

    if (otpCode != null) {
      _loginOrSignup(otpCode, context);
    }
  }

  Widget _buildOtpInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _loginOrSignup(String otpCode, BuildContext context) {
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP"),
          // backgroundColor:ColorConstants.authText,
        ),
      );
      return;
    }

    verifyOtp(verificationId!, otpCode);
  }

  void verifyOtp(String verificationId, String otpCode) async {
    try {
      PhoneAuthCredential creds = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(creds);
      User? user = userCredential.user;
      if (user != null) {
        if (isSignUp) {
          Navigator.pushReplacementNamed(context, '/register/');
        } else {
          Navigator.pushReplacementNamed(context, '/main-page/');
        }
      }
    } on FirebaseAuthException catch (e) {
      devtools.log("Error :$e");
    }
  }
}
