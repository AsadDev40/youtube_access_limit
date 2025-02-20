// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/scrap_api/models/thumbnail.dart';
import '../pages/playlist_page.dart';

class PlayListWidget extends StatelessWidget {
  final List<Thumbnail> thumbnails;
  final String id, videoCount, title, channelName;

  const PlayListWidget({
    super.key,
    required this.id,
    required this.thumbnails,
    required this.videoCount,
    required this.title,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () => _onTap(context),
                child: Stack(
                  children: [
                    Container(
                      height: 80,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: Image.network(thumbnails[0].url!).image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 0.0,
                      child: Container(
                        height: 80,
                        width: 60,
                        color: Colors.black54,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_open,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  videoCount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    channelName,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayListPage(
          title: title,
          id: id,
        ),
      ),
    );
  }
}
