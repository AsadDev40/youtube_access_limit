// ignore_for_file: use_build_context_synchronously

import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/pages/auth_page/login_page.dart';
import 'package:kidsafe_youtube/pages/home/home_page.dart';
import 'package:kidsafe_youtube/pages/home/child/security_code.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarterPage extends StatelessWidget {
  const StarterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              height: 600,
              // width: 400,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 208, 207, 205),
              ),
              child: SizedBox(
                child: RiveAnimation.asset(
                  'assets/social_app (1).riv',
                  fit: BoxFit.fitWidth,

                  animations: const [
                    'assets/social_app (1).riv',
                  ], // Replace with your animation name if needed
                  onInit: (Artboard artboard) {
                    final controller = StateMachineController.fromArtboard(
                        artboard, 'State Machine 1');
                    artboard.addController(controller!);
                    controller.isActive = true;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: SizedBox(
                width: 150,
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(const Color(0xFFC0E863))),
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    bool? isParent = prefs.getBool('parent');
                    await prefs.setBool('showbutton', true);

                    if (isParent == true) {
                      Utils.navigateTo(context, const HomePage());
                    } else {
                      Utils.navigateTo(context, const LoginPage());
                    }
                  },
                  child: const Text(
                    'Parent',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: 150,
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(const Color(0xFFC0E863))),
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    // bool? isChild = prefs.getBool('child');
                    await prefs.setBool('showbutton', false);

                    Utils.navigateTo(context, const SecurityCodePage());
                  },
                  child: const Text(
                    'Child',
                    style: TextStyle(fontSize: 20, color: Colors.black),
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
