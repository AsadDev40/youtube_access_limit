// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kidsafe_youtube/pages/shorts_page.dart';
import 'package:kidsafe_youtube/pages/subscription_screen.dart';
import 'package:kidsafe_youtube/scrap_api/models/video.dart';
import 'package:kidsafe_youtube/scrap_api/models/youtube_data_api.dart';
import 'package:kidsafe_youtube/utilities/custom_app_bar.dart';
import 'package:kidsafe_youtube/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../providers/subscription.dart';

import '../../theme/colors.dart';
import '../../utilities/categories.dart';
import '/pages/home/body.dart';
import '/widgets/loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  YoutubeDataApi youtubeDataApi = YoutubeDataApi();
  List<Video>? contentList;
  int _selectedIndex = 0;
  late Future<List<Video>> trending;
  int trendingIndex = 0;
  late double progressPosition;
  bool showSubscriptionScreen = false;
  bool isLoading = true;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkUserSubscriptionStatus();
    _checkInternetConnection();
    trending = youtubeDataApi.fetchHomeVideos();
    contentList = [];
  }

  Future<void> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));

      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
        });
      } else {
        setState(() {
          isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _checkInternetConnection();

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Internet Connection!")),
      );
      return;
    }

    List<Video> newList = await youtubeDataApi.fetchHomeVideos();

    if (newList.isNotEmpty) {
      setState(() {
        contentList = newList;
      });
    }
  }

  Future<void> _checkUserSubscriptionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Subscriptionprovider().checkSubscriptionStatus(user.uid);

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        bool isTrial = userData['isTrial'] ?? true;
        bool isSubscribed = userData['isSubscribed'] ?? false;
        DateTime creationDate = (userData['createdAt'] as Timestamp).toDate();

        if (isTrial && DateTime.now().difference(creationDate).inDays >= 3) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isTrial': false});
          isTrial = false;
        }

        if (!isTrial && !isSubscribed) {
          setState(() {
            showSubscriptionScreen = true;
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showSubscriptionScreen) {
      return const SubscriptionScreen();
    }

    progressPosition = MediaQuery.of(context).size.height / 0.5;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: body(),
      ),
      bottomNavigationBar: customBottomNavigationBar(),
    );
  }

  Widget body() {
    if (!isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Network Error: Please check your connection"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _refresh();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: pink, foregroundColor: Colors.black),
              child: const Text(
                "Retry",
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Categories(
              callback: changeTrendingState,
              trendingIndex: trendingIndex,
            ),
          ),
          FutureBuilder<List<Video>>(
            future: trending,
            builder:
                (BuildContext context, AsyncSnapshot<List<Video>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.active:
                  return Padding(
                    padding: const EdgeInsets.only(top: 300),
                    child: loading(),
                  );
                case ConnectionState.none:
                  return const Text("Connection None");
                case ConnectionState.done:
                  if (snapshot.error != null) {
                    return Text(snapshot.error.toString());
                  } else {
                    if (snapshot.hasData) {
                      contentList = snapshot.data;
                      return Body(contentList: contentList!);
                    } else {
                      return const Center(child: Text("No data"));
                    }
                  }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget customBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(30), topLeft: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF8B949D),
          selectedItemColor: pink,
          selectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department),
              label: 'Trending',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.live_tv), label: 'Subscriptions'),
            BottomNavigationBarItem(
                icon: Icon(Icons.recommend), label: 'Recommendation'),
            BottomNavigationBarItem(
                icon: Icon(Icons.video_call), label: 'Shorts'),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShortsPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void changeTrendingState(int index) {
    switch (index) {
      case 0:
        setState(() {
          trending = youtubeDataApi.fetchHomeVideos();
        });
        break;
      case 1:
        setState(() {
          trending = youtubeDataApi.fetchTrendingVideo();
        });
        break;
      case 2:
        setState(() {
          trending = youtubeDataApi.fetchTrendingMusic();
        });
        break;
      case 3:
        setState(() {
          trending = youtubeDataApi.fetchTrendingGaming();
        });
        break;
      case 4:
        setState(() {
          trending = youtubeDataApi.fetchTrendingMovies();
        });
        break;
    }
    trendingIndex = index;
  }
}
