import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/main.dart';
import 'package:song_player/widgets/RoundDropdown.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}
class _PlaylistPageState extends State<PlaylistPage> {
  List<Playlist> playlist_list = [];

  static const List<String> playlistTypes = ["Empty Playlist", "Filter Playlist"]; 
  bool is_creatingPlaylist = false;
  int create_playlist_type = 0;

  void button_onCreatePlaylist() {
    setState(() {
      is_creatingPlaylist = true;
    });
  }
  void button_onCancelCreate() {
    setState(() {
      is_creatingPlaylist = false;
    });
  }

  Future<void> initPlaylistList() async {
    List<Playlist> tmp = await db.getAllPlaylists(SortingStyle.nameAsc);
    setState(() {
      playlist_list = tmp;
    });
  }

  @override
  void initState() {
    initPlaylistList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Playlists", 
      child: Container(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            ...playlist_list.map((playlist) => playlistCard(playlist)),
            if (is_creatingPlaylist) ...createPlaylistMenu() else createPlaylistButton(),
          ],
        ),
      ),
    );
  }

  Widget playlistCard(Playlist playlist) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(playlist.playlist_name),
        subtitle: Text("Song Count : ${playlist.song_id_list.length}"),
      ),
    );
  }

  // For creating new playlist
  Widget createPlaylistButton() {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SizedBox(
        width: 64,
        height: 64,
        child: IconButton(
          onPressed: button_onCreatePlaylist, 
          icon: Icon(Icons.add),
        ),
      )
    );
  }
  List<Widget> createPlaylistMenu() {
    return [
      Card(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create New Playlist",
                textScaler: TextScaler.linear(1.5),
              ),
              playlistTypeInput(),
            ],
          ),
        ),
      ),
      createPlaylistMenuTypes(),
    ];
  }
  Widget createPlaylistMenuTypes() {
    switch(create_playlist_type) {
      case 0: return EmptyPlaylistMenu(onCancel: button_onCancelCreate);
      case 1: return FilteredPlaylistMenu(onCancel: button_onCancelCreate);
      default: return Container();
    }
  }
  Widget playlistTypeInput() {
    return Row(
      children: [
        const Text("Playlist Type : "),
        DropdownButton(
          value: playlistTypes[create_playlist_type],
          items: [
            ...playlistTypes.map((playlist_type) => DropdownMenuItem<String>(
              value: playlist_type,
              child: Text(playlist_type),
            ))
          ],
          onChanged: (value) => setState(() {
            if (value == null) return;
            create_playlist_type = playlistTypes.indexOf(value);
          }),
        )
      ],
    );
  }
}

class EmptyPlaylistMenu extends StatefulWidget {
  final VoidCallback onCancel;
  const EmptyPlaylistMenu({super.key, required this.onCancel});

  @override
  State<EmptyPlaylistMenu> createState() => _EmptyPlaylistMenuState();
}
class _EmptyPlaylistMenuState extends State<EmptyPlaylistMenu> {
  final TextEditingController playlist_name_controller = TextEditingController();

  Future<void> button_onCreatePlaylist() async {
    if (playlist_name_controller.text.isEmpty) {
      if (mounted) alert(context, "Please Enter a valid playlist name");
      return;
    }

    if (!await db.createRegularPlaylist(playlist_name_controller.text, [])) {// todo
      if (mounted) alert(context, "Something went wrong while adding playlist to database.");
      return;
    }

    if (mounted) alert(context, "Playlist \"${playlist_name_controller.text}\" Created!");
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            playlistNameInput(),
            createCancelButtonSet()
          ],
        ),
      ),
    );
  }
  
  Widget playlistNameInput() {
    return Row(
      children: [
        Text("Playlist Name : "),
        SizedBox(
          width: 256,
          height: 40,
          child: TextFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Enter Name Here",
            ),
            controller: playlist_name_controller,
          ),
        ),
      ],
    );
  }
  Widget createCancelButtonSet() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: button_onCreatePlaylist,
          child: const Text("Create")
        ),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text("Cancel")
        ),
      ],
    );
  }
}


class ConditionInput {
  int condition;
  int value;
  ConditionInput(this.condition, this.value);
  @override
  String toString() {
    return "ConditionInput{condition : $condition, value: $value}";
  }
}
class Condition {
  final String name;
  final ConditionTypes type;
  Condition(this.name, this.type);
}
enum ConditionTypes {tags}
final List<Condition> conditions = [ // todo : "hasAuthor", "withoutAuthor"
  Condition("hasTag", ConditionTypes.tags), 
  Condition("withoutTag", ConditionTypes.tags)
];

class FilteredPlaylistMenu extends StatefulWidget {
  final VoidCallback onCancel;
  const FilteredPlaylistMenu({super.key, required this.onCancel});

  @override
  State<FilteredPlaylistMenu> createState() => _FilteredPlaylistMenuState();
}
class _FilteredPlaylistMenuState extends State<FilteredPlaylistMenu> {
  static const List<String> operators = ["And", "Or"];
  List<Tag> tag_list = [];

