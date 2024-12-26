import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  int editing = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text("Song : ${widget.song.song_name}"),
      ),
      body: Column(
        children: [
          Text("Song Name : ${widget.song.song_name}")
        ],
      ),
    );
  }
}