// ignore_for_file: unused_element, avoid_function_literals_in_foreach_calls, avoid_print

library youtube_data_api;

import 'package:kidsafe_youtube/scrap_api/helpers/extract_json.dart';
import 'package:kidsafe_youtube/scrap_api/helpers/helpers_extension.dart';
import 'package:kidsafe_youtube/scrap_api/models/channel_data.dart';
import 'package:kidsafe_youtube/scrap_api/models/channel_page.dart';

import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import 'package:kidsafe_youtube/scrap_api/models/video_data.dart';
import 'package:kidsafe_youtube/scrap_api/models/video_page.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:xml2json/xml2json.dart';

class YoutubeDataApi {
  ///Continue token for load more videos on youtube search
  //String? _searchToken;

  ///Continue token for load more videos on youtube channel
  String? _channelToken;

  ///Continue token for load more videos on youtube playlist
  String? _playListToken;

  ///Last search query on youtube search
  String? lastQuery;

  ///Get list of videos and playlists and channels from youtube search with query
  Future<List<Video>> fetchSearchVideo(String query) async {
    List<Video> list = [];
    var client = http.Client();
    var response = await client.get(
      Uri.parse(
        'https://www.youtube.com/results?search_query=$query&hl=en',
      ),
    );
    var jsonMap = _getJsonMap(response);
    if (jsonMap != null) {
      var contents = jsonMap
          .get('contents')
          ?.get('twoColumnSearchResultsRenderer')
          ?.get('primaryContents')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents');

      var contentList = contents?.toList();
      for (var element in contentList!) {
        if (element.containsKey('videoRenderer')) {
          ///Element is Video
          Video video = Video.fromMap(element);
          list.add(video);
        }
      }
      //_searchToken = _getContinuationToken(jsonMap);
    }

    return list;
  }

  ///Get list of trending videos on youtube
  Future<List<Video>> fetchTrendingVideo() async {
    List<Video> list = [];
    var client = http.Client();

    // Adjust URL for pagination if needed
    var url = 'https://www.youtube.com/feed/trending?hl=en';

    var response = await client.get(
      Uri.parse(url),
    );
    var raw = response.body;
    var root = parser.parse(raw);
    final scriptText = root
        .querySelectorAll('script')
        .map((e) => e.text)
        .toList(growable: false);
    var initialData =
        scriptText.firstWhereOrNull((e) => e.contains('var ytInitialData = '));
    initialData ??= scriptText
        .firstWhereOrNull((e) => e.contains('window["ytInitialData"] ='));
    var jsonMap = extractJson(initialData!);
    if (jsonMap != null) {
      var contents = jsonMap
          .get('contents')
          ?.get('twoColumnBrowseResultsRenderer')
          ?.getList('tabs')
          ?.firstOrNull
          ?.get('tabRenderer')
          ?.get('content')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('shelfRenderer')
          ?.get('content')
          ?.get('expandedShelfContentsRenderer')
          ?.getList('items');
      var firstList = contents != null ? contents.toList() : [];

      var secondContents = jsonMap
          .get('contents')
          ?.get('twoColumnBrowseResultsRenderer')
          ?.getList('tabs')
          ?.firstOrNull
          ?.get('tabRenderer')
          ?.get('content')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.elementAtSafe(3)
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('shelfRenderer')
          ?.get('content')
          ?.get('expandedShelfContentsRenderer')
          ?.getList('items');
      var secondList = secondContents != null ? secondContents.toList() : [];

      var contentList = [...firstList, ...secondList];

      for (var element in contentList) {
        Video video = Video.fromMap(element);
        list.add(video);
      }
    }

    return list;
  }

