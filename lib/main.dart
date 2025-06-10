// ignore_for_file: prefer_const_constructors
import 'package:emergency_alert_app/screens/auth_screen.dart';
import 'package:emergency_alert_app/screens/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'Emergency Alert App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: currentUser == null
          ? AuthScreen()
          : HomePage(user: currentUser), // ✅ pass user here
    );
  }
}
