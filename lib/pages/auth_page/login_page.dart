// ignore_for_file: avoid_print, unnecessary_null_comparison, use_build_context_synchronously

import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/pages/auth_page/signup_page.dart';
import 'package:kidsafe_youtube/pages/home/home_page.dart';
import 'package:kidsafe_youtube/providers/auth_provider.dart';
import 'package:kidsafe_youtube/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Google Sign In
  GoogleSignIn googleAuth = GoogleSignIn();

  final _formField = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  bool passToggle = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152534),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xFF152534),
              height: 120,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in to your',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Account',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Sign in to your Account',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formField,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        'Email',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: userNameController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Email',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.left,
                      enableBorder: true,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        'Password',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      isPassword: passToggle,
                      controller: passwordController,
                      hintText: '********',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.left,
                      enableBorder: true,
                      suffixWidget: InkWell(
                        onTap: () {
                          setState(() {
                            passToggle = !passToggle;
                          });
                        },
                        child: Icon(
                          passToggle
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          showForgotPasswordDialog(context);
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 170,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (userNameController.text.isEmpty) {
                                Utils.showToast('Enter valid email');
                              } else if (passwordController.text.isEmpty) {
                                Utils.showToast('Enter valid password');
                              } else {
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                EasyLoading.show();

                                try {
                                  final res = await authProvider
                                      .signInWithEmailAndPassword(
                                    userNameController.text,
                                    passwordController.text,
                                  );

                                  EasyLoading.dismiss();

                                  if (res.user != null) {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool('parent', true);
                                    await prefs.setBool('showbutton', true);

                                    userNameController.clear();
                                    passwordController.clear();

                                    Utils.pushAndRemovePrevious(
                                        context, const HomePage());
                                  } else {
                                    Utils.showToast(
                                        'Invalid email or password');
                                  }
                                } catch (e) {
                                  EasyLoading.dismiss();
                                  Utils.showToast('Invalid email and password');
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                        child: Padding(
                      padding:
                          const EdgeInsets.only(left: 15, right: 15, top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 0.7, // Height of the line
                              color: Colors.black54, // Color of the line
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                    10), // Spacing between the lines and text
                            child: Text(
                              'Or login with',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 0.7, // Height of the line
                              color: Colors.black54, // Color of the line
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () async {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            EasyLoading.show();

                            try {
                              final res = await authProvider.signInWithGoogle();
                              if (res != null) {
                                EasyLoading.dismiss();
                                Utils.pushAndRemovePrevious(
                                    context, const HomePage());
                              } else {
                                EasyLoading.dismiss();
                                Utils.showToast('An error occurred');
                              }
                            } catch (e) {
                              EasyLoading.dismiss();
                              Utils.showToast(
                                  'An error occurred. Failed to login');
                            }
                          },
                          child: Container(
                            height: 50,
                            width: 150,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 30,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 90,
                                    child: Image.asset(
                                      'assets/google.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      'Google',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () async {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);

                            EasyLoading.show();

                            try {
                              final res = await authProvider.signInWithApple();

                              if (res != null) {
                                EasyLoading.dismiss();
                                Utils.pushAndRemovePrevious(
                                    context, const HomePage());
                              } else {
                                EasyLoading.dismiss();
                                Utils.showToast('An error occured ');
                              }
                            } catch (e) {
                              EasyLoading.dismiss();
                              Utils.showToast(
                                  'an error occured. failed to login');
                            }
                          },
                          child: Container(
                            height: 50,
                            width: 150,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Padding(
                              padding: EdgeInsets.only(
                                left: 10,
                                right: 0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.apple,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 5, right: 25),
                                    child: Text(
                                      'Apple',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Utils.navigateTo(context, const SignupPage());
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: Colors.lightGreen,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'Email',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.left,
              enableBorder: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text;
              if (email.isEmpty) {
                Utils.showToast('Please enter your email');
              } else {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                authProvider.sendPasswordResetEmail(email);
                Navigator.pop(context);
                Utils.showToast('Password reset email sent');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
