// // ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

// import 'dart:async';
// import 'dart:io';
// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';
// import 'package:kidsafe_youtube/Utils/utils.dart';
// import 'package:kidsafe_youtube/providers/video_provider.dart';
// import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
// import 'package:provider/provider.dart';

// class OfflineShortsPage extends StatefulWidget {
//   const OfflineShortsPage({super.key});

//   @override
//   _OfflineShortsPageState createState() => _OfflineShortsPageState();
// }

// class _OfflineShortsPageState extends State<OfflineShortsPage> {
//   List<Map<String, dynamic>> _offlineVideos = [];
//   BetterPlayerController? _currentController;
//   int _selectedVideoCount = 50; // Default selected count
//   int _currentPage = 0;
//   final PageController _pageController = PageController(initialPage: 0);
//   bool _isLoading = true; // Add a loading state

//   @override
//   void initState() {
//     super.initState();
//     _loadOfflineVideos();
//     _pageController.addListener(_onPageChanged);
//   }

//   Future<void> _loadOfflineVideos() async {
//     setState(() {
//       _isLoading = true; // Start loading
//     });

//     try {
//       // Fetch offline videos using the updated getOfflineVideos method
//       _offlineVideos = await Provider.of<VideoProvider>(context, listen: false)
//           .getOfflineVideos();
//     } catch (e) {
//       print('Error loading offline videos: $e');
//       // Optionally, show a user-friendly error message
//     } finally {
//       setState(() {
//         _isLoading = false; // Stop loading
//       });
//     }
//   }

//   BetterPlayerController _initializeController(int index) {
//     final videoDetails = _offlineVideos[index];
//     final videoPath =
//         videoDetails['videoPath']; // Access 'videoPath' from the map
//     if (videoPath == null) {
//       throw Exception('Video path not found');
//     }

//     final file = File(videoPath);
//     if (!file.existsSync()) {
//       throw Exception('File not found');
//     }

//     // Initialize BetterPlayerController with the video file
//     return BetterPlayerController(
//       BetterPlayerConfiguration(
//           aspectRatio: 9 / 16,
//           autoPlay: true,
//           looping: true,
//           autoDispose: false,
//           controlsConfiguration:
//               BetterPlayerControlsConfiguration(showControls: false)),
//       betterPlayerDataSource: BetterPlayerDataSource(
//         BetterPlayerDataSourceType.file,
//         videoPath,
//       ),
//     );
//   }

//   void _onPageChanged() {
//     int newPage = _pageController.page?.round() ?? 0;

//     if (newPage != _currentPage) {
//       _disposeCurrentController();
//       _currentPage = newPage;
//       _currentController = _initializeController(_currentPage);
//       _playVideo();
//       setState(() {});
//     }
//   }

//   void _disposeCurrentController() {
//     if (_currentController != null) {
//       _currentController?.dispose();
//       _currentController = null;
//       print('Controller disposed for page $_currentPage');
//     }
//   }

//   void _playVideo() {
//     _currentController?.play();
//   }

//   @override
//   void dispose() {
//     _disposeCurrentController();

//     _pageController.dispose();
//     print('disposed controllerss: $_currentPage');
//     super.dispose();
//   }

//   void _showSettingsBottomSheet(BuildContext context) {
//     final videoprovider = Provider.of<VideoProvider>(context, listen: false);

//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             int _totalVideos = 0;
//             int _downloadedVideos = 0;
//             double _downloadProgress = 0.0;
//             bool _isDownloading = false;

//             void _startDownload() async {
//               try {
//                 Utils.showToast(
//                     'Offline videos downloading started. Please wait');
//                 var videoList = await YoutubeDataApi().fetchShortVideos();

//                 List<Map<String, String>> videoDetails = videoList.map((video) {
//                   return {
//                     'videoId': video.videoId ?? '',
//                     'title': video.title ?? '',
//                     'channelName': video.channelName ?? '',
//                     'thumbnailUrl': video.thumbnailUrl ?? '',
//                   };
//                 }).toList();

//                 _totalVideos = videoDetails.length;
//                 List<String> videoUrls = videoDetails.map((details) {
//                   return 'https://www.youtube.com/shorts/${details['videoId']}';
//                 }).toList();

//                 await videoprovider
//                     .downloadVideos(videoUrls, _totalVideos, videoDetails,
//                         onProgress: (downloaded, total) {
//                   setState(() {
//                     _downloadedVideos = downloaded;
//                     _downloadProgress = downloaded / total;
//                   });
//                 });

//                 Utils.showToast(
//                     'Offline video downloaded successfully. You can watch them in offline videos.');
//               } catch (e) {
//                 Utils.showToast('Error fetching videos');
//               } finally {
//                 setState(() {
//                   _isDownloading = false;
//                 });
//               }
//             }

