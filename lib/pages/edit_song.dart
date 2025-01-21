import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';
import 'package:song_player/widgets/RoundDropdown.dart';
import 'package:song_player/widgets/TagCard.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  List<Playlist> playlist_list = [];
  List<Tag> song_tag_list = [];
  List<Tag> tag_list = [];

  bool is_editing = false;
  bool need_update = false;
  double volume = 1;

  TextEditingController author_controller = TextEditingController();
  TextEditingController song_name_controller = TextEditingController();
  String selected_playlist = "";

  void initControllers() {
    author_controller.text = widget.song.author.toString();
    song_name_controller.text = widget.song.song_name;
  }

  Future<void> updateTagList() async {
    final List<Tag> tmp_song_tag_list = await db.getTagsFromSongId(widget.song.song_id);
    final List<Tag> tmp_all_tag_list = await db.getAllTags();
    setState(() {
      song_tag_list = tmp_song_tag_list;
      tag_list = tmp_all_tag_list;
    });
  }
  Future<void> initPlaylistList() async {
    List<Playlist> tmp_playlist_list = await db.getAllPlaylists(sort: SortingStyle.nameAsc);
    setState(() {
      playlist_list = tmp_playlist_list.where((playlist) => !playlist.is_filtered_playlist).toList();
    });
  }

  @override
  void initState() {
    initControllers();
    updateTagList();
    initPlaylistList();

    setState(() {
      volume = widget.song.volume;
    });
    super.initState();
  }

  void button_toggleEditMode() {
    setState(() {
      is_editing = !is_editing;
    });
  }
  Future<void> button_applyChange() async {
    // 1. Check if values are valid
    if (song_name_controller.text.isEmpty) {
      alert(context, "Please Enter a valid song name!");
      return;
    }
    if (author_controller.text.isEmpty) {
      alert(context, "Please Enter a valid author name!");
      return;
    }

    // 2. Update values
    if (author_controller.text != widget.song.author) {
      await db.changeAuthor(widget.song.song_id, author_controller.text);
      widget.song.author = author_controller.text;
    }
    if (song_name_controller.text != widget.song.song_name) {
      await db.changeSongName(widget.song.song_id, song_name_controller.text);
      widget.song.song_name = song_name_controller.text;
    }
    if (volume != widget.song.volume) {
      await db.changeSongVolume(widget.song.song_id, volume);
      widget.song.volume = volume;
    }

    setState(() {
      need_update = false;
    });

    audio_handler.updateSongsInQueue();
  }
  void button_resetChange() {
    initControllers();
    setState(() {
      need_update = false;
      volume = widget.song.volume;
    });
  }
  Future<void> button_onAddTag(Tag tag) async {
    await db.addTagToSong(widget.song.song_id, tag.tag_id);
    await updateTagList();
    if (mounted) alert(context, "Tag \"${tag.tag_name}\" Added to Song!");
  }
  Future<void> button_onRemoveTag(Tag tag) async {
    await db.removeTagFromSong(widget.song.song_id, tag.tag_id);
    await updateTagList();
    if (mounted) alert(context, "Tag \"${tag.tag_name}\" Removed to Song!");
  }
  Future<void> button_addToPlaylist() async {
    final int index = playlist_list.indexWhere((playlist) => playlist.playlist_name == selected_playlist);
    if (index == -1) {
      alert(context, "Invalid Playlist Input");
      return;
    }

    await db.addSongToPlaylist(playlist_list[index].playlist_id, widget.song.song_id);
    if (mounted) alert(context, "Song Added to Playlist!");
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      pageName: "Viewing Song",
      pageIcon: Icons.music_note,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: [
              InfoTable(),
              const SizedBox(height: 10),
              TagList(),
              if (is_editing) ...[
                const SizedBox(height: 10), 
                AddTagMenu()
              ],
              AddToPlaylistMenu(),
            ],
          )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: button_toggleEditMode,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget InfoTable() {
    return AppCard(
      child: Column(
        children: [
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              InfoRow("Name", widget.song.song_name, 
                editable: true, 
                controller: song_name_controller
              ),
              InfoRow("Author", widget.song.author.toString(), 
                editable: true,
                controller: author_controller,
              ),
              InfoRow("FilePath", widget.song.song_path),
              VolumeRow(),
              InfoRow("id", widget.song.song_id.toString()),
            ],
          ),
          if (need_update) Row(
            children: [
              TextButton(
                onPressed: button_applyChange, 
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Wrap(
                      children: [
                        Icon(Icons.update),
                        Text("Apply Changes")
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: button_resetChange, 
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Wrap(
                      children: [
                        Icon(Icons.cancel),
                        Text("Reset Changes")
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  TableRow InfoRow(String title, String value, {bool editable = false, TextEditingController? controller}) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          child: Text(
            "$title: ", 
            textAlign: TextAlign.right,
            textScaler: const TextScaler.linear(1.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          child: (is_editing && editable)? 
            SizedBox(
              height: 40,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {
                    need_update = true;
                  });
                },
                controller: controller,
              ),
            ) : Text(
              value, 
              textScaler: const TextScaler.linear(1.5)
            ),
        ),
      ]
    );
  }
  TableRow VolumeRow() {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          child: const Text(
            "Volume: ", 
            textAlign: TextAlign.right,
            textScaler: TextScaler.linear(1.5),
          ),
        ),
        is_editing?
          Container(
            padding: const EdgeInsets.fromLTRB(6, 0, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(volume.toStringAsFixed(2), textScaler: const TextScaler.linear(1.5)),
                Slider(
                  min: 0,
                  max: 1,
                  value: volume,
                  onChanged: (value) => {
                    setState(() {
                      volume = value;
                    })
                  },
                  onChangeEnd: (_) {
                    setState(() {
                      need_update = true;
                    });
                  },
                ),
                const Text("3.00", textScaler: TextScaler.linear(1.5)),
              ],
            ),
          ) : Container(
            padding: const EdgeInsets.all(6),
            child: Text(
              volume.toStringAsFixed(2), 
              textScaler: const TextScaler.linear(1.5)
            ),
          ),
      ]
    );
  }

  Widget TagList() {
    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tags : ",
              textScaler: TextScaler.linear(1.5),
            ),
            Wrap(
              direction: Axis.horizontal,
              children: [
                ...song_tag_list.map((tag) => TagCard(
                  value: tag,
                  removable: is_editing,
                  onRemove: () => button_onRemoveTag(tag),
                )),
              ],
            )
          ],
        ), 
      ),
    );
  }
  Widget AddTagMenu() {
    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Tags to Add : ",
              textScaler: TextScaler.linear(1.5),
            ),
            Wrap(
              direction: Axis.horizontal,
              children: [
                ...tag_list.where((tag) => (song_tag_list.indexWhere((val) => val.tag_id == tag.tag_id) == -1)).map((tag) => TagCard(
                  value: tag,
                  tapable: true,
                  onTap: () => button_onAddTag(tag),
                )),
              ],
            )
          ],
        ), 
      ),
    );
  }
  Widget AddToPlaylistMenu() {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add to Playlist : ", textScaler: TextScaler.linear(1.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RoundDropDown(
                value: selected_playlist,
                options: playlist_list.map((playlist) => playlist.playlist_name).toList(), 
                onChanged: (playlist_name) {
                  if (playlist_name == null) return;
                  setState(() {
                    selected_playlist = playlist_name;
                  });
                }
              ),
              AppCard(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: TextButton(
                  onPressed: button_addToPlaylist, 
                  child: const Wrap(
                    children: [
                      Icon(Icons.add),
                      Text("Add"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}