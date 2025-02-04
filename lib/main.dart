import 'dart:io';

import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/pages/player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSettingsManager();
  await initDatabase();
  await initAudioHandler();
  await initFileHandler();

  await db.addDefaultPlaylist();

  runApp(const SongPlayerApp());
}

class SongPlayerApp extends StatefulWidget {
  const SongPlayerApp({super.key});

  @override
  State<StatefulWidget> createState() => _SongPlayerAppState();
}

class _SongPlayerAppState extends State<SongPlayerApp> with WidgetsBindingObserver {
  Color seed_color = const Color.fromARGB(255, 255, 202, 248);
  bool is_dark_mode = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!audio_handler.app_opened) {
          audio_handler.setAppOpened(true);
          preloadImages();
        }
        break;
      case AppLifecycleState.hidden:
        audio_handler.setAppOpened(false);
        break;
      default:
        break;
    }
  }

  Color colorFromArr(List<int> arr) {
    return Color.fromARGB(arr[3], arr[0], arr[1], arr[2]);
  }
  void updateUI() {
    setState(() {
      seed_color = colorFromArr(settings_manager.getSetting(Settings.interfaceColor).cast<int>());
      is_dark_mode = settings_manager.getSetting(Settings.isDarkMode);
    });
  }
  
  Future<void> preloadImages() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final imageList = settings_manager.getSetting(Settings.bgImagePaths);
    if (imageList.isEmpty) return;

    for (final String path in imageList) {
      if (mounted) await precacheImage(FileImage(File(path)), context);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // 1. Update & Listen for UI settings change
    updateUI();
    settings_manager.notifiers[Settings.interfaceColor.value]?.addListener(updateUI);
    settings_manager.notifiers[Settings.isDarkMode.value]?.addListener(updateUI);

    // 2. Preload Images
    preloadImages();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song Player',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed_color,
          brightness: is_dark_mode?Brightness.dark: Brightness.light,
        ),
      ),
      home: const PlayerPage(),
    );
  }
}