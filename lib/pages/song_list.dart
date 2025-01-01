import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/pages/edit_song.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';

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

  List<int> selected_files = [];
  bool is_select_mode = false;
  bool all_selected = false;

  Future<void> updateFileList(String dir) async {
    final List<FileEntity> tmp_list = file_handler.getFilesInDirectory(dir);
    final List<FileEntity> tmp_folder_list = [];
    final List<Song> tmp_song_list = [];

    // 1. Convert file entity list for rendering & Clear selection
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

      opened_index = -1;

      is_select_mode = false;
      all_selected = false;
      selected_files = [];
    });

    // 2. Check if all files are selected (if select mode)
    if (is_select_mode) {
      checkAllSelected();
    }
  }
  void deselectFile(int song_id) {
    selected_files.remove(song_id);
    setState(() {
      if (selected_files.isEmpty) {
        is_select_mode = false;
      }
      all_selected = checkAllSelected();
    });
  }
  bool checkAllSelected() {
    return song_list.length == selected_files.length;
  }

  void onFileCardTap(int index) {
    if (is_select_mode) {
      onFileCardLongPress(index);
      return;
    }

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
  void onFileCardLongPress(int index) {
    int song_id = song_list[index].song_id;
    if (selected_files.contains(song_id)) {
      deselectFile(song_id);
      return;
    }

    setState(() {
      selected_files.add(song_id);
      is_select_mode = true;
      all_selected = checkAllSelected();
    });
  }
  void onFileCardView(Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditSongPage(song: song))
    );
  }
  void onFolderCardTap(FileEntity folder) {
    updateFileList("${folder.file_directory}${folder.file_name}/");
  }
  void onPreviousFolderTap() {
    final List<String> tmp_arr = current_folder.substring(0, current_folder.length-1).split("/");
    tmp_arr.removeLast();
    updateFileList((tmp_arr.isEmpty)?"":"${tmp_arr.join("/")}/");
  }
  void onSelectAll() {
    if (all_selected) {
      setState(() {
        all_selected = false;
        selected_files = [];
      });
      return;
    }

    setState(() {
      all_selected = true;
      selected_files = song_list.map((song) => song.song_id).toList();
    });
  }

  @override
  void initState() {
    updateFileList("");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Song List - /$current_folder", 
      child: Scaffold(
        appBar: is_select_mode?toolBar():null,
        body: ListView(
          children: [
            if (current_folder.isNotEmpty) previousFolderCard(),
            ...folder_list.map((folder_entity) => folderCard(folder_entity)),
            ...song_list.asMap().entries.map((entry) => fileCard(entry.value, entry.key)),
          ],
        ),
      )
    );
  }

  AppBar toolBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      toolbarHeight: 40,
      leading: Checkbox(
        value: all_selected, 
        onChanged: (_) => onSelectAll(),
      ),
      title: Text(
        "Selected : ${selected_files.length}",
        textScaler: TextScaler.linear(0.8),
      ),
      actions: [
        selectOptions()
      ],
    );
  }
  Widget selectOptions() {
    return MenuAnchor(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
      menuChildren: [
        MenuItemButton(
          child: Text("Add To Playlist"),
        ),
        MenuItemButton(
          child: Text("Add Tags"),
        ),
        MenuItemButton(
          child: Text("Remove Tags"),
        ),
      ]
    );
  }

  Widget fileCard(Song song, int index) {
    bool is_selected = selected_files.contains(song.song_id);
    return GestureDetector(
      onTap: () => onFileCardTap(index),
      onLongPress: () => onFileCardLongPress(index),
      child: Card(
        color: is_selected?Theme.of(context).colorScheme.secondaryContainer:null,
        child: Stack(
          children: [
            Column(
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
            ),
            if (is_select_mode) Align(
              alignment: Alignment(1.05, 5),
              child: Checkbox(
                value: is_selected,
                onChanged: (_) => onFileCardLongPress(index),
              ),
            )
          ],
        )
      ),
    );
  }
  Widget folderCard(FileEntity folder) {
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
  Widget previousFolderCard() {
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