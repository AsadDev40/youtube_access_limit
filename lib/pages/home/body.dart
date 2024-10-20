// ignore_for_file: must_be_immutable, library_private_types_in_public_api, no_logic_in_create_state

import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import 'package:flutter/material.dart';
import '/widgets/video_widget.dart';

class Body extends StatefulWidget {
  List<Video> contentList;

  Body({super.key, required this.contentList});

  @override
  _BodyState createState() => _BodyState(contentList);
}

class _BodyState extends State<Body> {
  List<Video> contentList;

  _BodyState(this.contentList);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          return video(contentList[index]);
        },
      ),
    );
  }

  Widget video(Video video) {
    // Extract the list of video IDs
    List<String> videoIds = contentList
        .map((video) => video.videoId)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    return VideoWidget(
      video: video,
      videolist: videoIds,
    );
  }
}
