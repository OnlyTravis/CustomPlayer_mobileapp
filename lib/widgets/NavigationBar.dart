import 'package:flutter/material.dart';
import 'package:song_player/main.dart';
import 'package:song_player/pages/player.dart';
import 'package:song_player/pages/playlist.dart';
import 'package:song_player/pages/queue.dart';
import 'package:song_player/pages/song_list.dart';
import 'package:song_player/pages/tag_list.dart';

class CommonNavigationBar extends StatefulWidget {
  const CommonNavigationBar({super.key});

  @override
  State<StatefulWidget> createState() => _CommonNavigationBarState();
}

class _CommonNavigationBarState extends State<CommonNavigationBar> {
  static int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NavigationButton("Song List", Icons.list, 0),
          NavigationButton("Player", Icons.audiotrack, 1),
          NavigationButton("Queue", Icons.queue_music, 2),
          NavigationButton("Playlist", Icons.playlist_add, 3),
          NavigationButton("Tags", Icons.tag, 4),
        ],
      ),
    );
  }

  Widget NavigationButton(String title, IconData icon, int index) {
    return GestureDetector(
      onTap: () => button_navigationButtonOnPress(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: (selected == index)?const Color.fromARGB(44, 93, 93, 93):null,
        ),
        child: Column(
          children: [
            Icon(icon),
            Text(title)
          ],
        ),
      )
    );
  }

  void button_navigationButtonOnPress(int index) {
    setState(() {
      selected = index;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AppNavigationWrap(
        child: routeFromIndex(index),
      ))
    );
  }

  Widget routeFromIndex(int index) {
    switch (index) {
      case 0: return SongListPage();
      case 1: return PlayerPage();
      case 2: return QueuePage();
      case 3: return PlaylistPage();
      case 4: return TagListPage();
    }
    return Container();
  }
}