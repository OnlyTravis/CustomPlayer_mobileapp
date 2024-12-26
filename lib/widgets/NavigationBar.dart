import 'package:flutter/material.dart';
import 'package:song_player/main.dart';

class CommonNavigationBar extends StatefulWidget {
  const CommonNavigationBar({super.key});

  @override
  State<StatefulWidget> createState() => _CommonNavigationBarState();
}

class _CommonNavigationBarState extends State<CommonNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
        onDestinationSelected: (int index) {
          route_change.value = index;
        },
        selectedIndex: route_change.value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list), 
            label: "Song List",
          ),
          NavigationDestination(
            icon: Icon(Icons.audiotrack), 
            label: "Player",
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music), 
            label: "Queue",
          )
        ]
      );
  }
}