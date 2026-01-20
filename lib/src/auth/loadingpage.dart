import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zimax/src/components/navbar.dart';
import 'package:zimax/src/services/welcomenotify.dart';

class Loadingpage extends StatefulWidget {
  const Loadingpage({super.key});

  @override
  State<Loadingpage> createState() => _LoadingpageState();
}

class _LoadingpageState extends State<Loadingpage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeScale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    // Welcome notification (after UI loads)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.showWelcomeNotification();
    });

    // Navigate after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavBar()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            ///  Animated Logo + Title
            ScaleTransition(
              scale: _fadeScale,
              child: FadeTransition(
                opacity: _fadeScale,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logodark.png',
                      width: 170,
                      height: 170,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Zimax",
                      style: GoogleFonts.poppins(
                        fontSize: 29,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Bottom animation
            SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  LoadingAnimationWidget.stretchedDots(
                    color: Colors.black,
                    size: 45,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Getting ready",
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
