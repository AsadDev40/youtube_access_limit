import 'package:kidsafe_youtube/scrap_api/models/channle.dart';

class ChannelPage {
  final String channelId; // Add this field
  final String channelName;
  final String subscribers;
  final String avatar;
  final String banner;
  final String? videoCount;

  ChannelPage({
    required this.channelId, // Initialize this field
    required this.channelName,
    required this.subscribers,
    required this.avatar,
    required this.banner,
    this.videoCount,
  });
  Channel tochannel() {
    return Channel(
        channelId: channelId,
        title: channelName,
        thumbnail: avatar,
        subscriberCount: subscribers,
        videoCount: videoCount);
  }

  factory ChannelPage.fromMap(Map<String, dynamic> map) {
    return ChannelPage(
      channelId: map['id'], // Ensure this field is retrieved correctly
      channelName: map['snippet']['title'] ?? "Unknown Channel",
      subscribers: map['statistics']['subscriberCount'] ?? "N/A",
      avatar: map['snippet']['thumbnails']['default']['url'] ??
          'https://via.placeholder.com/150',
      banner: map['snippet']['thumbnails']['high']['url'] ??
          'https://via.placeholder.com/80',
      videoCount: map['statistics']['videoCount'] ?? "N/A",
    );
  }
}
