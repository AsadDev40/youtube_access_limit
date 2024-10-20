class Channel {
  /// Youtube channel id
  String? channelId;

  /// Youtube channel title
  String? title;

  /// Youtube channel thumbnail
  String? thumbnail;

  /// Youtube channel number of videos
  String? videoCount;

  /// Youtube channel number of subscribers
  String? subscriberCount;

  Channel({
    this.channelId,
    this.title,
    this.thumbnail,
    this.videoCount,
    this.subscriberCount,
  });

  factory Channel.fromMap(Map<String, dynamic>? map) {
    return Channel(
      channelId: map?['channelRenderer']['channelId'],
      thumbnail: map?['channelRenderer']['thumbnail']['thumbnails'][0]['url'],
      title: map?['channelRenderer']['title']['simpleText'],
      videoCount: map?['channelRenderer']['videoCountText']['runs'][0]['text'],
      subscriberCount: map?['channelRenderer']['subscriberCountText']
          ['simpleText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "channelId": channelId,
      "title": title,
      "thumbnail": thumbnail,
      "videoCount": videoCount,
      "subscriberCount": subscriberCount,
    };
  }
}
