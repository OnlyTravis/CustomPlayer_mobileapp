import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/pages/edit_song.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  int opened_index = -1;
  List<Song> song_list = [];

  Future<void> updateSongList() async {
    await audio_handler.updateSongList();
    setState(() {
      song_list = audio_handler.song_list;
    });
  }

  @override
  void initState() {
    updateSongList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text("Song List"),
      ),
      body: _SongList(),
    );
  }

  Widget _SongList() {
    return ListView(
      children: [...song_list.asMap().entries.map((entry) => SongCard(entry.value, entry.key))],
    );
  }

  void onSongCardTap(int index) {
    if (opened_index == index) {
      setState(() {
        opened_index = -1;
      });
    } else {
      setState(() {
        opened_index = index;
      });
    }
  }

  void onSongCardView(Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditSongPage(song: song))
    );
  }

  Widget SongCard(Song song, int index) {
    return GestureDetector(
      onTap: () => onSongCardTap(index),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.audio_file),
              title: Text(song.song_name),
              subtitle: (index == opened_index)?Text("Author : ${song.author}"):null,
              trailing: Wrap(
                children: [
                  IconButton(
                    onPressed: () => audio_handler.addToQueue(song), 
                    icon: Icon(Icons.add)
                  ),
                  IconButton(
                    onPressed: () => audio_handler.replaceCurrent(song), 
                    icon: Icon(Icons.play_arrow)
                  ),
                ],
              ),
            ),
            if (index == opened_index) Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onSongCardView(song), 
                  child: Text("View / Edit Song"),
                )
              ],
            )
          ],
        )
      ),
    );
  }
}