import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/auth/signup.dart';
import 'package:zimax/src/components/imaget.dart';
import 'package:zimax/src/components/inputfield.dart';
import 'package:zimax/src/components/navbar.dart';
import 'package:zimax/src/models/userprofile.dart';
import 'package:zimax/src/services/authservice.dart';
import 'package:zimax/src/services/riverpod.dart';
import 'package:zimax/src/services/supabase.dart';

class Signin extends ConsumerStatefulWidget {
  const Signin({super.key});

  @override
  ConsumerState<Signin> createState() => _SigninState();
}

class _SigninState extends ConsumerState<Signin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;
  final profileService = UserProfileService();

void login() async {
  setState(() => _isLoading = true);

  try {
    final response = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final user = response.user;
    if (user == null) {
      return _showError("Invalid email or password.");
    }

    // Fetch user profile
    final profileResponse = await supabase
        .from('user_profile')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileResponse == null) {
      return _showError("We couldn't load your profile. Please try again.");
    }

    final profile = Userprofile.fromJson(profileResponse);
    (ref.read(userProfileProvider.notifier) as dynamic).state = profile;
    // ref.invalidate(userProfileProvider);


    // Success popup
    _showAlertDialog(
      title: "Welcome back",
      message: "You're now signed in.",
      confirmText: "Continue",
      onConfirm: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavBar()),
        );
      },
    );

  } on AuthApiException catch (e) {
    // Supabase Auth-specific errors
    if (e.message.contains("Invalid login credentials")) {
      _showError("Incorrect email or password.");
    } else if (e.message.contains("Email not confirmed")) {
      _showError("Please verify your email before signing in.");
    } else {
      _showError("Unable to sign in. Please try again.");
    }

  } on PostgrestException {
    // Database-related errors
    _showError("A server error occurred. Please try again shortly.");

  } on SocketException {
    // No internet
    _showError("No internet connection. Check your network and try again.");

  } catch (e) {
    // Fallback error
    _showError("Something went wrong. Please try again.");
  } finally {
    setState(() => _isLoading = false);
  }
}

void _showError(String message) {
  _showAlertDialog(
    title: "Oops!",
    message: message,
    confirmText: "OK",
  );
}

void _showAlertDialog({
  required String title,
  required String message,
  String confirmText = "OK",
  VoidCallback? onConfirm,
}) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
        actions: [
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageDisplay(),
              const SizedBox(height: 50),

              Text(
                'Welcome',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Text(
                  "Sign in to your account to continue",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              InputField(hintText: 'Email', controller: _emailController, obscureText: false,),
              const SizedBox(height: 10),
              InputField(obscureText: true, hintText: 'Password', controller: _passwordController),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _isLoading ? null : login,
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
                            'Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: GoogleFonts.poppins(fontSize: 12)),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Signup()),
                    ),
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
