import 'package:flutter/material.dart';
import '/pages/video_detail_page.dart';

class CustomVideoWidget extends StatelessWidget {
  final String title;
  final String channelName;
  final List<String> thumbnails;
  final String duration;
  final String views;
  final String videoId;
  final List<String>? videolist;
  final List<String>? channelthumbnails;

  const CustomVideoWidget({
    super.key,
    required this.title,
    required this.channelName,
    required this.thumbnails,
    required this.duration,
    required this.views,
    required this.videoId,
    this.videolist,
    this.channelthumbnails,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => navigateToPlayer(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        child: Row(
          children: <Widget>[
            _buildThumbnail(context),
            _buildVideoDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: Stack(
        children: [
          Container(
            height: 80,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: thumbnails.isNotEmpty
                    ? NetworkImage(thumbnails[0])
                    : const AssetImage('https://via.placeholder.com/150')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 4.0,
            right: 4.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
              color: duration == "Live"
                  ? Colors.red.withOpacity(0.88)
                  : Colors.black54,
              child: Text(
                duration,
                style: TextStyle(
                  color: theme.textTheme.labelLarge?.color ?? Colors.white,
                  fontSize: 11,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDetails(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 20, left: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: theme.textTheme.labelLarge?.color ?? Colors.white,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              channelName,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: theme.textTheme.labelLarge?.color ?? Colors.white38,
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              views,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: theme.textTheme.labelLarge?.color ?? Colors.white38,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navigateToPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoDetailPage(
          videoId: videoId,
          videolist: videolist,
        ),
      ),
    );
  }
}
