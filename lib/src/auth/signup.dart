// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/auth/relativeschoolinfo.dart';
import 'package:zimax/src/components/inputfield.dart';


class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();

  bool _isLoading = false;

Future<void> _createAccount() async {
  final email = _emailController.text.trim();
  final fullname = _fullnameController.text.trim();
  final password = _passwordController.text.trim();
  final confirmPassword = _confirmpasswordController.text.trim();

  if (email.isEmpty || password.isEmpty || fullname.isEmpty || confirmPassword.isEmpty) {
    _showAlertDialog(
      context,
      title: "Error",
      message: "Please fill all fields",
      onConfirm: () {},
    );
    return;
  }

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email)) {
    _showAlertDialog(
      context,
      title: "Error",
      message: "Please enter a valid email address",
      onConfirm: () {},
    );
    return;
  }

  if (password.length < 8) {
    _showAlertDialog(
      context,
      title: "Error",
      message: "Password must be at least 8 characters long",
      onConfirm: () {},
    );
    return;
  }

  if (password != confirmPassword) {
    _showAlertDialog(
      context,
      title: "Error",
      message: "Passwords do not match",
      onConfirm: () {},
    );
    return;
  }
  setState(() => _isLoading = true);

  try {
    // Proceed to next page or sign up
    Future.delayed(const Duration(milliseconds: 700), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Relativeschoolinfo(
            email: email,
            fullname: fullname,
            password: password,
          ),
        ),
      );
    });
  } catch (e) {
    print(e);
    _showAlertDialog(
      context,
      title: "Error",
      message: "Unexpected error: $e",
      onConfirm: () {},
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  void _showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = "Cancel",
    String confirmText = "Confirm",
    VoidCallback? onConfirm,
  }) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              message,
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: false,
              onPressed: () => Navigator.pop(context),
              child: Text(cancelText),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.arrow_back,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "back",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 18, 18, 18),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 35, 35, 35),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Profile Information',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "To continue, fill in the following field below to create your account",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color.fromARGB(255, 90, 90, 90),
                ),
              ),
              SizedBox(height: 20),
              InputField(obscureText: false, hintText: 'Full Name', controller: _fullnameController,),
              SizedBox(height: 10),
              InputField(obscureText: false, hintText: 'Email address', controller: _emailController,),
              SizedBox(height: 10),
              InputField(obscureText: true, hintText: 'Password', controller: _passwordController),
              SizedBox(height: 10),
              InputField(obscureText: true, hintText: 'Confirm password', controller: _confirmpasswordController,),
              SizedBox(height: 25),
              GestureDetector(
                onTap: _isLoading ? null : _createAccount,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? const Color.fromARGB(255, 34, 34, 34)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              size: 30,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
