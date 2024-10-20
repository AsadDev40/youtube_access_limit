import 'package:kidsafe_youtube/scrap_api/models/thumbnail.dart';

class Video {
  // Existing properties
  String? videoId;
  String? duration;
  String? title;
  String? channelName;
  String? views;
  String? uploadDate;
  List<Thumbnail>? thumbnails;
  String? description;
  String? thumbnailUrl;
  DateTime? publishedAt;

  Video({
    this.videoId,
    this.duration,
    this.title,
    this.channelName,
    this.views,
    this.uploadDate,
    this.thumbnails,
    this.description,
    this.thumbnailUrl,
    this.publishedAt,
  });

  factory Video.fromMap(Map<String, dynamic>? map) {
    // Existing implementation
    List<Thumbnail>? thumbnails;
    if (map?.containsKey("richItemRenderer") ?? false) {
      var uploadDate = map?['richItemRenderer']['content']['videoRenderer']
          ?['publishedTimeText'];
      var lengthText =
          map?['richItemRenderer']['content']['videoRenderer']?['lengthText'];
      thumbnails = [];
      map?['richItemRenderer']['content']['videoRenderer']['thumbnail']
              ['thumbnails']
          .forEach((thumbnail) {
        thumbnails!.add(Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']));
      });
      var viewtext = map?['richItemRenderer']?['content']?['videoRenderer']
          ?['shortViewCountText']?['runs'];
      String? uploadDates;
      String? viewers;
      if (uploadDate != null) {
        uploadDates = uploadDate['simpleText'];
      } else {
        uploadDates = '';
      }
      if (viewtext != null) {
        viewers = viewtext[0]['text'] + viewtext[1]['text'];
      } else {
        viewers = map?['richItemRenderer']?['content']?['videoRenderer']
            ?['shortViewCountText']?['simpleText'];
      }
      return Video(
          videoId: map?['richItemRenderer']['content']['videoRenderer']
              ?['videoId'],
          duration: lengthText?['simpleText'],
          title: map?['richItemRenderer']['content']['videoRenderer']?['title']
              ?['runs']?[0]?['text'],
          channelName: '',
          thumbnails: thumbnails,
          views: viewers,
          uploadDate: uploadDates);
    } else if (map?.containsKey("videoRenderer") ?? false) {
      var uploadDate = map?['videoRenderer']?['publishedTimeText'];
      var lengthText = map?['videoRenderer']?['lengthText'];
      var simpleText =
          map?['videoRenderer']?['shortViewCountText']?['simpleText'];
      thumbnails = [];
      map?['videoRenderer']['thumbnail']['thumbnails'].forEach((thumbnail) {
        thumbnails!.add(Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']));
      });
      String? uploadDates;
      if (uploadDate != null) {
        uploadDates = uploadDate?['simpleText'];
      } else {
        uploadDates = '';
      }
      return Video(
          videoId: map?['videoRenderer']?['videoId'],
          duration: (lengthText == null) ? 'LIVE' : lengthText?['simpleText'],
          title: map?['videoRenderer']?['title']?['runs']?[0]?['text'],
          channelName: map?['videoRenderer']['longBylineText']['runs'][0]
              ['text'],
          thumbnails: thumbnails,
          views: (lengthText == null)
              ? "Views ${map!['videoRenderer']['viewCountText']['runs'][0]['text']}"
              : simpleText,
          uploadDate: uploadDates);
    } else if (map?.containsKey("compactVideoRenderer") ?? false) {
      var uploadDate = map?['compactVideoRenderer']?['publishedTimeText'];
      thumbnails = [];
      map?['compactVideoRenderer']['thumbnail']['thumbnails']
          .forEach((thumbnail) {
        thumbnails!.add(Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']));
      });
      var lengthText = map?['compactVideoRenderer']?['lengthText'];
      var viewtext =
          map?['compactVideoRenderer']?['shortViewCountText']?['runs'];
      String? viewers;
      String? uploadDates;
      if (uploadDate != null) {
        uploadDates = uploadDate?['simpleText'];
      } else {
        uploadDates = '';
      }
      if (viewtext != null) {
        viewers = viewtext?[0]['text'] + viewtext?[1]['text'];
      } else {
        viewers =
            map?['compactVideoRenderer']?['shortViewCountText']?['simpleText'];
      }
      return Video(
          videoId: map?['compactVideoRenderer']['videoId'],
          title: map?['compactVideoRenderer']?['title']?['simpleText'],
          duration: (lengthText == null) ? 'LIVE' : lengthText?['simpleText'],
          thumbnails: thumbnails,
          channelName: map?['compactVideoRenderer']?['shortBylineText']?['runs']
              ?[0]?['text'],
          views: viewers,
          uploadDate: uploadDates);
    } else if (map?.containsKey("gridVideoRenderer") ?? false) {
      String? simpleText =
          map?['gridVideoRenderer']['shortViewCountText']?['simpleText'];
      thumbnails = [];
      map?['gridVideoRenderer']['thumbnail']['thumbnails'].forEach((thumbnail) {
        thumbnails!.add(Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']));
      });
      return Video(
          videoId: map?['gridVideoRenderer']['videoId'],
          title: map?['gridVideoRenderer']['title']['runs'][0]['text'],
          duration: map?['gridVideoRenderer']['thumbnailOverlays'][0]
              ['thumbnailOverlayTimeStatusRenderer']['text']['simpleText'],
          thumbnails: thumbnails,
          views: (simpleText != null) ? simpleText : "???");
    } else if (map?.containsKey("playlistVideoRenderer") ?? false) {
      var uploadDate = map?['playlistVideoRenderer']?['publishedTimeText'];
      thumbnails = [];
      map?['playlistVideoRenderer']['thumbnail']['thumbnails']
          .forEach((thumbnail) {
        thumbnails!.add(Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']));
      });
      String? uploadDates;
      if (uploadDate != null) {
        uploadDates = uploadDate;
      } else {
        uploadDates = '';
      }
      return Video(
          videoId: map?['playlistVideoRenderer']['videoId'],
          title: map?['playlistVideoRenderer']['title']['runs'][0]['text'],
          duration: map?['playlistVideoRenderer']['thumbnailOverlays'][0]
              ['thumbnailOverlayTimeStatusRenderer']['text']['simpleText'],
          thumbnails: thumbnails,
          views: map?['playlistVideoRenderer']['title']['accessibility']
              ['accessibilityData']['label'],
          uploadDate: uploadDates);
    }
    return Video();
  }

  factory Video.fromSnippet(Map<String, dynamic> snippet) {
    return Video(
      videoId: snippet['resourceId']['videoId'] ?? '',
      title: snippet['title'] ?? 'Untitled',
      description: snippet['description'] ?? '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? '',
      views: snippet['views'] ?? '',
      publishedAt:
          DateTime.parse(snippet['publishedAt'] ?? '1970-01-01T00:00:00Z'),
    );
  }

  factory Video.fromSnippet2(Map<String, dynamic> snippet) {
    return Video(
      videoId: snippet['id'] ?? '',
      title: snippet['snippet']['title'] ?? 'Untitled',
      description: snippet['snippet']['description'] ?? '',
      thumbnailUrl: snippet['snippet']['thumbnails']['high']['url'] ?? '',
      views: snippet['Views'] ?? '',
      channelName: snippet['snippet']['channelTitle'] ?? 'Unknown Channel',
      publishedAt: DateTime.parse(
          snippet['snippet']['publishedAt'] ?? '1970-01-01T00:00:00Z'),
    );
  }

  Map<String, dynamic> toSnippet2() {
    return {
      'id': videoId ?? '',
      'snippet': {
        'title': title ?? 'Untitled',
        'description': description ?? '',
        'thumbnails': {
          'high': {'url': thumbnailUrl ?? ''}
        },
        'channelTitle': channelName ?? 'Unknown Channel',
        'publishedAt': publishedAt?.toIso8601String() ?? '1970-01-01T00:00:00Z',
      },
      'views': views ?? '',
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'duration': duration,
      'title': title,
      'channelName': channelName,
      'views': views,
      'uploadDate': uploadDate,
      'thumbnails': thumbnails?.map((t) => t.toMap()).toList(),
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  factory Video.fromShorts(Map<String, dynamic> snippet) {
    return Video(
      videoId: snippet['id']['videoId'] ?? '',
      title: snippet['snippet']['title'] ?? 'Untitled',
      description: snippet['snippet']['description'] ?? '',
      thumbnailUrl: snippet['snippet']['thumbnails']['high']['url'] ?? '',
      views: snippet[
          'views'], // Assuming views are not available in the short snippet
      channelName: snippet['snippet']['channelTitle'] ?? 'Unknown Channel',
      publishedAt: DateTime.parse(
          snippet['snippet']['publishedAt'] ?? '1970-01-01T00:00:00Z'),
    );
  }
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channelName: json['channelName'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
