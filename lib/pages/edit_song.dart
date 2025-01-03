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
  List<Tag> song_tag_list = [];
  List<Tag> tag_list = [];

  bool is_editing = false;
  bool need_update = false;
  double volume = 1;

  TextEditingController author_controller = TextEditingController();
  TextEditingController song_name_controller = TextEditingController();

  void initControllers() {
    author_controller.text = widget.song.author.toString();
    song_name_controller.text = widget.song.song_name;
  }

  Future<void> initTagList() async {
    final List<Tag> tmp_1 = await db.getTagsFromSongId(widget.song.song_id);
    final List<Tag> tmp_2 = await db.getAllTags();
    setState(() {
      song_tag_list = tmp_1;
      tag_list = tmp_2;
    });
  }

  @override
  void initState() {
    initControllers();
    initTagList();

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
  Future<void> button_update() async {
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
  }
  void button_reset() {
    initControllers();
    setState(() {
      need_update = false;
      volume = widget.song.volume;
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
          child: ListView(
            children: [
              InfoTable(),
              SizedBox(height: 10),
              TagList(),
              if (is_editing) ...[SizedBox(height: 10), addTagMenu()]
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
    return Card(
      child: Column(
        children: [
          Table(
            columnWidths: {
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
                onPressed: button_update, 
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
    );
  }
  TableRow InfoRow(String title, String value, {bool editable = false, TextEditingController? controller}) {
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
          child: (is_editing && editable)? 
            SizedBox(
              height: 40,
              child: TextFormField(
                decoration: InputDecoration(
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
              textScaler: TextScaler.linear(1.5)
            ),
        ),
      ]
    );
  }
  TableRow VolumeRow() {
    return TableRow(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          child: Text(
            "Volume: ", 
            textAlign: TextAlign.right,
            textScaler: TextScaler.linear(1.5),
          ),
        ),
        is_editing?
          Container(
            padding: EdgeInsets.fromLTRB(6, 0, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(volume.toStringAsFixed(2), textScaler: TextScaler.linear(1.5)),
                Slider(
                  min: 0,
                  max: 3,
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
            padding: EdgeInsets.all(6),
            child: Text(
              volume.toStringAsFixed(2), 
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
              ],
            )
          ],
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