  List<List<ConditionInput>> condition_list = [];
  List<List<int>> inner_operator_list = [];
  List<int> outer_operator_list = [];
  TextEditingController playlist_name_controller = TextEditingController();

  void button_addConditionSet() {
    setState(() {
      if (condition_list.isNotEmpty) outer_operator_list.add(0);
      condition_list.add([ConditionInput(0, -1)]);
      inner_operator_list.add([]);
    });
  }
  void button_addCondition(int index) {
    setState(() {
      condition_list[index].add(ConditionInput(0, -1));
      inner_operator_list[index].add(0);
    });
  }
  Future<void> button_onCreatePlaylist() async {
    if (playlist_name_controller.text.isEmpty) {
      if (mounted) alert(context, "Please Enter a valid playlist name");
      return;
    }
    // todo : check if conditions are empty/valid

    if (!await db.createFilterPlaylist(playlist_name_controller.text, condition_list, outer_operator_list, inner_operator_list)) {// todo
      if (mounted) alert(context, "Something went wrong while adding playlist to database.");
      return;
    }

    if (mounted) alert(context, "Filtered Playlist \"${playlist_name_controller.text}\" Created!");
    widget.onCancel();
  }

  Future<void> initTagList() async {
    final List<Tag> tmp = await db.getAllTags();
    setState(() {
      tag_list = tmp;
      print(tmp);
    });
  }
  
  @override
  void initState() {
    initTagList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            playlistNameInput(),
            for (int i = 0; i < 2*condition_list.length-1; i++) (i%2 == 0)?outerConditionMenu(i~/2):outerOperatorInputCard(i~/2),
            addConditionSetButton(),
            createCancelButtonSet()
          ],
        ),
      ),
    );
  }

  Widget playlistNameInput() {
    return Row(
      children: [
        Text("Playlist Name : "),
        SizedBox(
          width: 256,
          height: 40,
          child: TextFormField(
            textAlignVertical: TextAlignVertical(y: -1),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Enter Name Here",
            ),
            controller: playlist_name_controller,
          ),
        ),
      ],
    );
  }
  Widget createCancelButtonSet() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: button_onCreatePlaylist,
          child: const Text("Create")
        ),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text("Cancel")
        ),
      ],
    );
  }
  
  Widget addConditionSetButton() {
    return TextButton(
      onPressed: button_addConditionSet, 
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add),
            Text("Add Condition Set")
          ],
        ),
      ),
    );
  }
  Widget addConditionButton(int index) {
    return TextButton(
      onPressed: () => button_addCondition(index), 
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add),
            Text("Add Condition")
          ],
        ),
      ),
    );
  }

  Widget outerConditionMenu(int index) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryFixed,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Condition Set ${index+1} : "),
            if (condition_list[index].length == 1) conditionInputRow(index, 0)
            else for (int i = 0; i < 2*condition_list[index].length-1; i++) (i%2 == 0)?innerConditionMenu(index, i~/2):innerOperatorInputCard(index, i~/2),
            addConditionButton(index),
          ],
        ),
      )
    );
  }
  Widget innerConditionMenu(int index_1, int index_2) {
    return Card(
      color: Theme.of(context).colorScheme.primaryFixed,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: conditionInputRow(index_1, index_2)
      ),
    );
  }
  Widget conditionInputRow(int index_1, int index_2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RoundDropDown(
          options: conditions.map((condition) => condition.name).toList(), 
          value: conditions[condition_list[index_1][index_2].condition].name, 
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              condition_list[index_1][index_2].condition = conditions.map((condition) => condition.name).toList().indexOf(value);
            });
          }
        ),
        const Text(
          ":",
          textScaler: TextScaler.linear(1.5),
        ),
        conditionTypeInput(conditions[condition_list[index_1][index_2].condition].type, index_1, index_2),
      ],
    );
  }
  Widget conditionTypeInput(ConditionTypes type, int index_1, int index_2) {
    switch (type) {
      case ConditionTypes.tags: 
        return RoundDropDown(
          options: tag_list.map((tag) => tag.tag_name).toList(), 
          value: (condition_list[index_1][index_2].value == -1)?null:tag_list.firstWhere((tag) => tag.tag_id == condition_list[index_1][index_2].value).tag_name,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              condition_list[index_1][index_2].value = tag_list.firstWhere((tag) => tag.tag_name == value).tag_id;
            });
          }
        );
      default: return Container();
    }
  }
  Widget outerOperatorInputCard(int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: RoundDropDown(
        options: operators, 
        value: operators[outer_operator_list[index]], 
        color: Theme.of(context).colorScheme.secondaryContainer,
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            outer_operator_list[index] = operators.indexOf(value);
          });
        }
      ),
    );
  }
  Widget innerOperatorInputCard(int index_1, int index_2) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: RoundDropDown(
        options: operators, 
        value: operators[inner_operator_list[index_1][index_2]], 
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            inner_operator_list[index_1][index_2] = operators.indexOf(value);
          });
        }
      ),
    );
  }
}