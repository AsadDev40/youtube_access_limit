// ignore_for_file: use_build_context_synchronously

import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/pages/home/child/child_home_page.dart';
import 'package:kidsafe_youtube/pages/home/home_page.dart';
import 'package:kidsafe_youtube/pages/starter_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> getHomePage(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final bool? isParent = prefs.getBool('parent');
  final bool? isChild = prefs.getBool('child');
  final String? parentEmail = prefs.getString('parentEmail');
  final String? childName = prefs.getString('childName');
  final String? securityCode = prefs.getString('Securitycode');

  if (isParent == true) {
    return const HomePage();
  } else if (isChild == true) {
    if (parentEmail != null && childName != null && securityCode != null) {
      await Provider.of<ChildProvider>(context, listen: false).getLoggedInChild(
        parentEmail: parentEmail,
        childName: childName,
        securityCode: securityCode,
      );
      return const ChildHomePage();
    } else {
      return const StarterPage();
    }
  } else {
    return const StarterPage();
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: getHomePage(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading home page'));
        } else if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const StarterPage();
        }
      },
    );
  }
}
