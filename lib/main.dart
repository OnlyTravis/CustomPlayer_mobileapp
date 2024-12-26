import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/pages/edit_song.dart';
import 'package:song_player/pages/queue.dart';
import 'package:song_player/pages/song_list.dart';
import 'package:song_player/pages/player.dart';
import 'package:song_player/widgets/NavigationBar.dart';

ValueNotifier<int> route_change = ValueNotifier(0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase();
  await initAudioHandler();
  runApp(const SongPlayerApp());
}

class SongPlayerApp extends StatelessWidget {
  const SongPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
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

class _AppNavigationWrapState extends State<AppNavigationWrap> with WidgetsBindingObserver {
  int current_page_index = 0;

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
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    route_change.addListener(() {
      setState(() {
        current_page_index = route_change.value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CommonNavigationBar(),
      body: [
        SongListPage(),
        PlayerPage(),
        QueuePage(),
      ][current_page_index],
    );
  }
}