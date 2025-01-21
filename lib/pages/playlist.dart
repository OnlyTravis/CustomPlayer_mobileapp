import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/pages/view_playlist.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';
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

  Future<void> initPlaylistList() async {
    List<Playlist> tmp = await db.getAllPlaylists(sort: SortingStyle.nameAsc);
    setState(() {
      playlist_list = tmp;
    });
  }

  @override
  void initState() {
    initPlaylistList();
    super.initState();
  }

  void button_onCreatePlaylist() {
    setState(() {
      is_creatingPlaylist = true;
    });
  }
  void button_onCancelCreate() {
    setState(() {
      is_creatingPlaylist = false;
    });
    initPlaylistList();
  }
  void button_viewPlaylist(Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ViewPlaylistPage(playlist: playlist))
    );
  }
  Future<void> button_onPlayPlaylist(Playlist playlist) async {
    await audio_handler.playPlaylist(playlist);
  }
  Future<void> button_onStopPlaylist() async {
    await audio_handler.stopPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      pageName: "Playlists", 
      pageIcon: Icons.queue_music,
      page: Pages.settingsPage,
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          ...playlist_list.map((playlist) => playlistCard(playlist)),
          if (is_creatingPlaylist) ...createPlaylistMenu() else createPlaylistButton(),
        ],
      ),
    );
  }

  Widget playlistCard(Playlist playlist) {
    bool is_playing = (audio_handler.is_playing_playlist && (audio_handler.playing_playlist.playlist_id == playlist.playlist_id));
    return GestureDetector(
      onTap: () => button_viewPlaylist(playlist),
      child: AppCard(
        child: ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(playlist.playlist_name),
          subtitle: Text("Song Count : ${playlist.song_id_list.length}"),
          trailing: Wrap(
            children: [
              IconButton(
                onPressed: () => is_playing?button_onStopPlaylist():button_onPlayPlaylist(playlist),
                icon: Icon(is_playing?Icons.pause:Icons.play_arrow)
              ),
            ],
          ),
        ),
      ),
    );
  }

  // For creating new playlist
  Widget createPlaylistButton() {
    return AppCard(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SizedBox(
        width: 64,
        height: 64,
        child: IconButton(
          onPressed: button_onCreatePlaylist, 
          icon: const Icon(Icons.add),
        ),
      )
    );
  }
  List<Widget> createPlaylistMenu() {
    return [
      AppCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Playlist",
              textScaler: TextScaler.linear(1.5),
            ),
            playlistTypeInput(),
          ],
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
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
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
        const Text("Playlist Name : "),
        SizedBox(
          width: 256,
          height: 40,
          child: TextFormField(
            decoration: const InputDecoration(
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
  void button_removeConditionSet(int index) {
    setState(() {
      if (index == condition_list.length-1) {
        if (index != 0) {
          outer_operator_list.removeAt(index-1);
        }
      } else {
        outer_operator_list.removeAt(index);
      }
      condition_list.removeAt(index);
      inner_operator_list.removeAt(index);
    });
  }
  void button_addCondition(int index) {
    setState(() {
      condition_list[index].add(ConditionInput(0, -1));
      inner_operator_list[index].add(0);
    });
  }
  void button_removeCondition(int index_1, int index_2) {
    setState(() {
      if (index_2 == condition_list[index_1].length-1) {
        inner_operator_list[index_1].removeAt(index_2-1);
      } else {
        inner_operator_list[index_1].removeAt(index_2);
      }
      condition_list[index_1].removeAt(index_2);

      if (condition_list[index_1].isEmpty) {
        condition_list.removeAt(index_1);
      }
    });
  }
  Future<void> button_onCreatePlaylist() async {
    if (playlist_name_controller.text.isEmpty) {
      if (mounted) alert(context, "Please Enter a valid playlist name");
      return;
    }
    
    for (final list in condition_list) {
      for (final condition in list) {
        if (condition.value == -1) {
          if (mounted) alert(context, "Atleast one condition is not valid");
          return;
        }
      }
    }

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
    });
  }
  
  @override
  void initState() {
    initTagList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          playlistNameInput(),
          for (int i = 0; i < 2*condition_list.length-1; i++) (i%2 == 0)?outerConditionMenu(i~/2):outerOperatorInputCard(i~/2),
          addConditionSetButton(),
          createCancelButtonSet()
        ],
      ),
    );
  }

  Widget playlistNameInput() {
    return Row(
      children: [
        const Text("Playlist Name : "),
        SizedBox(
          width: 256,
          height: 40,
          child: TextFormField(
            textAlignVertical: const TextAlignVertical(y: -1),
            decoration: const InputDecoration(
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: const Row(
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        child: const Row(
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
    return AppCard(
      color: Theme.of(context).colorScheme.secondaryFixed,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Condition Set ${index+1} : "),
                if (condition_list[index].length == 1) conditionInputRow(index, 0)
                else for (int i = 0; i < 2*condition_list[index].length-1; i++) (i%2 == 0)?innerConditionMenu(index, i~/2):innerOperatorInputCard(index, i~/2),
                addConditionButton(index),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => button_removeConditionSet(index), 
              icon: const Icon(Icons.cancel)
            ),
          )
        ],
      )
    );
  }
  Widget innerConditionMenu(int index_1, int index_2) {
    return Stack(
      children: [
        AppCard(
          color: Theme.of(context).colorScheme.primaryFixed,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Condition ${index_2+1} : "),
              conditionInputRow(index_1, index_2)
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () => button_removeCondition(index_1, index_2), 
            icon: const Icon(Icons.cancel)
          ),
        )
      ],
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