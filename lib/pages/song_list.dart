import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';

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

  Widget SongCard(Song song, int index) {
    return Card(
      child: Column(
        children: [
          ListTile(
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
            onTap: () => onSongCardTap(index),
          ),
          if (index == opened_index) Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => {}, 
                child: Text("Edit Song"),
              )
            ],
          )
        ],
      )
    );
  }
}