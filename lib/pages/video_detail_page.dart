// ignore_for_file: must_be_immutable, library_private_types_in_public_api, unused_field, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:kidsafe_youtube/Utils/child_channel_popup.dart';
import 'package:kidsafe_youtube/Utils/child_video_popup.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/models/child_model.dart';
import 'package:kidsafe_youtube/models/subscribed.dart';
import 'package:kidsafe_youtube/providers/auth_provider.dart' as authen;
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/providers/subscription_provider.dart';
import 'package:kidsafe_youtube/scrap_api/models/video_data.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:kidsafe_youtube/widgets/custom_video_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pod_player/pod_player.dart';
import 'package:provider/provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:social_share/social_share.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../helpers/shared_helper.dart';
import '/theme/colors.dart';
import 'channel/channel_page.dart';

class VideoDetailPage extends StatefulWidget {
  String videoId;
  List<String>? videolist;

  VideoDetailPage({super.key, required this.videoId, this.videolist});

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  //Subscribed? subscribed;
  bool isSwitched = true;
  bool isparent = false;
  late PodPlayerController _controller;
  authen.AuthProvider authProvider = authen.AuthProvider();

  // for video player
  late int _playBackTime;

  //The values that are passed when changing quality
  late Duration newCurrentPosition;

  YoutubeDataApi youtubeDataApi = YoutubeDataApi();
  VideoData? videoData;
  double? progressPadding;
  final unknown = "Unknown";

  SharedHelper sharedHelper = SharedHelper();
  late Future<bool> checkFuture;
  ChildModel? childModel;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _fetchParentValue();
    // Initialize the PodPlayerController with the initial video ID
    _controller = PodPlayerController(
      playVideoFrom:
          PlayVideoFrom.youtube('https://youtu.be/${widget.videoId}'),
    )..initialise();