  Future<List<Video>> fetchHomeVideos() async {
    const String apiKey = 'AIzaSyBccVeCz3qHbxCqDA3M25xrfJEo8njCyCg';
    const String urlBase =
        'https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails,statistics&chart=mostPopular&maxResults=200&key=$apiKey';
    const String cacheKey = 'home_videos';
    const String cacheKeyTimestamp = 'home_videos_timestamp';

    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    final cacheTimestamp = prefs.getInt(cacheKeyTimestamp);

    // Check if cache exists and is not expired (1 day)
    if (cachedData != null && cacheTimestamp != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
      const threeDaysInMillis = 1 * 24 * 60 * 60 * 1000;

      if (cacheAge < threeDaysInMillis) {
        try {
          final List<dynamic> decodedData = json.decode(cachedData);
          return decodedData
              .map((videoJson) => Video.fromSnippet2(videoJson))
              .toList();
        } catch (e) {
          print('Error decoding cached data: $e');
          throw Exception('Failed to decode cached data');
        }
      } else {
        // Clear old cache
        await prefs.remove(cacheKey);
        await prefs.remove(cacheKeyTimestamp);
      }
    }

    // No valid cache found, fetching from API
    final List<Video> videoList = [];
    String? nextPageToken;
    bool hasMorePages = true;

    while (hasMorePages) {
      final String url =
          nextPageToken != null ? '$urlBase&pageToken=$nextPageToken' : urlBase;

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          final items = jsonResponse['items'] as List<dynamic>?;

          if (items != null) {
            for (var item in items) {
              try {
                Video video = Video.fromSnippet2(item);
                videoList.add(video);
              } catch (e) {
                print('Error parsing video item: $e');
              }
            }
          }

          // Store the fetched data in cache using toMap method
          final List<Map<String, dynamic>> videoMapList =
              videoList.map((video) => video.toSnippet2()).toList();
          await prefs.setString(cacheKey, json.encode(videoMapList));
          await prefs.setInt(
              cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);

          nextPageToken = jsonResponse['nextPageToken'];
          hasMorePages = nextPageToken != null;
        } catch (e) {
          throw Exception('Failed to parse JSON');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Quota exceeded. Please try again later.');
      } else {
        throw Exception(
            'Failed to load videos with status code: ${response.statusCode}');
      }
    }

