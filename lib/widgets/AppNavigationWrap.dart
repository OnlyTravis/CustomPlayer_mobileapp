import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/widgets/NavigationBar.dart';

enum Pages {
  otherPage, 
  songListPage,
  playerPage,
  queuePage,
  playlistPage,
  tagsPage,
  settingsPage,
}

class AppNavigationWrap extends StatefulWidget {
  final Widget child;
  final String page_name;
  final Pages page;
  final EdgeInsetsGeometry? padding;
  final List<Widget> actions;
  const AppNavigationWrap({super.key, required this.page_name, this.page = Pages.otherPage, this.padding, this.actions = const [], required this.child});

  @override
  State<StatefulWidget> createState() => _AppNavigationWrapState();
}
class _AppNavigationWrapState extends State<AppNavigationWrap> {
  String image_background_path = "";

  String getBackgroundImagePath() {
    final List<String> imageList = settings_manager.getSetting(Settings.bgImagePaths).cast<String>();
    if (imageList.isEmpty) return "";

    return imageList[Random().nextInt(imageList.length)];
  }

  @override
  void initState() {
    setState(() {
      image_background_path = getBackgroundImagePath();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.page_name),
        actions: widget.actions,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: widget.padding,
              width: double.infinity,
              decoration: image_background_path.isNotEmpty?BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(image_background_path)),
                  fit: BoxFit.cover,
                ),
              ):null,
              child: widget.child,
            )
          ),
          const CommonNavigationBar()
        ]
      ),
    );
  }
}