    // Add a listener to the controller to check if the video has ended
    _controller.addListener(_onVideoEnd);
  }

  Future<void> _fetchParentValue() async {
    bool? value = await isShowbutton();
    if (value != null) {
      setState(() {
        isparent = value; // Store the fetched value in isparent
      });
    }
  }

  void _onVideoEnd() {
    if (_controller.isInitialised) {
      Duration currentPosition = _controller.currentVideoPosition;
      Duration totalDuration = _controller.totalVideoLength;

      // Check if the video has ended
      if (currentPosition >= totalDuration - const Duration(seconds: 1)) {
        _controller
            .removeListener(_onVideoEnd); // Temporarily remove the listener
        playNextVideo();
      }
    }
  }

  Future<void> playNextVideo() async {
    String nextVideoId = await getNextVideoId();

    if (nextVideoId.isNotEmpty && isSwitched) {
      setState(() {
        widget.videoId = nextVideoId;
        _controller
            .changeVideo(
          playVideoFrom: PlayVideoFrom.youtube('https://youtu.be/$nextVideoId'),
        )
            .then((_) {
          _controller.addListener(
              _onVideoEnd); // Re-add the listener after the video has been changed
          _controller.play(); // Autoplay the next video
        });
      });
    } else {
      _controller.removeListener(_onVideoEnd);
    }
  }

  Future<String> getNextVideoId() async {
    List<String> videoIds = widget.videolist ?? [];

    // Find the current video's index
    int currentIndex = videoIds.indexOf(widget.videoId);

    // If the current video is not the last one, return the next video ID
    if (currentIndex != -1 && currentIndex < videoIds.length - 1) {
      return videoIds[currentIndex + 1];
    }

    // Return an empty string if there are no more videos
    return '';
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd); // Clean up the listener
    _controller.dispose();
    super.dispose();
  }

  Future<bool?> isShowbutton() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isshowButton = prefs.getBool('parent');

    return isshowButton;
  }

  @override
  Widget build(BuildContext context) {
    progressPadding = MediaQuery.of(context).size.height * 0.3;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: getBody(),
    );
  }

  Widget getBody() {
    String channelId = videoData?.video?.channelId ?? "";
    bool isSubscribed =
        Provider.of<SubscriptionProvider>(context).isSubscribed(channelId);

    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: Column(
        children: <Widget>[
          PodVideoPlayer(controller: _controller),
          FutureBuilder(
            future: youtubeDataApi.fetchVideoData(widget.videoId),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Padding(
                    padding: EdgeInsets.only(top: progressPadding!),
                    child: const CircularProgressIndicator(),
                  );
                case ConnectionState.active:
                  return Padding(
                    padding: EdgeInsets.only(top: progressPadding!),
                    child: const CircularProgressIndicator(),
                  );
                case ConnectionState.none:
                  return const Text("Connection None");
                case ConnectionState.done:
                  if (snapshot.error != null) {
                    return Center(child: Text(snapshot.stackTrace.toString()));
                  } else {
                    if (snapshot.hasData) {
                      videoData = snapshot.data;
                      return Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, top: 10),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      SizedBox(
                                        width: size.width - 80,
                                        child: Text(
                                          videoData?.video?.title ?? "",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Cairo',
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground
                                                  .withOpacity(0.8),
                                              fontWeight: FontWeight.w500,
                                              height: 1.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: GestureDetector(
                                          onTap: () {
                                            _controller.pause();
                                            Navigator.pop(context);
                                          },
                                          child: Icon(
                                            LineIcons.angleDown,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.7),
                                            size: 18,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        videoData?.video?.date ?? "",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.4),
                                            fontSize: 13,
                                            fontFamily: 'Cairo'),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        videoData?.video?.viewCount ?? "",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.4),
                                            fontSize: 13,
                                            fontFamily: 'Cairo'),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        const Column(
                                          children: <Widget>[
                                            // Icon(
                                            //   LineIcons.thumbsUp,
                                            //   color: white.withOpacity(0.5),
                                            //   size: 26,
                                            // ),
                                            // const SizedBox(
                                            //   height: 2,
                                            // ),
                                            // Text(
                                            //   videoData?.video?.likeCount ?? "",
                                            //   style: TextStyle(
                                            //       color: white.withOpacity(0.4),
                                            //       fontSize: 13,
                                            //       fontFamily: 'Cairo'),
                                            // )
                                          ],
                                        ),
                                        // Column(
                                        //   children: <Widget>[
                                        //     Icon(
                                        //       LineIcons.thumbsDown,
                                        //       color: white.withOpacity(0.5),
                                        //       size: 26,
                                        //     ),
                                        //     const SizedBox(
                                        //       height: 2,
                                        //     ),
                                        //     Text(
                                        //       'Dislike',
                                        //       style: TextStyle(
                                        //           color: white.withOpacity(0.4),
                                        //           fontSize: 13,
                                        //           fontFamily: 'Cairo'),
                                        //     )
                                        //   ],
                                        // ),
                                        if (isparent)
                                          InkWell(
                                            onTap: (() async {
                                              final videoId =
                                                  videoData!.video!.videoId;
                                              final videoUrl =
                                                  'https://www.youtube.com/watch?v=$videoId';
                                              Share.share(videoUrl);
                                            }),
                                            child: Column(
                                              children: <Widget>[
                                                Icon(
                                                  LineIcons.share,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onBackground
                                                      .withOpacity(0.5),
                                                  size: 26,
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),

                                                Text(
                                                  "Share",
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground
                                                          .withOpacity(0.4),
                                                      fontSize: 13,
                                                      fontFamily: 'Cairo'),
                                                ),
                                                // )
                                              ],
                                            ),
                                          ),
                                        InkWell(
                                          onTap: () async {
                                            await downloadVideo(widget.videoId);
                                          },
                                          child: Column(
                                            children: <Widget>[
                                              Icon(
                                                LineIcons.download,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onBackground
                                                    .withOpacity(0.5),
                                                size: 26,
                                              ),
                                              const SizedBox(
                                                height: 2,
                                              ),
                                              Text(
                                                "Download",
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onBackground
                                                        .withOpacity(0.4),
                                                    fontSize: 13,
                                                    fontFamily: 'Cairo'),
                                              )
                                            ],
                                          ),
                                        ),
                                        // Column(
                                        //   children: <Widget>[
                                        //     Icon(
                                        //       LineIcons.plus,
                                        //       color: white.withOpacity(0.5),
                                        //       size: 26,
                                        //     ),
                                        //     const SizedBox(
                                        //       height: 2,
                                        //     ),
                                        //     Text(
                                        //       "Save",
                                        //       style: TextStyle(
                                        //           color: white.withOpacity(0.4),
                                        //           fontSize: 13,
                                        //           fontFamily: 'Cairo'),
                                        //     )
                                        //   ],
                                        // )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  FutureBuilder<bool?>(
                                    future: isShowbutton(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return const Text('Error');
                                      } else if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                        pink),
                                                foregroundColor:
                                                    MaterialStateProperty.all(
                                                        Colors.black),
                                                textStyle:
                                                    MaterialStateProperty.all(
                                                  const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                              onPressed: () {
                                                Utils.navigateTo(
                                                  context,
                                                  AllowVideoPopup(
                                                      videodata: videoData!),
                                                );
                                              },
                                              child: const Text(
                                                'Allow Video for child',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                        pink),
                                                foregroundColor:
                                                    MaterialStateProperty.all(
                                                        Colors.black),
                                                textStyle:
                                                    MaterialStateProperty.all(
                                                  const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                              onPressed: () {
                                                Utils.navigateTo(
                                                  context,
                                                  AllowChannelPopup(
                                                    channel: videoData!,
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Add Channel for child',
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Container();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: white.withOpacity(0.1),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 17),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      _controller.pause();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Channelpage(
                                                id: videoData!.video!.channelId,
                                                title: videoData!
                                                    .video!.channelName)),
                                      );
                                    },
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                  image: NetworkImage(videoData!
                                                      .video!.channelThumb!),
                                                  fit: BoxFit.cover)),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        SizedBox(
                                          width: (MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              180),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                videoData?.video?.channelName ??
                                                    "",
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onBackground,
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.3),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: <Widget>[
                                                  Text(
                                                    videoData?.video
                                                            ?.subscribeCount ??
                                                        '',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  if (isparent)
                                    GestureDetector(
                                      onTap: () {
                                        if (isSubscribed) {
                                          unSubscribe();
                                        } else {
                                          subscribe();
                                        }
                                      },
                                      child: Text(
                                        isSubscribed
                                            ? 'UNSUBSCRIBE'
                                            : "SUBSCRIBE",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  // FutureBuilder<bool>(
                                  //     future: checkFuture,
                                  //     builder: (context, snapshot) {
                                  //       if (snapshot.hasData) {
                                  //         isSubscribed = snapshot.data!;
                                  //         return GestureDetector(
                                  //           onTap: () {
                                  //             if (isSubscribed) {
                                  //               unSubscribe();
                                  //             } else {
                                  //               subscribe();
                                  //             }
                                  //           },
                                  //           child: Text(
                                  //             isSubscribed
                                  //                 ? 'UNSUBCRIBE'
                                  //                 : "SUBSCRIBE",
                                  //             style: TextStyle(
                                  //                 color: red,
                                  //                 fontWeight: FontWeight.bold,
                                  //                 fontFamily: 'Cairo'),
                                  //           ),
                                  //         );
                                  //       } else {
                                  //         return const SizedBox();
                                  //       }
                                  //     }),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Divider(
                              color: white.withOpacity(0.1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 0, left: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    "Up next",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.4),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Cairo'),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        "Autoplay",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.4),
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Cairo'),
                                      ),
                                      Switch(
                                          activeColor: pink,
                                          value: isSwitched,
                                          onChanged: (value) {
                                            setState(() {
                                              isSwitched = value;
                                            });
                                          })
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            FutureBuilder<bool?>(
                              future: isShowbutton(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return const Center(child: Text('Error'));
                                } else if (snapshot.hasData &&
                                    snapshot.data == true) {
                                  // Show videos for parent
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 20),
                                    child: SingleChildScrollView(
                                      physics: const ScrollPhysics(),
                                      child: Column(
                                        children: [
                                          ListView.builder(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount:
                                                videoData?.videosList.length ??
                                                    0,
                                            itemBuilder: (context, index) {
                                              return GestureDetector(
                                                onTap: () {
                                                  String videoId = videoData!
                                                      .videosList[index]
                                                      .videoId!;
                                                  _changeVideo(videoId);
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 20),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Container(
                                                        width: (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width -
                                                                50) /
                                                            2,
                                                        height: 100,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          image:
                                                              DecorationImage(
                                                            image: Image.network(videoData!
                                                                    .videosList[
                                                                        index]
                                                                    .thumbnails![
                                                                        1]
                                                                    .url!)
                                                                .image,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        child: Stack(
                                                          children: <Widget>[
                                                            Positioned(
                                                              bottom: 10,
                                                              right: 12,
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onBackground
                                                                      .withOpacity(
                                                                          0.8),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              3),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3.0),
                                                                  child: Text(
                                                                    videoData!
                                                                            .videosList[index]
                                                                            .duration ??
                                                                        "00:00",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.4),
                                                                      fontFamily:
                                                                          'Cairo',
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 20),
                                                      Expanded(
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: <Widget>[
                                                            SizedBox(
                                                              width: (MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width -
                                                                      130) /
                                                                  2,
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: <Widget>[
                                                                  Text(
                                                                    videoData!
                                                                            .videosList[index]
                                                                            .title ??
                                                                        'Unknown',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onBackground
                                                                          .withOpacity(
                                                                              0.9),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      height:
                                                                          1.3,
                                                                      fontSize:
                                                                          14,
                                                                      fontFamily:
                                                                          'Cairo',
                                                                    ),
                                                                    maxLines: 3,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  Text(
                                                                    videoData!
                                                                            .videosList[index]
                                                                            .channelName ??
                                                                        'Unknown',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onBackground
                                                                          .withOpacity(
                                                                              0.4),
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontFamily:
                                                                          'Cairo',
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  Row(
                                                                    children: <Widget>[
                                                                      Text(
                                                                        videoData!.videosList[index].views ??
                                                                            'Unknown',
                                                                        style:
                                                                            TextStyle(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .onBackground
                                                                              .withOpacity(0.4),
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          fontFamily:
                                                                              'Cairo',
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Icon(
                                                              LineIcons
                                                                  .horizontalEllipsis,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.4),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  final childProvider =
                                      Provider.of<ChildProvider>(context);
                                  List<String> filteredVideoIds = childProvider
                                          .currentChild?.videos
                                          .where((id) => id != widget.videoId)
                                          .toList() ??
                                      [];

                                  return SizedBox(
                                    height: 300,
                                    child: ListView.builder(
                                      itemCount: filteredVideoIds.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final videoId = filteredVideoIds[index];

                                        return FutureBuilder<VideoData?>(
                                          future: YoutubeDataApi()
                                              .fetchVideoData(videoId),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child: Text('loading...'));
                                            }
                                            if (!snapshot.hasData ||
                                                snapshot.data == null) {
                                              return const Text(
                                                  'No data found');
                                            }

                                            final videoPage =
                                                snapshot.data!.video;
                                            if (videoPage == null) {
                                              return const Text(
                                                  'No video data found');
                                            }

                                            return CustomVideoWidget(
                                              title:
                                                  videoPage.title ?? 'No title',
                                              channelName:
                                                  videoPage.channelName ??
                                                      'No channel',
                                              thumbnails: [
                                                videoPage.channelThumb ?? ''
                                              ],
                                              duration:
                                                  videoPage.date ?? '0:00',
                                              views: videoPage.viewCount ??
                                                  '0 views',
                                              videoId: videoPage.videoId!,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ));
                    } else {
                      return const Center(child: Text("No data"));
                    }
                  }
              }
            },
          )
        ],
      ),
    );
  }

  void _changeVideo(String videoId) {
    _controller.changeVideo(
        playVideoFrom: PlayVideoFrom.youtube("https://youtu.be/$videoId"));
    setState(() {
      widget.videoId = videoId;
    });
  }

  void subscribe() async {
    if (videoData != null && videoData!.video != null) {
      final data = videoData!.video!;
      final subscribed = Subscribed(
          username: data.channelName,
          channelId: data.channelId,
          avatar: data.channelThumb,
          videosCount: "");
      sharedHelper.subscribeChannel(
          videoData!.video!.channelId!, jsonEncode(subscribed.toJson()));
      Provider.of<SubscriptionProvider>(context, listen: false)
          .subscribe(data.channelId!);
    }
  }

  void unSubscribe() async {
    if (videoData != null && videoData!.video != null) {
      sharedHelper.unSubscribeChannel(videoData!.video!.channelId!);
      Provider.of<SubscriptionProvider>(context, listen: false)
          .unSubscribe(videoData!.video!.channelId!);
    }
  }

//download video
  Future<void> downloadVideo(String videoId) async {
    await requestNotificationPermissions();
    await requeststoragepermission();
    var yt = YoutubeExplode();
    final directory = await getExternalStorageDirectory();
    var manifest = await yt.videos.streamsClient.getManifest(videoId);
    var streamInfo = manifest.muxed.withHighestBitrate();
    final String filename = videoData!.video!.title.toString();

    // Ensure the notification channel is created
    await createNotificationChannel();

    // Create a notification with an ongoing progress indicator
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('download_channel', 'Download Channel',
            channelDescription: 'Download in progress',
            importance: Importance.max,
            priority: Priority.high,
            progress: 100,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    var stream = yt.videos.streamsClient.get(streamInfo);
    var file = File('${directory!.path}/downloads/$filename.mp4');

    final String picturesPath =
        directory.path; // Ensure you have a fallback in case the path is null

    // Construct the full path to the file within the Pictures directory
    final String filePath = '$picturesPath/downloads/$filename.mp4';

    await file.create(recursive: true);

    // Calculate the total bytes to download
    final totalBytes = streamInfo.size.totalBytes;
    int downloadedBytes = 0;
    bool isDownloadComplete = false; // Flag to track download completion

    // Create a StreamController to allow multiple listeners
    final StreamController<List<int>> streamController = StreamController();
    stream.listen((data) {
      downloadedBytes += data.length;
      final progress = (downloadedBytes / totalBytes) * 100;

      // Update the notification with the new progress
      flutterLocalNotificationsPlugin.show(
        0,
        'Downloading $filename',
        'Download in progress: ${progress.toStringAsFixed(0)}%',
        platformChannelSpecifics,
        payload: videoId,
      );

      // Check if download is complete
      if (progress >= 100 && downloadedBytes == totalBytes) {
        // Ensure totalBytes match
        isDownloadComplete = true;
      }

      // Add the data to the StreamController
      streamController.add(data);
    }).onDone(() {
      streamController.close();

      // Show completion notification if download is complete
      if (isDownloadComplete) {
        flutterLocalNotificationsPlugin.show(0, 'Download Complete',
            'Video downloaded successfully', platformChannelSpecifics,
            payload: videoId);
      }
    });

    // Pipe the StreamController's stream to the file
    await streamController.stream.pipe(file.openWrite());

    yt.close();
    await SaverGallery.saveFile(
        file: filePath, name: filename, androidExistNotSave: true);
  }

//create local notificatins
  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'download_channel',
      'Download Channel',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

//request notification permission
  Future<void> requestNotificationPermissions() async {
    PermissionStatus status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

//Request Storage Permission
  Future<void> requeststoragepermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }
}
