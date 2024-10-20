// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoProvider with ChangeNotifier {
  bool isDownloading = false;
  double downloadProgress = 0.0;
  final int maxCacheSize = 500 * 1024 * 1024; // 500 MB
  int downloadedCount = 0;
  int totalVideos = 0;
  int currentVideoIndex = 0;
  final StreamController<List<Map<String, dynamic>>> _videosController =
      StreamController.broadcast();
  Stream<List<Map<String, dynamic>>> get videosStream =>
      _videosController.stream;

  Future<void> onStart() async {
    WidgetsFlutterBinding.ensureInitialized();
    final service = FlutterBackgroundService();

    service.on('start_download').listen((event) async {
      if (event != null) {
        await downloadVideos(
          event['videoIds'] as List<String>,
          event['count'] as int,
          event['videoDetails'] as List<Map<String, dynamic>>,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> downloadVideos(List<String> videoIds,
      int count, List<Map<String, dynamic>> videoDetails) async {
    List<Map<String, dynamic>> newlyDownloadedVideos = [];

    try {
      isDownloading = true;
      totalVideos = count;
      downloadedCount = 0;
      notifyListeners();

      var status = await Permission.storage.request();
      if (!status.isGranted) {
        print("Storage permission is not granted.");
        isDownloading = false;
        notifyListeners();
        return newlyDownloadedVideos;
      }

      final directory = await getTemporaryDirectory();
      final videoDir = Directory('${directory.path}/offline_videos');
      final thumbnailDir = Directory('${directory.path}/thumbnails');

      if (!videoDir.existsSync()) {
        videoDir.createSync(recursive: true);
      }
      if (!thumbnailDir.existsSync()) {
        thumbnailDir.createSync(recursive: true);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Map<String, String>> downloadedVideos = [];
      var yt = YoutubeExplode();

      for (int i = 0; i < count; i++) {
        final videoId = videoIds[i];
        final details = videoDetails[i];
        final manifest = await yt.videos.streamsClient.getManifest(videoId);
        final streamInfo = manifest.muxed.withHighestBitrate();
        final String filename = 'video_${i + 1}.mp4';
        final videoFilePath = '${videoDir.path}/$filename';
        final String thumbnailFilename = 'video_${i + 1}.jpg';
        final thumbnailPath = '${thumbnailDir.path}/$thumbnailFilename';

        try {
          var stream = yt.videos.streamsClient.get(streamInfo);
          var file = File(videoFilePath);
          await file.create(recursive: true);

          await stream.listen((data) {
            file.writeAsBytesSync(data, mode: FileMode.append);
          }).asFuture();

          print('Download complete for $filename');
          final thumbnailUrl = details['thumbnailUrl']!;
          await _downloadThumbnail(thumbnailUrl, thumbnailPath);

          // Add video to the newly downloaded list
          newlyDownloadedVideos.add({
            'videoPath': videoFilePath,
            'thumbnailPath': thumbnailPath,
            'title': details['title']!,
            'channelName': details['channelName']!,
          });

          downloadedVideos.add({
            'videoPath': videoFilePath,
            'thumbnailPath': thumbnailPath,
            'title': details['title']!,
            'channelName': details['channelName']!,
          });

          downloadedCount++;
          notifyListeners();

          // Save each video to cache after downloading and managing cache
          await _manageCache(videoDir);

          // Update the SharedPreferences after each video is downloaded
          await prefs.setString('offline_videos', jsonEncode(downloadedVideos));
        } catch (e) {
          print('Failed to download video: $e');
        }
      }
    } catch (e) {
      print('Error downloading videos: $e');
    } finally {
      isDownloading = false;
      notifyListeners();
    }

    return newlyDownloadedVideos; // Return the list of newly downloaded videos
  }

  Future<void> _downloadThumbnail(String url, String savePath) async {
    try {
      _sanitizeFilename(url);
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final file = File(savePath);
        final fileSink = file.openWrite();

        await response.listen((data) {
          fileSink.add(data);
        }, onDone: () async {
          await fileSink.close();
        }).asFuture();
      } else {
        print('Failed to download thumbnail: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to download thumbnail: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNewlyDownloadedVideos(
      List<String> videoIds,
      int count,
      List<Map<String, dynamic>> videoDetails) async {
    List<Map<String, dynamic>> newlyDownloadedVideos =
        await downloadVideos(videoIds, count, videoDetails);

    return newlyDownloadedVideos;
  }

  String _sanitizeFilename(String url) {
    // Sanitize the URL to create a valid filename
    return '${url.replaceAll(RegExp(r'[\/:\*?"<>|]'), '_')}.jpg';
  }

  Future<void> _manageCache(Directory cacheDir) async {
    final List<FileSystemEntity> files = cacheDir.listSync();
    int totalSize = 0;

    // Calculate total cache size
    for (var file in files) {
      if (file is File) {
        totalSize += file.lengthSync();
      }
    }

    // If cache size exceeds limit, delete oldest files
    if (totalSize > maxCacheSize) {
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      for (var file in files) {
        if (file is File) {
          totalSize -= file.lengthSync();
          file.deleteSync();
          if (totalSize <= maxCacheSize) {
            break;
          }
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? offlineVideosString = prefs.getString('offline_videos');
    if (offlineVideosString != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(offlineVideosString));
    }
    return [];
  }

  Future<int> getOfflineVideosCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? offlineVideosString = prefs.getString('offline_videos');
    if (offlineVideosString != null) {
      List<Map<String, dynamic>> offlineVideos =
          List<Map<String, dynamic>>.from(jsonDecode(offlineVideosString));
      return offlineVideos.length;
    }
    return 0; // No videos found
  }

  Future<void> clearOfflineVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? offlineVideosString = prefs.getString('offline_videos');

    if (offlineVideosString != null) {
      List<Map<String, dynamic>> offlineVideos =
          List<Map<String, dynamic>>.from(jsonDecode(offlineVideosString));

      for (var videoData in offlineVideos) {
        String videoPath = videoData['videoPath'];
        final file = File(videoPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            print('Failed to delete video: $e');
          }
        }
      }

      await prefs.remove('offline_videos');
      notifyListeners();
    }
  }
}
