// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidsafe_youtube/Utils/firestore_collection.dart';
import 'package:kidsafe_youtube/pages/channel_view_page.dart';
import 'package:kidsafe_youtube/scrap_api/models/channel_data.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:flutter/material.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  YoutubeDataApi youtubeDataApi = YoutubeDataApi();
  List<ChannelData> channelDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChannelData();
  }

  Future<void> fetchChannelData() async {
    try {
      QuerySnapshot snapshot = await recommendCollection.get();
      List<ChannelData> loadedChannelData = [];

      for (var doc in snapshot.docs) {
        String channelId = doc['channelID'];
        ChannelData? data = await youtubeDataApi.fetchChannelData(channelId);
        if (data != null) {
          loadedChannelData.add(data);
        }
      }

      setState(() {
        channelDataList = loadedChannelData;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : channelDataList.isEmpty
              ? const Center(
                  child: Text('No Data Found!'),
                )
              : ListView.builder(
                  itemCount: channelDataList.length,
                  itemBuilder: (context, index) {
                    final data = channelDataList[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChannelViewPage(
                              data: data,
                              id: data.channel.channelId,
                            ),
                          ),
                        );
                      },
                      title: Text(data.channel.channelName),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(data.channel.avatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
