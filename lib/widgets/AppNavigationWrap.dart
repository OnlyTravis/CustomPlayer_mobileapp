import 'dart:io';

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

class AppNavigationWrap extends StatelessWidget {
  final Widget child;
  final String page_name;
  final Pages page;
  final EdgeInsetsGeometry? padding;
  final List<Widget> actions;
  const AppNavigationWrap({super.key, required this.page_name, this.page = Pages.otherPage, this.padding, this.actions = const [], required this.child});

  String getBackgroundImagePath() {
    switch (page) {
      case Pages.otherPage:
        return settings_manager.getSetting(Settings.defaultImagePath);

      case Pages.songListPage:
        final String path = settings_manager.getSetting(Settings.songListImagePath);
        if (path.isEmpty) return settings_manager.getSetting(Settings.defaultImagePath);
        return settings_manager.getSetting(Settings.songListImagePath);

      case Pages.playerPage:
        final String path = settings_manager.getSetting(Settings.playerImagePath);
        if (path.isEmpty) return settings_manager.getSetting(Settings.defaultImagePath);
        return settings_manager.getSetting(Settings.playerImagePath);
      
      case Pages.queuePage:
        final String path = settings_manager.getSetting(Settings.queueImagePath);
        if (path.isEmpty) return settings_manager.getSetting(Settings.defaultImagePath);
        return settings_manager.getSetting(Settings.queueImagePath);
      
      case Pages.playlistPage:
        final String path = settings_manager.getSetting(Settings.playlistImagePath);
        if (path.isEmpty) return settings_manager.getSetting(Settings.defaultImagePath);
        return settings_manager.getSetting(Settings.playlistImagePath);

      case Pages.tagsPage:
        final String path = settings_manager.getSetting(Settings.tagImagePath);
        if (path.isEmpty) return settings_manager.getSetting(Settings.defaultImagePath);
        return settings_manager.getSetting(Settings.tagImagePath);
      
      case Pages.settingsPage:
        final String path = settings_manager.getSetting(Settings.settingImagePath);
        if (path.isEmpty) return settings_manager.getSetting(Settings.defaultImagePath);
        return settings_manager.getSetting(Settings.settingImagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    String image_background_path = getBackgroundImagePath();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(page_name),
        actions: actions,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: padding,
              width: double.infinity,
              decoration: image_background_path.isNotEmpty?BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(image_background_path)),
                  fit: BoxFit.cover,
                ),
              ):null,
              child: child,
            )
          ),
          CommonNavigationBar()
        ]
      ),
    );
  }
}