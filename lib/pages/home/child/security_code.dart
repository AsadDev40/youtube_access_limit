// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/pages/home/child/child_home_page.dart';
import 'package:kidsafe_youtube/pages/home/child/child_qr_code_scanner.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityCodePage extends HookWidget {
  const SecurityCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final passwordController = useTextEditingController();
    final usernameController = useTextEditingController();
    final userEmailController = useTextEditingController();
    final showPassword = useState(true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152534),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header similar to LoginPage
            Container(
              color: const Color(0xFF152534),
              height: 120,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Security Details',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'For Child Login',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parent Email Field
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        'Parent Email',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: userEmailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter Parent Email',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.left,
                      enableBorder: true,
                    ),
                    const SizedBox(height: 20),
                    // Child Name Field
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        'Child Name',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: usernameController,
                      hintText: 'Enter Child Name',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.left,
                      enableBorder: true,
                    ),
                    const SizedBox(height: 20),
                    // Security Code Field
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        'Security Code',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      isPassword: showPassword.value,
                      controller: passwordController,
                      hintText: 'Enter Security Code',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.left,
                      enableBorder: true,
                      suffixWidget: InkWell(
                        onTap: () {
                          showPassword.value = !showPassword.value;
                        },
                        child: Icon(
                          showPassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Submit Button
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 170,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (usernameController.text.isEmpty) {
                                Utils.showToast('Enter your name');
                              } else if (userEmailController.text.isEmpty) {
                                Utils.showToast('Enter your Email');
                              } else if (passwordController.text.isEmpty) {
                                Utils.showToast('Enter security code');
                              } else {
                                EasyLoading.show();
                                try {
                                  await childProvider.getLoggedInChild(
                                    parentEmail: userEmailController.text,
                                    childName: usernameController.text,
                                    securityCode: passwordController.text,
                                  );

                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('child', true);
                                  await prefs.setBool('showbutton', false);
                                  await prefs.setString(
                                      'parentEmail', userEmailController.text);
                                  await prefs.setString(
                                      'childName', usernameController.text);
                                  await prefs.setString(
                                      'Securitycode', passwordController.text);

                                  Utils.pushAndRemovePrevious(
                                      context, const ChildHomePage());

                                  EasyLoading.dismiss();
                                  userEmailController.clear();
                                  usernameController.clear();
                                  passwordController.clear();
                                } catch (e) {
                                  EasyLoading.dismiss();
                                  Utils.showToast(
                                      ' Please enter valid email, name, and security code.');
                                  debugPrint('Error: $e');
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
                              'Submit',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    // QR Code Button
                    Padding(
                      padding: const EdgeInsets.only(left: 100),
                      child: SizedBox(
                        width: 170,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Utils.navigateTo(context, const QRCodeScanScreen());
                          },
                          child: Center(
                            child: const Text(
                              'Login Using QrCode',
                              style: TextStyle(color: Colors.white),
                            ),
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
}
