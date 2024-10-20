// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/providers/video_provider.dart';
import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  _ShortsPageState createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final List<Video> _videos = []; // Store Video objects instead of IDs
  final List<YoutubePlayerController> _controllers = [];
  bool _isLoading = false;
  int _currentBatch = 0;
  final int _batchSize = 50;
  int _selectedVideoCount = 50;
  List<Map<String, dynamic>> _offlineVideos = [];

  bool _isButtonVisible = false;
  Timer? _hideButtonTimer;

  @override
  void initState() {
    super.initState();
    // _loadOfflineVideos();
    _loadMoreShorts();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _hideButtonTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOfflineVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _offlineVideos = await Provider.of<VideoProvider>(context, listen: false)
          .getOfflineVideos();
      print('offline videos: ${_offlineVideos.length}');
    } catch (e) {
      rethrow;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreShorts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newShorts = await YoutubeDataApi().fetchShortVideos();

      final newBatch =
          newShorts.skip(_currentBatch * _batchSize).take(_batchSize).toList();

      setState(() {
        _videos.addAll(newBatch);
        _currentBatch++;
      });

      _loadVideoControllers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load shorts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadVideoControllers() {
    for (var video in _videos) {
      _controllers.add(
        YoutubePlayerController(
          initialVideoId: video.videoId!,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            loop: true,
            mute: false,
            showLiveFullscreenButton: false,
            hideControls: true,
          ),
        ),
      );
    }
  }

  void _togglePlayPause(int index) {
    final controller = _controllers[index];
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    _showButtonTemporarily();
  }

  void _showButtonTemporarily() {
    setState(() {
      _isButtonVisible = true;
    });

    _hideButtonTimer?.cancel();
    _hideButtonTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _isButtonVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? const Center(child: Text('No Shorts available'))
              : Stack(
                  children: [
                    Swiper(
                      itemBuilder: (BuildContext context, int index) {
                        if (index == _videos.length) {
                          return _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const Center(
                                  child: Text('No more shorts available'),
                                );
                        }

                        return GestureDetector(
                          onTap: () => _togglePlayPause(index),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              YoutubePlayer(
                                controller: _controllers[index],
                                showVideoProgressIndicator: false,
                                aspectRatio: 9 / 16,
                              ),
                              if (_isButtonVisible)
                                Center(
                                  child: Icon(
                                    _controllers[index].value.isPlaying
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              _buildVideoOverlay(context, index),
                            ],
                          ),
                        );
                      },
                      itemCount: _videos.length + 1,
                      scrollDirection: Axis.vertical,
                      onIndexChanged: (index) {
                        if (index == _videos.length - 1 && !_isLoading) {
                          _loadMoreShorts();
                        }
                      },
                    ),
                    Container(
                      color: Colors.black,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 25, left: 8, right: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Shorts',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  _showSettingsBottomSheet(context);
                                },
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
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
                // Listening to changes in isDownloading
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
    final video = _videos[index];
    return Positioned(
      bottom: 60,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(video.thumbnailUrl ?? ''),
                radius: 16,
              ),
              const SizedBox(width: 6),
              Text(
                video.channelName ?? 'Unknown Channel',
                style: const TextStyle(
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.verified, size: 15, color: Colors.white),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            video.title ?? 'No Title',
            style: const TextStyle(
              color: Colors.white,
              overflow: TextOverflow.ellipsis,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.music_note,
                size: 15,
                color: Colors.white,
              ),
              Text(
                'Original Audio',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
