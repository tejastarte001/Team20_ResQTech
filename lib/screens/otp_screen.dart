import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_alert_app/screens/home_page.dart';
import 'package:emergency_alert_app/screens/profileSetup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;

  OTPScreen({required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;

  Future<void> _verifyOTP() async {
    final String otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a 6-digit OTP')));
      return;
    }

    setState(() => _verifying = true);

    try {
      // 1. Get credentials and sign in
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      // User? user = userCredential.user;

User? user = userCredential.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print('Firestore data: ${doc.data()}');
      }

      print(user);

      if (user == null) throw Exception("User is null after OTP sign-in");

      final String uid = user.uid;
      final String? phone = user.phoneNumber;

      print('🔐 Firebase UID: $uid');
      print('📱 Phone Number: $phone');

      // 2. Get user document from Firestore
      // ✅ Correct approach: fetch where uid field matches
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        print('📄 Fetched user document: $data');

        if (data['name'] != null &&
            data['email'] != null &&
            data['gender'] != null &&
            data['number'] != null) {
          print('✅ Complete profile found. Going to HomePage.');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomePage( user: user,)),
            (route) => false,
          );
          return;
        }
      }

      // 3. If not found or incomplete → Profile Setup
      print('🆕 Incomplete or missing profile. Go to Profile Setup.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupPage(isGoogleSignIn: false),
        ),
        (route) => false,
      );

      
    } catch (e) {
      print('❌ OTP verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
        backgroundColor: Color.fromRGBO(42, 135, 135, 0.494),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to your phone',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            TextField(
              controller: _otpController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                hintStyle: TextStyle(letterSpacing: 12, fontSize: 24),
              ),
              style: TextStyle(
                letterSpacing: 12,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verifyOTP,
                child: _verifying
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Verify'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
