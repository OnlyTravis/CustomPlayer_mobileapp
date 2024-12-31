import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/pages/player.dart';
import 'package:song_player/widgets/NavigationBar.dart';

ValueNotifier<int> route_change = ValueNotifier(0);

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

class AppNavigationWrap extends StatefulWidget {
  final Widget child;
  final String page_name;
  const AppNavigationWrap({super.key, required this.page_name, required this.child});

  @override
  State<AppNavigationWrap> createState() => _AppNavigationWrapState();
}

class _AppNavigationWrapState extends State<AppNavigationWrap> {
  int current_page_index = 0;

  @override
  void initState() {
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.page_name),
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: widget.child,
            )
          ),
          CommonNavigationBar()
        ]
      ),
    );
  }
}