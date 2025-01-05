import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/pages/edit_song.dart';
import 'package:song_player/pages/mass_edit_song.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';

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
  void deselectFile(int index) {
    selected_files.remove(index);
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

  void button_onFileCardTap(int index) {
    if (is_select_mode) {
      button_onFileCardLongPress(index);
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
  void button_onFileCardLongPress(int index) {
    if (selected_files.contains(index)) {
      deselectFile(index);
      return;
    }

    setState(() {
      selected_files.add(index);
      is_select_mode = true;
      all_selected = checkAllSelected();
    });
  }
  void button_onFileCardView(Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditSongPage(song: song))
    );
  }
  void button_onFolderCardTap(FileEntity folder) {
    updateFileList("${folder.file_directory}${folder.file_name}/");
  }
  void button_onPreviousFolderTap() {
    final List<String> tmp_arr = current_folder.substring(0, current_folder.length-1).split("/");
    tmp_arr.removeLast();
    updateFileList((tmp_arr.isEmpty)?"":"${tmp_arr.join("/")}/");
  }
  void button_onSelectAll() {
    if (all_selected) {
      setState(() {
        all_selected = false;
        selected_files = [];
      });
      return;
    }

    setState(() {
      all_selected = true;
      selected_files = List.generate(song_list.length, (int index) => index);
    });
  }
  Future<void> button_onMassEditSong() async {
    final List<Song> selected_song_list = [];
    for (final index in selected_files) {
      selected_song_list.add(song_list[index]);
    }

    setState(() {
      selected_files = [];
      is_select_mode = false;
      all_selected = false;
      opened_index = -1;
    });

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MassEditSongPage(edit_song_list: selected_song_list))
    );
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
      page: Pages.songListPage,
      child: Scaffold(
        appBar: is_select_mode?toolBar():null,
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
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
        onChanged: (_) => button_onSelectAll(),
      ),
      title: Text(
        "Selected : ${selected_files.length}",
        textScaler: const TextScaler.linear(0.8),
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
          onPressed: button_onMassEditSong,
          child: const Text("Mass Edit Song"),
        ),
      ]
    );
  }

  Widget fileCard(Song song, int index) {
    bool is_selected = selected_files.contains(index);
    return GestureDetector(
      onTap: () => button_onFileCardTap(index),
      onLongPress: () => button_onFileCardLongPress(index),
      child: AppCard(
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
                        icon: const Icon(Icons.add)
                      ),
                      IconButton(
                        onPressed: () => audio_handler.replaceCurrent(song), 
                        icon: const Icon(Icons.play_arrow)
                      ),
                    ],
                  ),
                ),
                if (index == opened_index) Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => button_onFileCardView(song), 
                      child: const Text("View / Edit Song"),
                    )
                  ],
                )
              ],
            ),
            if (is_select_mode) Align(
              alignment: const Alignment(1.05, 5),
              child: Checkbox(
                value: is_selected,
                onChanged: (_) => button_onFileCardLongPress(index),
              ),
            )
          ],
        )
      ),
    );
  }
  Widget folderCard(FileEntity folder) {
    return GestureDetector(
      onTap: () => button_onFolderCardTap(folder),
      child: AppCard(
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.file_name)
        ),
      ),
    );
  }
  Widget previousFolderCard() {
    return GestureDetector(
      onTap: button_onPreviousFolderTap,
      child: const AppCard(
        child: ListTile(
          leading: Icon(Icons.folder),
          title: Text("..")
        ),
      ),
    );
  }
}