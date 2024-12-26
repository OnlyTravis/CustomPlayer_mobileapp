import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/widgets/TagCard.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  List<Tag> tag_list = [];

  void button_toggleEditMode() {

  }

  @override
  void initState() {
    initTagList();
    super.initState();
  }

  Future<void> initTagList() async {
    final List<Tag> tmp = await db.getTagsFromSongId(widget.song.song_id);
    setState(() {
      tag_list = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text("Editing : ${widget.song.song_name}"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoTable(),
            SizedBox(height: 10),
            ...TagList()
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
                  ...tag_list.map((tag) => TagCard(
                    value: tag,
                  )),
                ],
              )
            ],
          ), 
        ),
      )
    ];
  }
}