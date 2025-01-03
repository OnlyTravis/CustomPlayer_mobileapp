import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
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

  @override
  void initState() {
    updateTagList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Mass Edit Song", 
      padding: EdgeInsets.all(8),
      child: ListView(
        children: [
          SongListCard(),
          EditTagCard(),
          AddTagCard(),
        ],
      ),
    );
  }

  Widget SongListCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selected Songs : ", textScaler: TextScaler.linear(1.5)),
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
  Widget EditTagCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tags : ", textScaler: TextScaler.linear(1.5)),
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
                Text("Common Tags Only : "),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
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
}