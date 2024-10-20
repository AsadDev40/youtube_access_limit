import 'package:kidsafe_youtube/scrap_api/models/video_data.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:kidsafe_youtube/widgets/custom_video_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildVideoPage extends StatefulWidget {
  const ChildVideoPage({super.key});

  @override
  State<ChildVideoPage> createState() => _ChildVideoPageState();
}

class _ChildVideoPageState extends State<ChildVideoPage> {
  bool _isParent = false;
  late Future<List<VideoData?>> _videoFutures;

  @override
  void initState() {
    super.initState();
    _loadIsParent();
    _loadVideos();
  }

  Future<void> _loadIsParent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isParent = prefs.getBool('parent') ?? false;
    });
  }

  Future<void> _loadVideos() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    setState(() {
      _videoFutures = Future.wait(
        childProvider.currentChild?.videos.map((videoId) {
              return YoutubeDataApi().fetchVideoData(videoId);
            }).toList() ??
            [],
      );
    });
  }

  Future<void> _refreshVideos() async {
    await _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshVideos,
        child: FutureBuilder<List<VideoData?>>(
          future: _videoFutures,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No videos found'),
              );
            }

            final videoList = snapshot.data!;
            return ListView.builder(
              itemCount: videoList.length,
              itemBuilder: (BuildContext context, int index) {
                final videoPage = videoList[index]?.video;

                if (videoPage == null) {
                  return const Text('No video data found');
                }

                return Row(
                  children: [
                    Expanded(
                      child: CustomVideoWidget(
                        title: videoPage.title ?? 'No title',
                        channelName: videoPage.channelName ?? 'No channel',
                        thumbnails: [videoPage.channelThumb ?? ''],
                        duration: videoPage.date ?? '0:00',
                        views: videoPage.viewCount ?? '0 views',
                        videoId: videoPage.videoId!,
                        videolist: childProvider.currentChild?.videos,
                      ),
                    ),
                    if (_isParent)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          var childId = childProvider.currentChild?.uid;
                          await childProvider.deleteVideoFromChild(
                              videoPage.videoId!, childId!);
                          setState(() {
                            videoList.removeAt(index);
                          });
                        },
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
