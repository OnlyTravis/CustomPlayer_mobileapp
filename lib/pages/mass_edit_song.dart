import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';
import 'package:song_player/widgets/RoundDropdown.dart';
import 'package:song_player/widgets/TagCard.dart';

class MassEditSongPage extends StatefulWidget {
  final List<Song> edit_song_list;

  const MassEditSongPage({super.key, required this.edit_song_list});

  @override
  State<StatefulWidget> createState() => _MassEditSongPageState();
}
class _MassEditSongPageState extends State<MassEditSongPage> {
  bool common_tags_only = true;
  List<Tag> common_tag_list = [];
  List<Tag> tag_list = [];
  List<Tag> all_tag_list = [];

  TextEditingController author_controller = TextEditingController();
  bool same_author = false;
  bool author_need_update = false;

  String selected_playlist = "";
  List<Playlist> playlist_list = [];

  Future<void> initPlaylistList() async {
    List<Playlist> tmp_playlist_list = await db.getAllPlaylists(sort: SortingStyle.nameAsc);
    setState(() {
      playlist_list = tmp_playlist_list.where((playlist) => !playlist.is_filtered_playlist).toList();
    });
  }

  void updateAuthorDisplay() {
    if (widget.edit_song_list[0].author != null) {
      bool author_are_same = true;
      String author = widget.edit_song_list[0].author ?? "";
      for (final song in widget.edit_song_list) {
        if (song.author != author) {
          author_are_same = false;
          break;
        }
      }
      if (author_are_same) {
        author_controller.text = author;
        setState(() {
          same_author = true;
        });
      }
    }
  }
  Future<void> updateTagList() async {
    // 1. Get common tags & contains tags
    Set<int> common_tags_set = Set.from(widget.edit_song_list[0].tag_id_list);
    Set<int> tags_set = Set.from(widget.edit_song_list[0].tag_id_list);
    for (int i = 1; i < widget.edit_song_list.length; i++) {
      Set<int> tmp_set = Set.from(widget.edit_song_list[i].tag_id_list);
      common_tags_set = common_tags_set.intersection(tmp_set);
      tags_set = tags_set.union(tmp_set);
    }
    
    // 2. Fetch tags from db
    List<Tag> tmp_common_tag_list = [];
    List<Tag> tmp_tag_list = [];
    List<Tag> tmp_all_tag_list = await db.getAllTags();
    for (final int tag_id in tags_set) {
      tmp_tag_list.add(await db.getTagFromTagId(tag_id));
    }
    for (final int tag_id in common_tags_set) {
      tmp_common_tag_list.add(tmp_tag_list.firstWhere((tag) => tag.tag_id == tag_id));
    }
    
    // 3. Set states
    setState(() {
      common_tag_list = tmp_common_tag_list;
      tag_list = tmp_tag_list;
      all_tag_list = tmp_all_tag_list;
    });
  }

  @override
  void initState() {
    updateAuthorDisplay();
    updateTagList();
    initPlaylistList();

    super.initState();
  }

  Future<void> button_addTagToSongs(Tag tag) async {
    for (int i = 0; i < widget.edit_song_list.length; i++) {
      if (!widget.edit_song_list[i].tag_id_list.contains(tag.tag_id)) {
        await db.addTagToSong(widget.edit_song_list[i].song_id, tag.tag_id);
        widget.edit_song_list[i].tag_id_list.add(tag.tag_id);
      }
    }
    await updateTagList();
  }
  Future<void> button_removeTagFromSongs(Tag tag) async {
    for (int i = 0; i < widget.edit_song_list.length; i++) {
      if (widget.edit_song_list[i].tag_id_list.contains(tag.tag_id)) {
        await db.removeTagFromSong(widget.edit_song_list[i].song_id, tag.tag_id);
        widget.edit_song_list[i].tag_id_list.remove(tag.tag_id);
      }
    }
    await updateTagList();
  }
  Future<void> button_batchSetAuthor() async {
    for (int i = 0; i < widget.edit_song_list.length; i++) {
      await db.changeAuthor(widget.edit_song_list[i].song_id, author_controller.text);
      widget.edit_song_list[i].author = author_controller.text;
    }
    setState(() {
      author_need_update = false;
    });
    updateAuthorDisplay();
    audio_handler.updateSongsInQueue();
  }
  void button_reset() {
    author_controller.text = "";
    updateAuthorDisplay();
    setState(() {
      author_need_update = false;
    });
  }
  Future<void> button_addToPlaylist() async {
    final int index = playlist_list.indexWhere((playlist) => playlist.playlist_name == selected_playlist);
    if (index == -1) {
      alert(context, "Invalid Playlist Input");
      return;
    }

    for (final song in widget.edit_song_list) {
      await db.addSongToPlaylist(playlist_list[index].playlist_id, song.song_id);
    }

    if (mounted) alert(context, "Song Added to Playlist!");
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      pageName: "Mass Edit Song",
      pageIcon: const Icon(Icons.music_note),
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: [
          SongListCard(),
          EditAuthorCard(),
          EditTagCard(),
          AddTagCard(),
          AddToPlaylistMenu(),
        ],
      ),
    );
  }

  Widget SongListCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selected Songs : ", textScaler: TextScaler.linear(1.5)),
            SizedBox(
              height: 256,
              child: ListView(
                children: [
                  ...widget.edit_song_list.map((song) => Text(song.song_name))
                ],
              ),
            )
          ],
        ),
      )
    );
  }
  Widget EditAuthorCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Author : ", textScaler: TextScaler.linear(1.5)),
                SizedBox(
                  width: 256,
                  height: 40,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: same_author?"":"<Authors are different>",
                    ),
                    controller: author_controller,
                    onChanged: (_) {
                      if (!author_need_update) setState(() {
                        author_need_update = true;
                      });
                    },
                  ),
                )
              ],
            ),
            if (author_need_update) Row(
              children: [
                TextButton(
                  onPressed: button_batchSetAuthor, 
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
                  onPressed: button_reset, 
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
      ),
    );
  }
  Widget EditTagCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tags : ", textScaler: TextScaler.linear(1.5)),
                Wrap(
                  children: [
                    ...(common_tags_only?common_tag_list:tag_list).map((tag) => TagCard(
                      value: tag,
                      removable: true,
                      onRemove: () => button_removeTagFromSongs(tag),
                    )),
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Common Tags Only : "),
                Switch(
                  value: common_tags_only, 
                  onChanged: (_) {
                    setState(() {
                      common_tags_only = !common_tags_only;
                    });
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget AddTagCard() {
    List<Tag> addable_tags = all_tag_list.where((tag) => (common_tag_list.indexWhere((val) => val.tag_id == tag.tag_id) == -1)).toList();
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tap To Add Tags To All Songs : ", textScaler: TextScaler.linear(1.5)),
            addable_tags.isEmpty?
              const Text("(No Tag Availiable)")
              : Wrap(
                children: [
                  ...addable_tags.map((tag) => TagCard(
                    value: tag,
                    tapable: true,
                    onTap: () => button_addTagToSongs(tag),
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