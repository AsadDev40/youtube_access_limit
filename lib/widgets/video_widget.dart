import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import '/pages/video_detail_page.dart';

class VideoWidget extends StatelessWidget {
  final Video video;
  final List<String>? videolist;

  const VideoWidget({super.key, required this.video, this.videolist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToPlayer(context),
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
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: video.thumbnails?.first.url ?? video.thumbnailUrl ?? '',
            imageBuilder: (context, imageProvider) => Container(
              height: 80,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            placeholder: (context, url) => Container(
              height: 80,
              width: 140,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 80,
              width: 140,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),
          if (video.duration != null) _buildDurationLabel(),
        ],
      ),
    );
  }

  Widget _buildDurationLabel() {
    final isLive = video.duration == "Live";
    return Positioned(
      bottom: 4.0,
      right: 4.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
        color: isLive ? Colors.red.withOpacity(0.88) : Colors.black54,
        child: Text(
          video.duration!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDetails(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.title ?? 'No Title',
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
              video.channelName ?? 'Unknown Channel',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: theme.textTheme.labelLarge?.color ?? Colors.white38,
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              video.views ?? 'No Views',
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

  void _navigateToPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoDetailPage(
          videoId: video.videoId!,
          videolist: videolist,
        ),
      ),
    );
  }
}
