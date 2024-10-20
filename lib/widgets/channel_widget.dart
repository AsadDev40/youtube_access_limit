import 'package:flutter/material.dart';
import '/pages/channel/channel_page.dart';

class ChannelWidget extends StatelessWidget {
  final String id;
  final String thumbnail;
  final String title;
  final String? videoCount; // Make videoCount nullable
  final String? subscriberCount; // Add subscriberCount

  const ChannelWidget({
    super.key,
    required this.id,
    required this.thumbnail,
    required this.title,
    this.videoCount, // Accept nullable videoCount
    this.subscriberCount, // Accept nullable subscriberCount
  });

  @override
  Widget build(BuildContext context) {
    String imgUrl = thumbnail;
    if (!imgUrl.startsWith("https")) {
      imgUrl = "https://${imgUrl.substring(2)}";
    }

    // Determine which text to show based on videoCount or subscriberCount
    // String displayText;
    // if (videoCount != null && videoCount!.isNotEmpty) {
    //   displayText = "$videoCount videos •";
    // } else if (subscriberCount != null && subscriberCount!.isNotEmpty) {
    //   displayText = "$subscriberCount subscribers •";
    // } else {
    //   displayText = "No data available"; // Fallback text
    // }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Channelpage(id: id, title: title)),
        );
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 10, left: 10, top: 10),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 20),
              child: InkWell(
                onTap: () {},
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: Image.network(imgUrl).image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align to the start
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Cairo',
                        ),
                  ),
                  // const SizedBox(height: 15),
                  // Text(
                  //   displayText,
                  //   style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  //         color: Theme.of(context).unselectedWidgetColor,
                  //         fontFamily: 'Cairo',
                  //       ),
                  // ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