//             return Container(
//               decoration: const BoxDecoration(color: Colors.white),
//               height: 455,
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       const Padding(
//                         padding: EdgeInsets.only(right: 90),
//                         child: Text(
//                           'Offline videos',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 10, right: 10),
//                     child: Text(
//                       'Download videos to watch offline. They’ll be refreshed with new content when you’re next connected to Wi-Fi.',
//                       style: TextStyle(fontSize: 14, color: Colors.grey),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   if (_isDownloading)
//                     Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(value: _downloadProgress),
//                           const SizedBox(height: 16),
//                           Text('Downloading...'),
//                           Text('$_downloadedVideos/$_totalVideos videos'),
//                         ],
//                       ),
//                     ),
//                   if (!_isDownloading)
//                     Expanded(
//                       child: ListView(
//                         children: [
//                           _buildRadioOption(
//                               setState, 50, '30 minute watch time • 100 MB'),
//                           _buildRadioOption(
//                               setState, 100, '50 minute watch time • 200 MB'),
//                           _buildRadioOption(
//                               setState, 150, '70 minute watch time • 300 MB'),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 50),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       backgroundColor: Colors.redAccent,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _isDownloading = true;
//                       });
//                       _startDownload();
//                     },
//                     child: const Text(
//                       'Download',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildRadioOption(
//       StateSetter setState, int videoCount, String description) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       title: Text(
//         '$videoCount videos',
//         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//       ),
//       subtitle: Text(description,
//           style: const TextStyle(fontSize: 12, color: Colors.grey)),
//       trailing: Radio<int>(
//         value: videoCount,
//         groupValue: _selectedVideoCount,
//         onChanged: (value) {
//           if (value != null) {
//             setState(() {
//               _selectedVideoCount = value;
//             });
//           }
//         },
//         activeColor: Colors.redAccent,
//       ),
//     );
//   }

//   Future<void> _clearStorage() async {
//     await Provider.of<VideoProvider>(context, listen: false)
//         .clearOfflineVideos();
//     setState(() {
//       _offlineVideos.clear();
//     });
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Offline shorts cleared successfully!')),
//     );
//   }

//   Widget _buildVideoOverlay(BuildContext context, int index) {
//     final video = _offlineVideos[index];
//     final String? thumbnailPath = video['thumbnailPath'] as String?;
//     return Positioned(
//       bottom: 60,
//       left: 20,
//       right: 20,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 backgroundImage:
//                     thumbnailPath != null && thumbnailPath.isNotEmpty
//                         ? FileImage(File(thumbnailPath))
//                         : const AssetImage('assets/placeholder.png')
//                             as ImageProvider,
//                 radius: 16,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 video['channelName'] ?? 'Unknown Channel',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               const Icon(Icons.verified, size: 15, color: Colors.white),
//               const SizedBox(width: 6),
//               TextButton(
//                 onPressed: () {
//                   // Handle follow
//                 },
//                 child: const Text(
//                   'Follow',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(
//             video['title'] ?? 'No Title',
//             style: const TextStyle(
//               color: Colors.white,
//               overflow: TextOverflow.ellipsis,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF252628),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF252628),
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.white,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         actions: _offlineVideos.isNotEmpty
//             ? [
//                 ElevatedButton(
//                     style: ButtonStyle(
//                       minimumSize: WidgetStateProperty.all(Size(50, 35)),
//                     ),
//                     onPressed: () => _clearStorage(),
//                     child: const Text(
//                       'Clear Shorts',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.black,
//                       ),
//                     )),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.settings,
//                     color: Colors.white,
//                   ),
//                   onPressed: () => _showSettingsBottomSheet(context),
//                 ),
//               ]
//             : null,
//         title: const Text(
//           'Offline Shorts',
//           style: TextStyle(
//               color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _offlineVideos.isEmpty
//               ? _buildNoOfflineVideosView()
//               : Stack(
//                   children: [
//                     PageView.builder(
//                       controller: _pageController,
//                       itemCount: _offlineVideos.length,
//                       scrollDirection: Axis.vertical,
//                       itemBuilder: (context, index) {
//                         _currentController ??= _initializeController(index);
//                         return BetterPlayer(
//                           controller: _currentController!,
//                           key: ValueKey(index),
//                         );
//                       },
//                     ),
//                     _offlineVideos.isNotEmpty
//                         ? _buildVideoOverlay(context, _currentPage)
//                         : Container(),
//                   ],
//                 ),
//     );
//   }

//   Widget _buildNoOfflineVideosView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.cloud_download_outlined,
//             size: 100,
//             color: Colors.white,
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'No offline shorts available',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 10),
//           const Text(
//             'Download some shorts to watch them offline.',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () => _showSettingsBottomSheet(context),
//             child: const Text('Download Shorts'),
//           ),
//         ],
//       ),
//     );
//   }
// }
