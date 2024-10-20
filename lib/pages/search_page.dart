// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, unused_local_variable, await_only_futures

import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/helpers/suggestion_history.dart';
import '/widgets/channel_widget.dart';
import '/widgets/playList_widget.dart';
import '/widgets/video_widget.dart';
import '/widgets/custom_video_widget.dart';
import 'package:kidsafe_youtube/scrap_api/models/channle.dart';
import 'package:kidsafe_youtube/scrap_api/models/playlist.dart';
import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';

class SearchPage extends StatefulWidget {
  const SearchPage(this.query, {super.key});

  final String query;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final YoutubeDataApi youtubeDataApi = YoutubeDataApi();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> contentList = [];
  bool isLoading = false;
  bool isSearching = false;
  bool isChild = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _checkUserType();
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty &&
          _searchController.text != searchQuery) {
        setState(() {
          searchQuery = _searchController.text;
          contentList.clear();
          isSearching = true;
          _loadMore(searchQuery);
        });
      }
    });
    SuggestionHistory.init();
  }

  Future<void> _checkUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var ischild = await prefs.getBool('child');
    setState(() {
      ischild = isChild;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: SizedBox(
          width: 400,
          height: 36,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primaryColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primaryColor, width: 0.3),
                borderRadius: BorderRadius.circular(30.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primaryColor, width: 0.3),
                borderRadius: BorderRadius.circular(30.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                searchQuery = "";
                contentList.clear();
                isSearching = false;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (isSearching && isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!isSearching && contentList.isEmpty)
              const Center(child: Text(''))
            else if (contentList.isEmpty)
              const Center(child: Text('No results found'))
            else
              LazyLoadScrollView(
                isLoading: isLoading,
                onEndOfPage: () => _loadMore(searchQuery),
                child: ListView.builder(
                  itemCount: contentList.length,
                  itemBuilder: (context, index) {
                    if (index == contentList.length - 1 && isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      final item = contentList[index];
                      if (item is Video) {
                        return _buildVideoWidget(item);
                      } else if (item is Channel) {
                        return channel(item);
                      } else if (item is PlayList) {
                        return playList(item);
                      }
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoWidget(Video video) {
    if (isChild) {
      final List<String> thumbnailUrls = (video.thumbnails
              ?.map((thumb) => thumb.url)
              .where((url) => url != null)
              .cast<String>()
              .toList()) ??
          [];
      return CustomVideoWidget(
        title: video.title.toString(),
        channelName: video.channelName.toString(),
        thumbnails: thumbnailUrls,
        duration: video.duration.toString(),
        views: video.views.toString(),
        videoId: video.videoId.toString(),
      );
    } else {
      return VideoWidget(video: video); // Use default video widget
    }
  }

  Widget playList(PlayList playList) {
    return PlayListWidget(
      id: playList.playListId!,
      thumbnails: playList.thumbnails!,
      videoCount: playList.videoCount!,
      title: playList.title!,
      channelName: playList.channelName!,
    );
  }

  Widget channel(Channel channel) {
    return ChannelWidget(
      id: channel.channelId!,
      thumbnail: channel.thumbnail!,
      title: channel.title!,
      videoCount: channel.videoCount,
      subscriberCount: channel.subscriberCount,
    );
  }

  Future<void> _loadMore(String query) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<dynamic> newList;
      if (isChild) {
        // Fetch from child's video and channel list
        final childProvider =
            Provider.of<ChildProvider>(context, listen: false);
        newList = await _fetchChildContent(childProvider, query);
      } else {
        // Fetch from YouTube API
        newList = await youtubeDataApi.fetchSearchVideo(query);
      }

      // Prioritize videos that match the search query in the title or channel name
      newList.sort((a, b) {
        int aMatches = _countQueryMatches(a, query);
        int bMatches = _countQueryMatches(b, query);
        return bMatches.compareTo(aMatches); // Higher matches come first
      });

      setState(() {
        contentList.addAll(newList);
        isLoading = false;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load more results')),
      );
    }
  }

  int _countQueryMatches(dynamic item, String query) {
    String title = '';
    String channelName = '';

    if (item is Video) {
      title = item.title ?? '';
      channelName = item.channelName ?? '';
    } else if (item is Channel) {
      title = item.title ?? '';
    }

    // Count how many times the query appears in the title or channel name
    int titleMatches =
        _countOccurrences(title.toLowerCase(), query.toLowerCase());
    int channelMatches =
        _countOccurrences(channelName.toLowerCase(), query.toLowerCase());

    return titleMatches + channelMatches;
  }

  int _countOccurrences(String text, String query) {
    return text.split(query).length - 1;
  }

  Future<List<dynamic>> _fetchChildContent(
      ChildProvider childProvider, String query) async {
    final videoIds = childProvider.currentChild?.videos ?? [];
    // final channelIds = childProvider.currentChild?.channels ?? [];

    // Fetch videos concurrently
    final videos = await Future.wait(
      videoIds.map((videoId) async {
        final videoData = await YoutubeDataApi().fetchVideoData(videoId);
        if (videoData != null && videoData.video != null) {
          return videoData.video?.toVideo();
        } else {
          return null; // Explicitly returning null for failed fetches
        }
      }),
    );

    // final channels = await Future.wait(
    //   channelIds.map((channelId) async {
    //     final channelData = await YoutubeDataApi().fetchChannelData(channelId);
    //     if (channelData != null) {

    //       print(
    //           'channel subscriber: ${channelData.channel.tochannel().subscriberCount}');
    //       return channelData.channel.tochannel();
    //     } else {
    //       return null; // Explicitly returning null for failed fetches
    //     }
    //   }),
    // );

    final filteredVideos = videos.where((video) => video != null).cast<Video>();
    // final filteredChannels =
    //     channels.where((channel) => channel != null).cast<Channel>();

    List<dynamic> combinedList = [
      ...filteredVideos,
    ];

    if (combinedList.isEmpty) {}

    return combinedList;
  }
}
