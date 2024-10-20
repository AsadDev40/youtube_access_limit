import 'package:kidsafe_youtube/scrap_api/models/thumbnail.dart';
import 'package:kidsafe_youtube/scrap_api/models/video.dart';

class VideoPage {
  String? videoId;
  String? title;
  String? date;
  String? description;
  String? channelName;
  String? viewCount;
  String? likeCount;
  String? unlikeCount;
  String? channelThumb;
  String? channelId;
  String? subscribeCount;

  // List of thumbnails for the video
  List<Thumbnail>? thumbnails;

  // List of thumbnails for the channel
  List<Thumbnail>? channelThumbnails;

  VideoPage({
    this.videoId,
    this.title,
    this.channelName,
    this.viewCount,
    this.subscribeCount,
    this.likeCount,
    this.unlikeCount,
    this.date,
    this.description,
    this.channelThumb,
    this.channelId,
    this.thumbnails, // Updated property
    this.channelThumbnails, // New property
  });

  Video toVideo() {
    return Video(
      videoId: videoId,
      duration: date,
      title: title,
      channelName: channelName,
      thumbnails: thumbnails ?? channelThumbnails,
      views: viewCount,
    );
  }

  factory VideoPage.fromMap(Map<String, dynamic>? map, String videoId) {
    if (map == null || map.isEmpty) {
      return VideoPage(videoId: videoId);
    }

    // Safe access with null checks
    var videoPrimaryInfoRenderer = map['results']?['results']?['contents']?[0]
        ?['videoPrimaryInfoRenderer'];
    var videoSecondaryInfoRenderer = map['results']?['results']?['contents']?[1]
        ?['videoSecondaryInfoRenderer'];

    var likes = videoPrimaryInfoRenderer?['videoActions']?['menuRenderer']
        ?['topLevelButtons']?[0];
    var views = videoPrimaryInfoRenderer?['viewCount']
        ?['videoViewCountRenderer']?['viewCount']?['runs'];
    var oldViews = videoPrimaryInfoRenderer?['viewCount']
        ?['videoViewCountRenderer']?['shortViewCount'];

    String? viewers;
    String? likers;

    if (likes == []) {
      likers = '0';
    } else {
      likers = likes?['segmentedLikeDislikeButtonViewModel']
                  ?['likeButtonViewModel']?['likeButtonViewModel']
              ?['toggleButtonViewModel']?['toggleButtonViewModel']
          ?['defaultButtonViewModel']?['buttonViewModel']?['title'];
    }

    if (views != null) {
      viewers = views?[0]['text'] + views?[1]['text'];
    } else if (oldViews != null) {
      viewers = oldViews?['simpleText'];
    } else {
      viewers = videoPrimaryInfoRenderer?['viewCount']
          ?['videoViewCountRenderer']?['viewCount']?['simpleText'];
    }

    // Safely extract video thumbnails
    List<Thumbnail>? thumbnails;
    var thumbnailData = videoPrimaryInfoRenderer?['thumbnails'] as List?;
    if (thumbnailData != null) {
      thumbnails = thumbnailData.map((thumbnail) {
        return Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']);
      }).toList();
    }

    // Safely extract channel thumbnails
    List<Thumbnail>? channelThumbnails;
    var channelThumbnailData = videoSecondaryInfoRenderer?['owner']
        ?['videoOwnerRenderer']?['thumbnail']?['thumbnails'] as List?;
    if (channelThumbnailData != null) {
      channelThumbnails = channelThumbnailData.map((thumbnail) {
        return Thumbnail(
            url: thumbnail['url'],
            width: thumbnail['width'],
            height: thumbnail['height']);
      }).toList();
    }

    return VideoPage(
      videoId: videoId,
      title: videoPrimaryInfoRenderer?['title']?['runs']?[0]?['text'],
      channelName: videoSecondaryInfoRenderer?['owner']?['videoOwnerRenderer']
          ?['title']?['runs']?[0]?['text'],
      viewCount: viewers,
      subscribeCount: videoSecondaryInfoRenderer?['owner']
          ?['videoOwnerRenderer']?['subscriberCountText']?['simpleText'],
      likeCount: likers,
      unlikeCount: '',
      description: videoSecondaryInfoRenderer?['attributedDescription']
          ?['content'],
      date: videoPrimaryInfoRenderer?['dateText']?['simpleText'],
      channelThumb: videoSecondaryInfoRenderer?['owner']?['videoOwnerRenderer']
          ?['thumbnail']?['thumbnails']?[1]?['url'],
      channelId: videoSecondaryInfoRenderer?['owner']?['videoOwnerRenderer']
          ?['navigationEndpoint']?['browseEndpoint']?['browseId'],
      thumbnails: thumbnails, // Updated property
      channelThumbnails: channelThumbnails, // New property
    );
  }
}
