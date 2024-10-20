import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:kidsafe_youtube/providers/video_provider.dart';

class BackgroundServiceManager {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onBackground,
        autoStart: true,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Initialize VideoProvider and call its onStart method
    final videoProvider = VideoProvider();
    videoProvider.onStart();

    // Set up periodic tasks or other background work
    Timer.periodic(const Duration(seconds: 1), (timer) {});

    service.on("stop").listen((event) {
      service.stopSelf();
    });

    service.on("start_download").listen((event) async {
      if (event != null) {
        final videoProvider = VideoProvider();
        await videoProvider.downloadVideos(
          event['videoIds'] as List<String>,
          event['count'] as int,
          event['videoDetails'] as List<Map<String, dynamic>>,
        );
      }
    });

    return true;
  }

  @pragma('vm:entry-point')
  static Future<bool> onBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Handle iOS background execution
    service.on('start_download').listen((event) async {
      if (event != null) {
        final videoProvider = VideoProvider();
        await videoProvider.downloadVideos(
          event['videoIds'] as List<String>,
          event['count'] as int,
          event['videoDetails'] as List<Map<String, dynamic>>,
        );
      }
    });

    return true;
  }
}
