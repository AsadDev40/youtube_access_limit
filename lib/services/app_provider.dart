import 'package:kidsafe_youtube/providers/auth_provider.dart';
import 'package:kidsafe_youtube/providers/file_upload_provider.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/providers/image_picker_provider.dart';
import 'package:kidsafe_youtube/providers/subscription.dart';
import 'package:kidsafe_youtube/providers/subscription_provider.dart';
import 'package:kidsafe_youtube/providers/theme_provider.dart';
import 'package:kidsafe_youtube/providers/video_provider.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class AppProvider extends StatelessWidget {
  const AppProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider(create: (context) => ChildProvider()),
          ChangeNotifierProvider(create: (context) => ImagePickerProvider()),
          ChangeNotifierProvider(create: (context) => FileUploadProvider()),
          ChangeNotifierProvider(create: (context) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => VideoProvider()),
          ChangeNotifierProvider(create: (context) => Subscriptionprovider()),
        ],
        child: child,
      );
}