    return videoList;
  }

  Future<List<Video>> fetchShortVideos() async {
    final List<Video> list = [];
    String apiKey = 'AIzaSyBccVeCz3qHbxCqDA3M25xrfJEo8njCyCg';
    String url = 'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&type=video'
        '&q=shorts'
        '&videoDuration=short'
        '&order=viewCount'
        '&maxResults=50'
        '&key=$apiKey';

    String? nextPageToken;
    bool hasMorePages = true;

    while (hasMorePages) {
      final response = await http.get(Uri.parse(
          nextPageToken != null ? '$url&pageToken=$nextPageToken' : url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final items = jsonResponse['items'] as List<dynamic>;

        for (var item in items) {
          Video video = Video.fromShorts(item);
          list.add(video);
        }

        nextPageToken = jsonResponse['nextPageToken'];
        hasMorePages = nextPageToken != null;
      } else {
        throw Exception('Failed to load videos');
      }
    }

    return list;
  }

  ///Get list of trending music videos on youtube
  Future<List<Video>> fetchTrendingMusic() async {
    String params = "4gINGgt5dG1hX2NoYXJ0cw%3D%3D";
    List<Video> list = [];
    var client = http.Client();
    var url = 'https://www.youtube.com/feed/trending?bp=$params&hl=en';

    var response = await client.get(
      Uri.parse(url),
    );
    var raw = response.body;
    var root = parser.parse(raw);
    final scriptText = root
        .querySelectorAll('script')
        .map((e) => e.text)
        .toList(growable: false);
    var initialData =
        scriptText.firstWhereOrNull((e) => e.contains('var ytInitialData = '));
    initialData ??= scriptText
        .firstWhereOrNull((e) => e.contains('window["ytInitialData"] ='));
    var jsonMap = extractJson(initialData!);
    if (jsonMap != null) {
      var contents = jsonMap
          .get('contents')
          ?.get('twoColumnBrowseResultsRenderer')
          ?.getList('tabs')
          ?.elementAtSafe(1)
          ?.get('tabRenderer')
          ?.get('content')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('shelfRenderer')
          ?.get('content')
          ?.get('expandedShelfContentsRenderer')
          ?.getList('items');
      var contentList = contents != null ? contents.toList() : [];
      contentList.forEach((element) {
        Video video = Video.fromMap(element);
        list.add(video);
      });
    }
    return list;
  }

  ///Get list of trending gaming videos on youtube
  Future<List<Video>> fetchTrendingGaming() async {
    String params = "4gIcGhpnYW1pbmdfY29ycHVzX21vc3RfcG9wdWxhcg";
    List<Video> list = [];
    var client = http.Client();
    var response = await client.get(
      Uri.parse(
        'https://www.youtube.com/feed/trending?bp=$params&hl=en',
      ),
    );
    var raw = response.body;
    var root = parser.parse(raw);
    final scriptText = root
        .querySelectorAll('script')
        .map((e) => e.text)
        .toList(growable: false);
    var initialData =
        scriptText.firstWhereOrNull((e) => e.contains('var ytInitialData = '));
    initialData ??= scriptText
        .firstWhereOrNull((e) => e.contains('window["ytInitialData"] ='));
    var jsonMap = extractJson(initialData!);
    if (jsonMap != null) {
      var contents = jsonMap
          .get('contents')
          ?.get('twoColumnBrowseResultsRenderer')
          ?.getList('tabs')
          ?.elementAtSafe(2)
          ?.get('tabRenderer')
          ?.get('content')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('shelfRenderer')
          ?.get('content')
          ?.get('expandedShelfContentsRenderer')
          ?.getList('items');
      var contentList = contents != null ? contents.toList() : [];

      for (var element in contentList) {
        Video video = Video.fromMap(element);
        list.add(video);
      }
    }
    return list;
  }

  Future<List<Video>> fetchTrendingMovies() async {
    String params = "4gIKGgh0cmFpbGVycw%3D%3D";
    List<Video> list = [];
    var client = http.Client();
    var url = 'https://www.youtube.com/feed/trending?bp=$params&hl=en';
    // YouTube might not support page parameter directly; adjust as necessary
    // var url = 'https://www.youtube.com/feed/trending?bp=$params&hl=en&page=$page';

    try {
      var response = await client.get(Uri.parse(url));
      var raw = response.body;
      var root = parser.parse(raw);
      final scriptText = root
          .querySelectorAll('script')
          .map((e) => e.text)
          .toList(growable: false);
      var initialData = scriptText
          .firstWhereOrNull((e) => e.contains('var ytInitialData = '));
      initialData ??= scriptText
          .firstWhereOrNull((e) => e.contains('window["ytInitialData"] ='));
      var jsonMap = extractJson(initialData!);

      if (jsonMap != null) {
        var contents = jsonMap
            .get('contents')
            ?.get('twoColumnBrowseResultsRenderer')
            ?.getList('tabs')
            ?.elementAtSafe(3)
            ?.get('tabRenderer')
            ?.get('content')
            ?.get('sectionListRenderer')
            ?.getList('contents')
            ?.firstOrNull
            ?.get('itemSectionRenderer')
            ?.getList('contents')
            ?.firstOrNull
            ?.get('shelfRenderer')
            ?.get('content')
            ?.get('expandedShelfContentsRenderer')
            ?.getList('items');
        var contentList = contents != null ? contents.toList() : [];
        for (var element in contentList) {
          Video video = Video.fromMap(element);
          list.add(video);
        }
      }
    } catch (e) {
      // Handle any errors that occur during fetch
    }

    return list;
  }

  ///Get list of suggestions search queries
  Future<List<String>> fetchSuggestions(String query) async {
    List<String> suggestions = [];
    String baseUrl =
        'http://suggestqueries.google.com/complete/search?output=toolbar&ds=yt&q=&hl=en';
    var client = http.Client();
    final myTranformer = Xml2Json();
    var response = await client.get(Uri.parse(baseUrl + query));
    var body = response.body;
    myTranformer.parse(body);
    var json = myTranformer.toGData();
    List suggestionsData = jsonDecode(json)['toplevel']['CompleteSuggestion'];
    for (var suggestion in suggestionsData) {
      suggestions.add(suggestion['suggestion']['data'].toString());
    }
    return suggestions;
  }

  Future<ChannelData?> fetchChannelData(String channelId) async {
    String apikey = 'AIzaSyB7nt8LmSoTit-zHB7LoRm5Xo125Smo_8Q';
    var client = http.Client();

    var channelDetailsUrl = Uri.parse(
        'https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails,statistics&id=$channelId&key=$apikey');

    var channelResponse = await client.get(channelDetailsUrl);
    if (channelResponse.statusCode != 200) {
      return null;
    }

    var channelData = json.decode(channelResponse.body);
    if (channelData['items'].isEmpty) {
      return null;
    }

    var channelInfo = channelData['items'][0];
    String title = channelInfo['snippet']['title'] ?? "Unknown Channel";
    String avatar = channelInfo['snippet']['thumbnails']['default']['url'] ??
        'https://via.placeholder.com/150';
    String banner = channelInfo['snippet']['thumbnails']['high']['url'] ??
        'https://via.placeholder.com/80';
    String subscribers = channelInfo['statistics']['subscriberCount'] ?? "N/A";
    String? uploadsPlaylistId =
        channelInfo['contentDetails']['relatedPlaylists']?['uploads'];

    if (uploadsPlaylistId == null) {
      return ChannelData(
        channel: ChannelPage(
          channelId: channelId, // Pass the channelId here
          channelName: title,
          subscribers: subscribers,
          avatar: avatar,
          banner: banner,
        ),
        videosList: [], // Return an empty list if no videos
      );
    }

    var videosUrl = Uri.parse(
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$uploadsPlaylistId&maxResults=200&key=$apikey');

    var videosResponse = await client.get(videosUrl);
    if (videosResponse.statusCode != 200) {
      return null;
    }

    var videosData = json.decode(videosResponse.body);

    List<Video> videoList = [];
    if (videosData['items'] != null && videosData['items'].isNotEmpty) {
      videoList = videosData['items'].map<Video>((videoItem) {
        return Video.fromSnippet(videoItem['snippet']);
      }).toList();
    }

    return ChannelData(
      channel: ChannelPage(
        channelId: channelId, // Pass the channelId here
        channelName: title,
        subscribers: subscribers,
        avatar: avatar,
        banner: banner,
      ),
      videosList: videoList,
    );
  }

  ///Get videos from playlist
  Future<List<Video>> fetchPlayListVideos(String id, int loaded) async {
    List<Video> videos = [];
    var url = 'https://www.youtube.com/playlist?list=$id&hl=en&persist_hl=1';
    var client = http.Client();
    var response = await client.get(
      Uri.parse(url),
    );
    var jsonMap = _getJsonMap(response);
    if (jsonMap != null) {
      var contents = jsonMap
          .get('contents')
          ?.get('twoColumnBrowseResultsRenderer')
          ?.getList('tabs')
          ?.firstOrNull
          ?.get('tabRenderer')
          ?.get('content')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('playlistVideoListRenderer')
          ?.getList('contents');
      var contentList = contents!.toList();
      for (var element in contentList) {
        Video video = Video.fromMap(element);
        videos.add(video);
      }
      _playListToken = _getPlayListContinuationToken(jsonMap);
    }
    return videos;
  }

  ///Get video data (videoId, title, viewCount, username, likeCount, unlikeCount, channelThumb,
  /// channelId, subscribeCount ,Related videos)
  Future<VideoData?> fetchVideoData(String videoId) async {
    VideoData? videoData;
    var client = http.Client();
    var response = await client
        .get(Uri.parse('https://www.youtube.com/watch?v=$videoId&hl=en'));

    var raw = response.body;
    print('response body: ${response.body}');
    var root = parser.parse(raw);
    final scriptText = root
        .querySelectorAll('script')
        .map((e) => e.text)
        .toList(growable: false);
    var initialData =
        scriptText.firstWhereOrNull((e) => e.contains('var ytInitialData = '));
    initialData ??= scriptText
        .firstWhereOrNull((e) => e.contains('window["ytInitialData"] ='));
    var jsonMap = extractJson(initialData!);
    if (jsonMap != null) {
      var contents = jsonMap.get('contents')?.get('twoColumnWatchNextResults');
      print('contents: $contents');

      var contentList = contents
          ?.get('secondaryResults')
          ?.get('secondaryResults')
          ?.getList('results')
          ?.toList();
      print('content list:$contentList');

      List<Video> videosList = [];

      contentList?.forEach((element) {
        if (element['compactVideoRenderer']?['title']?['simpleText'] != null) {
          Video video = Video.fromMap(element);
          videosList.add(video);
        }
      });

      videoData = VideoData(
          video: VideoPage.fromMap(contents!, videoId), videosList: videosList);
    }
    print('videodataaa: ${videoData!.video?.thumbnails}');
    return videoData;
  }

  ///Load more videos in youtube channel
  Future<List<Video>> loadMoreInChannel(String apikey) async {
    List<Video> videos = [];
    var client = http.Client();
    var url = 'https://www.youtube.com/youtubei/v1/browse?key=$apikey&hl=en';
    var body = {
      'context': const {
        'client': {
          'hl': 'en',
          'clientName': 'WEB',
          'clientVersion': '2.20200911.04.00'
        }
      },
      'continuation': _channelToken
    };
    var raw = await client.post(Uri.parse(url), body: json.encode(body));
    Map<String, dynamic> jsonMap = json.decode(raw.body);
    var contents = jsonMap
        .getList('onResponseReceivedActions')
        ?.firstOrNull
        ?.get('appendContinuationItemsAction')
        ?.getList('continuationItems');
    if (contents != null) {
      var contentList = contents.toList();
      for (var element in contentList) {
        Video video = Video.fromMap(element);
        videos.add(video);
      }
      _channelToken = _getChannelContinuationToken(jsonMap);
    }
    return videos;
  }

  ///Load more videos in youtube playlist
  Future<List<Video>> loadMoreInPlayList(String apikey) async {
    List<Video> list = [];
    var client = http.Client();
    var url = 'https://www.youtube.com/youtubei/v1/browse?key=$apikey&hl=en';
    var body = {
      'context': const {
        'client': {
          'hl': 'en',
          'clientName': 'WEB',
          'clientVersion': '2.20200911.04.00'
        }
      },
      'continuation': _playListToken
    };
    var raw = await client.post(Uri.parse(url), body: json.encode(body));
    Map<String, dynamic> jsonMap = json.decode(raw.body);
    var contents = jsonMap
        .getList('onResponseReceivedActions')
        ?.firstOrNull
        ?.get('appendContinuationItemsAction')
        ?.getList('continuationItems');
    if (contents != null) {
      var contentList = contents.toList();
      for (var element in contentList) {
        Video video = Video.fromMap(element);
        list.add(video);
      }
      _playListToken = _getChannelContinuationToken(jsonMap);
    }
    return list;
  }

  String? _getChannelContinuationToken(Map<String, dynamic>? root) {
    return root!
        .getList('onResponseReceivedActions')
        ?.firstOrNull
        ?.get('appendContinuationItemsAction')
        ?.getList('continuationItems')
        ?.elementAtSafe(30)
        ?.get('continuationItemRenderer')
        ?.get('continuationEndpoint')
        ?.get('continuationCommand')
        ?.getT<String>('token');
  }

  String? _getPlayListContinuationToken(Map<String, dynamic>? root) {
    return root!
        .get('contents')
        ?.get('twoColumnBrowseResultsRenderer')
        ?.getList('tabs')
        ?.firstOrNull
        ?.get('tabRenderer')
        ?.get('content')
        ?.get('sectionListRenderer')
        ?.getList('contents')
        ?.firstOrNull
        ?.get('itemSectionRenderer')
        ?.getList('contents')
        ?.firstOrNull
        ?.get('playlistVideoListRenderer')
        ?.getList('contents')
        ?.elementAtSafe(100)
        ?.get('continuationItemRenderer')
        ?.get('continuationEndpoint')
        ?.get('continuationCommand')
        ?.getT<String>('token');
  }

  String? _getContinuationToken(Map<String, dynamic>? root) {
    if (root?['contents'] != null) {
      if (root?['contents']?['twoColumnBrowseResultsRenderer'] != null) {
        return root!
            .get('contents')
            ?.get('twoColumnBrowseResultsRenderer')
            ?.getList('tabs')
            ?.elementAtSafe(1)
            ?.get('tabRenderer')
            ?.get('content')
            ?.get('sectionListRenderer')
            ?.getList('contents')
            ?.firstOrNull
            ?.get('itemSectionRenderer')
            ?.getList('contents')
            ?.firstOrNull
            ?.get('gridRenderer')
            ?.getList('items')
            ?.elementAtSafe(30)
            ?.get('continuationItemRenderer')
            ?.get('continuationEndpoint')
            ?.get('continuationCommand')
            ?.getT<String>('token');
      }
      var contents = root!
          .get('contents')
          ?.get('twoColumnSearchResultsRenderer')
          ?.get('primaryContents')
          ?.get('sectionListRenderer')
          ?.getList('contents');

      if (contents == null || contents.length <= 1) {
        return null;
      }
      return contents
          .elementAtSafe(1)
          ?.get('continuationItemRenderer')
          ?.get('continuationEndpoint')
          ?.get('continuationCommand')
          ?.getT<String>('token');
    }
    if (root?['onResponseReceivedCommands'] != null) {
      return root!
          .getList('onResponseReceivedCommands')
          ?.firstOrNull
          ?.get('appendContinuationItemsAction')
          ?.getList('continuationItems')
          ?.elementAtSafe(1)
          ?.get('continuationItemRenderer')
          ?.get('continuationEndpoint')
          ?.get('continuationCommand')
          ?.getT<String>('token');
    }
    return null;
  }

  Map<String, dynamic>? _getJsonMap(http.Response response) {
    var raw = response.body;
    var root = parser.parse(raw);
    final scriptText = root
        .querySelectorAll('script')
        .map((e) => e.text)
        .toList(growable: false);
    var initialData =
        scriptText.firstWhereOrNull((e) => e.contains('var ytInitialData = '));
    initialData ??= scriptText
        .firstWhereOrNull((e) => e.contains('window["ytInitialData"] ='));
    var jsonMap = extractJson(initialData!);
    return jsonMap;
  }
}
