import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/widgets/TagCard.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  bool is_editing = false;
  bool is_adding_tag = false;
  List<Tag> song_tag_list = [];
  List<Tag> tag_list = [];

  @override
  void initState() {
    initTagList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text("Viewing Song"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoTable(),
            SizedBox(height: 10),
            ...TagList(),
            if (is_adding_tag) ...[SizedBox(height: 10), addTagMenu()]
          ],
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: button_toggleEditMode,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.edit),
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
          InfoRow("Song Name", widget.song.song_name, true),
          InfoRow("Song Path", widget.song.song_path, false),
          InfoRow("Author", widget.song.author.toString(), true),
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

  List<Widget> TagList() {
    return [
      Card(
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
                  )),
                  if (is_editing) addTagButton(),
                ],
              )
            ],
          ), 
        ),
      )
    ];
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
                  onTap: button_onAddTag,
                )),
              ],
            )
          ],
        ), 
      ),
    );
  }
}