import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/pages/channel_view_page.dart';
import 'package:kidsafe_youtube/scrap_api/models/channel_data.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildChannelPage extends StatefulWidget {
  const ChildChannelPage({super.key});

  @override
  State<ChildChannelPage> createState() => _ChildChannelPageState();
}

class _ChildChannelPageState extends State<ChildChannelPage> {
  bool _isParent = false;
  late Future<List<ChannelData?>> _channelFutures;

  @override
  void initState() {
    super.initState();
    _loadIsParent();
    _loadChannels();
  }

  Future<void> _loadIsParent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isParent = prefs.getBool('parent') ?? false;
    });
  }

  Future<void> _loadChannels() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    setState(() {
      _channelFutures = Future.wait(
        childProvider.currentChild?.channels.map((channelId) {
              return YoutubeDataApi().fetchChannelData(channelId);
            }).toList() ??
            [],
      );
    });
  }

  Future<void> _refreshChannels() async {
    await _loadChannels();
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshChannels,
        child: FutureBuilder<List<ChannelData?>>(
          future: _channelFutures,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('An error occurred while fetching data.'),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No channels found'),
              );
            }

            final channelList = snapshot.data!;
            return ListView.builder(
              itemCount: channelList.length,
              itemBuilder: (BuildContext context, int index) {
                final channel = channelList[index]?.channel;
                if (channel == null) {
                  return const ListTile(
                    title: Text('No channel data found'),
                  );
                }

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChannelViewPage(
                          data: channelList[index]!,
                          id: childProvider.currentChild!.channels[index],
                        ),
                      ),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(channel.channelName)),
                      if (_isParent)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            var childId = childProvider.currentChild?.uid;
                            await childProvider.deleteChannelFromChild(
                              channel.channelId,
                              childId!,
                            );
                            setState(() {
                              channelList.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(channel.avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
