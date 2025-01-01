import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/main.dart';
import 'package:song_player/pages/edit_song.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  String current_folder = "";
  List<FileEntity> folder_list = [];
  List<Song> song_list = [];
  int opened_index = -1;

  Future<void> updateFileList(String dir) async {
    final List<FileEntity> tmp_list = file_handler.getFilesInDirectory(dir);
    final List<FileEntity> tmp_folder_list = [];
    final List<Song> tmp_song_list = [];

    for (final entity in tmp_list) {
      if (entity.file_type == FileType.folder) {
        tmp_folder_list.add(entity);
        continue;
      }
      tmp_song_list.add(await db.getSongFromEntity(entity));
    }
    setState(() {
      current_folder = dir;
      folder_list = tmp_folder_list;
      song_list = tmp_song_list;
    });
  }

  void onFileCardTap(int index) {
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
  void onFileCardView(Song song) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => EditSongPage(song: song))
    );
  }
  void onFolderCardTap(FileEntity folder) {
    updateFileList("${folder.file_name}/");
  }
  void onPreviousFolderTap() {
    final tmp_arr = current_folder.substring(current_folder.length-1).split("/");
    tmp_arr.removeLast();
    updateFileList((tmp_arr.length == 1)?"":"${tmp_arr.join("/")}/");
  }

  @override
  void initState() {
    updateFileList("");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Song List", 
      child: ListView(
        children: [
          if (current_folder.isNotEmpty) PreviousFolderCard(),
          ...folder_list.map((folder_entity) => FolderCard(folder_entity)),
          ...song_list.asMap().entries.map((entry) => FileCard(entry.value, entry.key)),
        ],
      )
    );
  }

  Widget FileCard(Song song, int index) {
    return GestureDetector(
      onTap: () => onFileCardTap(index),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(song.is_video?Icons.video_file:Icons.audio_file),
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
                  onPressed: () => onFileCardView(song), 
                  child: Text("View / Edit Song"),
                )
              ],
            )
          ],
        )
      ),
    );
  }
  Widget FolderCard(FileEntity folder) {
    return GestureDetector(
      onTap: () => onFolderCardTap(folder),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.file_name)
        ),
      ),
    );
  }
  Widget PreviousFolderCard() {
    return GestureDetector(
      onTap: onPreviousFolderTap,
      child: Card(
        child: const ListTile(
          leading: Icon(Icons.folder),
          title: Text("...")
        ),
      ),
    );
  }
}