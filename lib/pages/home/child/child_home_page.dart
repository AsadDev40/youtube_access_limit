// ignore_for_file: use_build_context_synchronously

import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/pages/home/child/child_channel_page.dart';
import 'package:kidsafe_youtube/pages/home/child/child_video_page.dart';
import 'package:kidsafe_youtube/pages/main_page.dart';
import 'package:kidsafe_youtube/providers/auth_provider.dart';
import 'package:kidsafe_youtube/theme/colors.dart';
import 'package:kidsafe_youtube/utilities/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  int _selectedIndex = 0;
  bool _isParent = false;

  @override
  void initState() {
    super.initState();
    _loadIsParent();
  }

  Future<void> _loadIsParent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isParent = prefs.getBool('child') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the current theme
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(),
      body: body(),
      bottomNavigationBar: customBottomNavigationBar(theme, isDarkTheme),
    );
  }

  Widget body() {
    switch (_selectedIndex) {
      case 0:
        return const ChildVideoPage();
      case 1:
        return const ChildChannelPage();
      default:
        return Container();
    }
  }

  Widget customBottomNavigationBar(ThemeData theme, bool isDarkTheme) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: pink,
          unselectedItemColor: isDarkTheme ? Colors.white70 : Colors.black54,
          selectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.smart_display),
              label: 'Videos',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.live_tv),
              label: 'Channels',
            ),
            if (_isParent)
              const BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: 'Logout',
              ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      // Logout button is tapped
      await _logout(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Log out the user using the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    // Clear SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('child', false);
    await prefs.setBool('showbutton', false);
    await prefs.setString('parentEmail', '');
    await prefs.setString('childName', '');
    await prefs.setString('Securitycode', '');

    // Navigate to the main page
    Utils.pushAndRemovePrevious(context, const MainPage());
  }
}
