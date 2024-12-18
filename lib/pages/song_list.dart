import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  List<String> song_file_list = [];


  Future<void> updateSongList() async {
    await audio_handler.updateSongList();
    setState(() {
      song_file_list = audio_handler.song_file_list;
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
      children: [...song_file_list.map((file_name) => Card(
        child: ListTile(
          title: Text(file_name),
          trailing: Wrap(
            children: [
              IconButton(
                onPressed: () => audio_handler.appendSongToQueue(file_name), 
                icon: Icon(Icons.add)
              ),
              IconButton(
                onPressed: () => audio_handler.replaceCurrentSong(file_name), 
                icon: Icon(Icons.play_arrow)
              ),
            ],
          )
        ),
      ))],
    );
  }
}