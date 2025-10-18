import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';
import 'package:kisanbazaar/screens/buyer/buyer_dashboard.dart';
import 'package:kisanbazaar/screens/seller/seller_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigateToScreen(const LoginScreen());
      return;
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (!userDoc.exists) {
      _navigateToScreen(const LoginScreen());
      return;
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String role = userData['role'];

    if (role == 'buyer') {
      _navigateToScreen(const BuyerDashboard());
    } else if (role == 'seller') {
      _navigateToScreen(const SellerDashboard());
    } else {
      _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "KisanBazaar",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
