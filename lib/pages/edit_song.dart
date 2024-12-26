import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/widgets/NavigationBar.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text("Editing : ${widget.song.song_name}"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text("Song Name : ${widget.song.song_name}")
          ],
        ),
      ),
      bottomNavigationBar: CommonNavigationBar(),
    );
  }
}