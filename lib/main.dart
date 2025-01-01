import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/pages/player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase();
  await initAudioHandler();
  await initFileHandler();
  runApp(SongPlayerApp());
}

class SongPlayerApp extends StatelessWidget with WidgetsBindingObserver {
  SongPlayerApp({super.key}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        audio_handler.setAppOpened(true);
        break;
      case AppLifecycleState.hidden:
        audio_handler.setAppOpened(false);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song Player',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 202, 248),
          brightness: Brightness.light,
        ),
      ),
      home: PlayerPage(),
    );
  }
}