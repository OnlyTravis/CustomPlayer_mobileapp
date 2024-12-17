import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:song_player/code/permission.dart';
import 'package:song_player/pages/song_list.dart';

void main() {
  runApp(const SongPlayerApp());
}

class SongPlayerApp extends StatelessWidget {
  const SongPlayerApp({super.key});

  Future<void> initApp() async {
    await requestPermission(Permission.manageExternalStorage);
    
  }

  @override
  Widget build(BuildContext context) {
    initApp();

    return MaterialApp(
      title: 'Song Player',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 191, 239, 255),
          brightness: Brightness.dark,
        ),
      ),
      home: AppNavigationWrap(),
    );
  }
}

class AppNavigationWrap extends StatefulWidget {
  const AppNavigationWrap({super.key});

  @override
  State<AppNavigationWrap> createState() => _AppNavigationWrapState();
}

class _AppNavigationWrapState extends State<AppNavigationWrap> {
  int current_page_index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list), 
            label: "Song List",
          ),
          NavigationDestination(
            icon: Icon(Icons.audiotrack), 
            label: "Player",
          )
        ]
      ),
      body: [
        SongListPage()
      ][current_page_index],
    );
  }
}