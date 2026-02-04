import 'package:flutter/material.dart';
import 'package:stock_buddy/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to next screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {

      // Replace with your actual navigation logic
      // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
      //   return LoginScreen();
      // },),(Route<dynamic> route) => false );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      body: Center(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo and App Name
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAppLogo(size: 120),
                const SizedBox(height: 24),
                _buildAppName(fontSize: 42),
                const SizedBox(height: 16),
                _buildAppTagline(fontSize: 18),
                const SizedBox(height: 40),
                _buildLoadingIndicator(),
              ],
            ),
          ),
          // Illustration or additional content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: _buildIllustration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAppLogo(size: 80),
          const SizedBox(height: 24),
          _buildAppName(fontSize: 32),
          const SizedBox(height: 12),
          _buildAppTagline(fontSize: 14),
          const SizedBox(height: 40),
          _buildLoadingIndicator(),
          const Spacer(),
          _buildFooterText(),
        ],
      ),
    );
  }

  Widget _buildAppLogo({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 50,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildAppName({required double fontSize}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Stock ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),
          TextSpan(
            text: 'Buddy',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w300,
              color: Colors.yellow.shade300,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTagline({required double fontSize}) {
    return Text(
      'Smart Inventory Management Solution',
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white.withOpacity(0.8),
        fontWeight: FontWeight.w300,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow.shade300),
                strokeWidth: 3,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.inventory_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            'Manage your inventory\nwith ease and precision',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        '© 2025 Stock Buddy. All rights reserved.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
    );
  }
}