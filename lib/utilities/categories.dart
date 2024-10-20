// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import '/constants.dart';
import '/theme/colors.dart';

class Categories extends StatefulWidget {
  void Function(int) callback;
  int trendingIndex;
  Categories({super.key, required this.callback, required this.trendingIndex});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<String> categories = ["All", "Trending", "Music", "Gaming", "Movies"];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) => buildCategory(index),
      ),
    );
  }

  Widget buildCategory(int index) {
    return GestureDetector(
      onTap: () {
        widget.trendingIndex = index;
        widget.callback(widget.trendingIndex);
      },
      child: widget.trendingIndex == index
          ? Align(
              child: Container(
                height: 38,
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), color: pink),
                child: Center(
                  child: Text(
                    categories[index],
                    style: const TextStyle(
                        color: PrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo'),
                  ),
                ),
              ),
            )
          : Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Center(
                child: Text(
                  categories[index],
                  style: const TextStyle(
                      color: Color(0xff9e9e9e),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo'),
                ),
              ),
            ),
    );
  }
}
