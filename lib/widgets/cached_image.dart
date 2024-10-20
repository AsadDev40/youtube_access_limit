import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  const CachedImage(
    this.imageUrl, {
    super.key,
    this.width,
    this.height,
    this.radius = 0,
    this.borderRadius,
    this.isRound = false,
    this.isAsset = false,
    this.fit = BoxFit.cover,
  });

  final BoxFit fit;
  final bool isRound;
  final bool isAsset;
  final double radius;
  final double? width;
  final double? height;
  final String? imageUrl;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    try {
      return SizedBox(
        width: isRound ? radius : width,
        height: isRound ? radius : height,
        child: ClipRRect(
          borderRadius:
              borderRadius ?? BorderRadius.circular(isRound ? 50 : radius),
          child: isAsset
              ? Image.asset(imageUrl!, fit: fit)
              : imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: fit,
                      // ignore: prefer_expression_function_bodies
                      placeholder: (context, url) {
                        // return const CustomCircularProgress();
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.secondary),
                          ),
                        );
                      },
                      errorWidget: (context, url, error) {
                        return const _ImageNotAvailableWidget();
                      },
                    )
                  : const _ImageNotAvailableWidget(),
        ),
      );
    } catch (e) {
      debugPrint('CachedImage.build: ${e.toString()}');

      return const _ImageNotAvailableWidget();
    }
  }
}

class _ImageNotAvailableWidget extends StatelessWidget {
  const _ImageNotAvailableWidget();

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/image_not_available.png', fit: BoxFit.cover);
}
