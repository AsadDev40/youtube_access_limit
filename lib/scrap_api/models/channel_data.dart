import 'package:kidsafe_youtube/scrap_api/models/channel_page.dart';
import 'package:kidsafe_youtube/scrap_api/models/video.dart';

class ChannelData {
  final ChannelPage channel;
  final List<Video> videosList;

  ChannelData({required this.channel, required this.videosList});

  factory ChannelData.fromMap(Map<String, dynamic> map) {
    // Extracting channel details
    String id = map['id'] ?? '';
    String title = map['channelName'] ?? "Unknown Channel";
    String avatar = map['avatar'] ?? 'https://via.placeholder.com/150';
    String banner = map['banner'] ?? 'https://via.placeholder.com/80';
    String subscribers = map['subscribers'] ?? "N/A";

    // Extracting video contents
    List<Video> videoList =
        (map['videos'] as List<dynamic>? ?? []).map<Video>((videoItem) {
      return Video.fromMap(videoItem);
    }).toList();

    return ChannelData(
      channel: ChannelPage(
        channelName: title,
        subscribers: subscribers,
        avatar: avatar,
        banner: banner,
        channelId: id,
      ),
      videosList: videoList,
    );
  }
}
