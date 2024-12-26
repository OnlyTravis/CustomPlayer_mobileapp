import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/widgets/TagCard.dart';

class TagListPage extends StatefulWidget {
  const TagListPage({super.key});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  List<Tag> tag_list = [];

  @override
  void initState() {
    initTagList();
    super.initState();
  }

  Future<void> initTagList() async {
    List<Tag> tmp = await db.getAllTags();
    setState(() {
      tag_list = tmp;
    });
  }

  Future<void> button_renameTag(Tag tag) async {

  }
  Future<void> button_deleteTag(Tag tag) async {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text("Tag List"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...tag_list.asMap().entries.map((entry) => ShowTagCard(entry.value, entry.key)),
            CreateTagMenu(onAdd: initTagList)
          ],
        )
      ),
    );
  }

  Widget ShowTagCard(Tag value, int index) {
    return Card(
      child: ListTile(
        leading: Text(index.toString()),
        title: Text(value.tag_name),
        subtitle: Text("Used in : ${value.tag_count.toString()}"),
        trailing: Wrap(
          children: [
            IconButton(onPressed: () => button_renameTag(value), icon: Icon(Icons.drive_file_rename_outline)),
            IconButton(onPressed: () => button_deleteTag(value), icon: Icon(Icons.delete)),
          ],
        ),
      ),
    );
  }
}

class CreateTagMenu extends StatefulWidget {
  final Function onAdd;
  const CreateTagMenu({super.key, required this.onAdd});

  @override
  State<CreateTagMenu> createState() => _CreateTagMenuState();
}
class _CreateTagMenuState extends State<CreateTagMenu> {
  bool isCreating = false;
  final TextEditingController tag_name_controller = TextEditingController();

  void button_toggleCreateTag() {
    setState(() {
      isCreating = !isCreating;
    });
  }

  Future<void> button_createTag() async {
    if (tag_name_controller.text.isEmpty || db.detectSqlInjection(tag_name_controller.text)) {
      displaySnackBar("Please Enter a valid tag name ( without ' \" \\ )");
      return;
    }

    if (!await db.createTag(tag_name_controller.text, 0)) {// todo
      displaySnackBar("Something went wrong while adding tag to database.");
      return;
    }

    displaySnackBar("Tag \"${tag_name_controller.text}\" Added!");
    widget.onAdd();
  }

  void displaySnackBar(String text) {
    final snack_bar = SnackBar(
      content: Text(text),
      action: SnackBarAction(
        label: "Dismiss", 
        onPressed: ScaffoldMessenger.of(context).hideCurrentSnackBar
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack_bar);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: isCreating?
      createTagMenu()
      :
      IconButton(
        onPressed: button_toggleCreateTag, 
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget createTagMenu() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Table(
            columnWidths: {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              InputRow("Tag Name : ", "Enter Tag Name", tag_name_controller),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: button_createTag,
                child: Text("Submit"),
              ),
              TextButton(
                onPressed: button_toggleCreateTag, 
                child: Text("Cancel"),
              ),
            ],
          ),
        ],
      )
    );
  }
  TableRow InputRow(String label, String place_holder, TextEditingController controller) {
    return TableRow(
      children: [
        Text(label),
        SizedBox(
          height: 40,
          child: TextFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: place_holder,
            ),
            controller: controller,
          ),
        ),
      ]
    );
  }
}