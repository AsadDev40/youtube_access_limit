// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/providers/video_provider.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:kidsafe_youtube/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';
import 'package:video_player/video_player.dart';

class OfflineShortsPage extends StatefulWidget {
  const OfflineShortsPage({super.key});

  @override
  _OfflineShortsPageState createState() => _OfflineShortsPageState();
}

class _OfflineShortsPageState extends State<OfflineShortsPage> {
  List<Map<String, dynamic>> _offlineVideos = [];
  VideoPlayerController? _currentController;
  int _selectedVideoCount = 50;
  bool isloadfirstvideo = true;
  int _currentindex = 0;
  bool _isLoading = true;
  bool _isPlaying = false;

  final Controller _tiktokController = Controller();
  @override
  void initState() {
    super.initState();
    _loadOfflineVideos();
    Provider.of<VideoProvider>(context, listen: false)
        .addListener(_onProviderChange);
    _tiktokController.addListener((event) {
      _onVideoChanged(event.pageNo ?? 0);
    });
  }

  @override
  void dispose() {
    _disposeCurrentController();
    _tiktokController.disposeListeners();
    super.dispose();
  }

  Future<void> _loadOfflineVideos({bool isRefreshing = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newVideos = await Provider.of<VideoProvider>(context, listen: false)
          .getOfflineVideos();

      if (isRefreshing) {
        _offlineVideos = newVideos; // Refresh the entire list
      } else {
        // Append new videos to the existing list
        _offlineVideos.addAll(newVideos);
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    if (_offlineVideos.isNotEmpty) {
      _initializeAndPlayFirstVideo();
    }
  }

  void _onProviderChange() async {
    final newVideos = await Provider.of<VideoProvider>(context, listen: false)
        .getOfflineVideos();
    final provider = Provider.of<VideoProvider>(context, listen: false);
    if (!provider.isDownloading) {
      _refreshScreen();
    } else if (provider.isDownloading) {
      setState(() {
        _offlineVideos = newVideos;
      });
      if (isloadfirstvideo == true) {
        _loadOfflineVideos();
        setState(() {
          isloadfirstvideo = false;
        });
      }
    }
  }

  VideoPlayerController _initializeController(int index) {
    final videoDetails = _offlineVideos[index];
    final videoPath = videoDetails['videoPath'];
    if (videoPath == null) {
      throw Exception('Video path not found');
    }

    final file = File(videoPath);
    if (!file.existsSync()) {
      throw Exception('File not found');
    }

    return VideoPlayerController.file(file)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});
        if (_isPlaying) {
          _playVideo();
        }
      });
  }

  void _refreshScreen() async {
    _disposeCurrentController();
    setState(() {
      _currentindex = 0;
      _isPlaying = false;
    });

    // Refresh offline videos, but don't clear the list
    await _loadOfflineVideos(isRefreshing: true);
  }

  void _initializeAndPlayFirstVideo() {
    if (_offlineVideos.isNotEmpty) {
      _currentController = _initializeController(_currentindex);
      _playVideo();
      setState(() {});
    }
  }

  void _disposeCurrentController() {
    _currentController?.dispose();
    _currentController = null;
  }

  void _onVideoChanged(int index) {
    _disposeCurrentController();
    setState(() {
      _currentindex = index;
    });

    _currentController = _initializeController(_currentindex);
    setState(() {});
  }

  void _playVideo() {
    _currentController?.play();
    setState(() {
      _isPlaying = true;
    });
  }

  void _pauseVideo() {
    _currentController?.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Consumer<VideoProvider>(
          builder: (context, provider, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  height: 530,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 90),
                            child: Text(
                              'Offline videos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(
                          'Download videos to watch offline. They’ll be refreshed with new content when you’re next connected to Wi-Fi.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      provider.isDownloading
                          ? Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 30),
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Downloading....',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '${provider.downloadedCount}/${provider.totalVideos} videos',
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Expanded(
                              child: _offlineVideos.isNotEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 70),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(
                                                  2), // Adjust the padding to control border thickness
                                              decoration: BoxDecoration(
                                                color: Colors
                                                    .white, // Background color for the border
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors
                                                      .black54, // Border color
                                                  width: 2.0, // Border width
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius:
                                                    20, // Adjust the size as needed
                                                backgroundColor: Colors.white,
                                                child: Icon(
                                                  Icons.download,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              'Downloaded Shorts',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              '${_offlineVideos.length} / ${_offlineVideos.length} Videos ',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      children: [
                                        _buildRadioOption(setState, 50,
                                            '30 minute watch time • 100 MB'),
                                        _buildRadioOption(setState, 100,
                                            '50 minute watch time • 200 MB'),
                                        _buildRadioOption(setState, 150,
                                            '70 minute watch time • 300 MB'),
                                      ],
                                    ),
                            ),
                      const SizedBox(height: 20),
                      if (!provider.isDownloading)
                        Column(
                          children: [
                            if (_offlineVideos.isEmpty)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  Utils.showToast(
                                      'Offline videos downloading started. Please wait');

                                  var videoList =
                                      await YoutubeDataApi().fetchShortVideos();
                                  List<Map<String, String>> videoDetails =
                                      videoList.map((video) {
                                    return {
                                      'videoId': video.videoId ?? '',
                                      'title': video.title ?? '',
                                      'channelName': video.channelName ?? '',
                                      'thumbnailUrl': video.thumbnailUrl ?? '',
                                    };
                                  }).toList();

                                  List<String> videoUrls =
                                      videoDetails.map((details) {
                                    return 'https://www.youtube.com/shorts/${details['videoId']}';
                                  }).toList();

                                  await provider.downloadVideos(videoUrls,
                                      _selectedVideoCount, videoDetails);

                                  setState(() {}); // Trigger UI rebuild
                                },
                                child: const Text(
                                  'Download',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                EasyLoading.show();
                                await provider.clearOfflineVideos();
                                EasyLoading.dismiss();
                                Utils.showToast(
                                    'Offline shorts cleared successfully!');
                                setState(() {}); // Trigger UI rebuild
                              },
                              child: const Text(
                                'Free up space',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption(
      StateSetter setState, int videoCount, String description) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '$videoCount videos',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(description,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Radio<int>(
        value: videoCount,
        groupValue: _selectedVideoCount,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedVideoCount = value;
            });
          }
        },
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildVideoOverlay(BuildContext context, int index) {
    final video = _offlineVideos[index];
    final String? thumbnailPath = video['thumbnailPath'] as String?;

    return Stack(
      children: [
        Positioned(
          bottom: 90,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        thumbnailPath != null && thumbnailPath.isNotEmpty
                            ? FileImage(File(thumbnailPath))
                            : const AssetImage('assets/placeholder.png')
                                as ImageProvider,
                    radius: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    video['channelName'] ?? 'Unknown Channel',
                    style: const TextStyle(
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.verified, size: 15, color: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                video['title'] ?? 'No Title',
                style: const TextStyle(
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 10,
          right: 20,
          child: SizedBox(
            height: 35,
            width: 100,
            child: TextButton(
              onPressed: () {
                _showSettingsBottomSheet(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
              child: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252628),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineVideos.isEmpty
              ? _buildNoOfflineVideosView()
              : TikTokStyleFullPageScroller(
                  contentSize: _offlineVideos.length,
                  swipePositionThreshold: 0.2,
                  controller: _tiktokController,
                  builder: (context, index) {
                    return Stack(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: _currentController != null &&
                                      _currentController!.value.isInitialized
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        VideoPlayer(_currentController!),
                                        if (!_isPlaying) // Show play button if not playing
                                          Center(
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 60,
                                              ),
                                              onPressed: _togglePlayPause,
                                            ),
                                          ),
                                      ],
                                    )
                                  : const SizedBox(),
                            ),
                          ),
                        ),
                        _buildVideoOverlay(context, index),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildNoOfflineVideosView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_download_outlined,
            size: 100,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          const Text(
            'No offline shorts available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Download some shorts to watch them offline.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pink),
            onPressed: () => _showSettingsBottomSheet(context),
            child: const Text(
              'Download Shorts',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
