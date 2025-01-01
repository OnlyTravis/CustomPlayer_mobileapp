import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/TagCard.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  double volume = 1;

  bool is_editing = false;
  bool is_adding_tag = false;
  List<Tag> song_tag_list = [];
  List<Tag> tag_list = [];

  @override
  void initState() {
    initTagList();
    setState(() {
      volume = widget.song.volume;
    });
    super.initState();
  }

  Future<void> initTagList() async {
    final List<Tag> tmp_1 = await db.getTagsFromSongId(widget.song.song_id);
    final List<Tag> tmp_2 = await db.getAllTags();
    setState(() {
      song_tag_list = tmp_1;
      tag_list = tmp_2;
    });
  }

  void button_toggleEditMode() {
    setState(() {
      is_editing = !is_editing;
      if (!is_editing) {
        is_adding_tag = false;
      }
    });
  }
  void button_onToggleAddTag() {
    setState(() {
      is_adding_tag = !is_adding_tag;
    });
  }
  Future<void> button_onAddTag(Tag tag) async {
    await db.addTagToSong(widget.song.song_id, tag.tag_id);
    await initTagList();
    if (mounted) alert(context, "Tag \"${tag.tag_name}\" Added to Song!");
  }
  Future<void> button_onRemoveTag(Tag tag) async {
    await db.removeTagFromSong(widget.song.song_id, tag.tag_id);
    await initTagList();
    if (mounted) alert(context, "Tag \"${tag.tag_name}\" Removed to Song!");
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Viewing Song",
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTable(),
              VolumeSlider(),
              SizedBox(height: 10),
              TagList(),
              if (is_adding_tag) ...[SizedBox(height: 10), addTagMenu()]
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

  Widget VolumeSlider() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Song Volume : ",
              textScaler: TextScaler.linear(1.5),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(volume.toString()),
                Slider(
                  min: 0,
                  max: 3,
                  value: volume,
                  onChanged: (value) => {
                    setState(() {
                      volume = value;
                    })
                  },
                  onChangeEnd: (new_value) async {
                    await db.changeSongVolume(widget.song.song_id, volume);
                  },
                ),
                Text("3"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget InfoTable() {
    return Card(
      child: Table(
        columnWidths: {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth()
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          InfoRow("Name", widget.song.song_name, true),
          InfoRow("Author", widget.song.author.toString(), true),
          InfoRow("FilePath", widget.song.song_path, false),
          InfoRow("id", widget.song.song_id.toString(), false),
        ],
      ),
    );
  }
  TableRow InfoRow(String title, String value, bool editable) {
    return TableRow(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          child: Text(
            "$title: ", 
            textAlign: TextAlign.right,
            textScaler: TextScaler.linear(1.5),
          ),
        ),
        Container(
          padding: EdgeInsets.all(6),
          child: Text(
            value, 
            textScaler: TextScaler.linear(1.5)
          ),
        ),
      ]
    );
  }

  Widget TagList() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
                if (is_editing) addTagButton(),
              ],
            )
          ],
        ), 
      ),
    );
  }
  Widget addTagButton() {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          onPressed: button_onToggleAddTag, 
          icon: Icon(Icons.add),
        ),
      ),
    );
  }
  Widget addTagMenu() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
}