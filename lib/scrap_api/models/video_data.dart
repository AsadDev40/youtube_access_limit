import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import 'package:kidsafe_youtube/scrap_api/models/video_page.dart';

class VideoData {
  VideoPage? video;
  List<Video> videosList;

  VideoData({this.video, required this.videosList});
}
