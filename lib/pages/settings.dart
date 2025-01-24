import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:song_player/code/database.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/pages/bg_images.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';
import 'package:song_player/widgets/RoundDropdown.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  bool changed = false;
  Map<Settings, dynamic> values = {};
  Map<Settings, String> image_paths = {};

  Color pickedColor = const Color(0xff443a49);

  Future<void> button_applyChange() async {
    values[Settings.interfaceColor] = [(pickedColor.r*255).toInt(), (pickedColor.g*255).toInt(), (pickedColor.b*255).toInt(), (pickedColor.a*255).toInt()];
    for (final entry in values.entries) {
      settings_manager.setSetting(entry.key, entry.value);
    }

    final folder_path = (await getApplicationDocumentsDirectory()).path;
    for (final entry in image_paths.entries) {
      final String old_path = settings_manager.getSetting(entry.key);
      if (old_path != "") {
        await File(old_path).delete();
      }

      if (entry.value != "") {
        final file = File(entry.value);

        final String new_path = "$folder_path/${entry.key.name}_${Random().nextInt(10000000)}.${entry.value.split(".").last}";
        await file.copy(new_path);
        settings_manager.setSetting(entry.key, new_path);
      } else {
        settings_manager.setSetting(entry.key, "");
      }
    }

    settings_manager.updateJsonFile();
    setState(() {
      changed = false;
    });
  }
  void button_resetChange() {
    initValues();
    setState(() {
      changed = false;
    });
  }
  Future<void> button_pickImage(Settings setting) async {
    final image_picker = ImagePicker();
    final XFile? picked_file = await image_picker.pickImage(source: ImageSource.gallery);

    if (picked_file == null) return;

    image_paths[setting] = picked_file.path;
    setState(() {
      changed = true;
    });
  }
  void button_removeImage(Settings setting) {
    image_paths[setting] = "";
    setState(() {
      changed = true;
    });
  }
  Future<void> button_importDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    if (!file.path.endsWith(".db")) {
      if (mounted) alert(context, "Please provide a file that ends with .db");
      return;
    }
    
    await db.importDatabase(file);
    if (mounted) alert(context, "Database Imported !");
  }
  void button_exportFiles() {
    confirm(context, 
      "Confirm Export", 
      "Are you sure you want to export the database file?\n(The files will be exported to /Download)", 
      () async {
        await db.exportDatabase();
        if (mounted) alert(context, "Database Exported!");
      }, 
      () => {}
    );
  }
  void button_onSelectImage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BackgroundImagePage())
    );
  }

  void onColorChange(Color color) {
    setState(() { 
      pickedColor = color;
      changed = true;
    });
  }
  void setPickerColor(List<int> arr) {
    pickedColor = Color.fromARGB(arr[3], arr[0], arr[1], arr[2]);
  }

  void initValues() {
    values[Settings.playlistBufferLength] = settings_manager.getSetting(Settings.playlistBufferLength);
    values[Settings.maxQueueLength] = settings_manager.getSetting(Settings.maxQueueLength);
    values[Settings.interfaceColor] = settings_manager.getSetting(Settings.interfaceColor).cast<int>();
    values[Settings.isDarkMode] = settings_manager.getSetting(Settings.isDarkMode);
    values[Settings.containerOpacity] = settings_manager.getSetting(Settings.containerOpacity);
    values[Settings.backgroundImageBrightness] = settings_manager.getSetting(Settings.backgroundImageBrightness);
    values[Settings.noRepeatFor] = settings_manager.getSetting(Settings.noRepeatFor);
    setPickerColor(values[Settings.interfaceColor]);
  }

  @override 
  void initState() {
    initValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      pageName: "Settings", 
      pageIcon: Icons.settings,
      page: Pages.settingsPage,
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          ListView(
            children: [
              DropDownInput("Playlist Buffer Length", Settings.playlistBufferLength, [5, 10, 20, 30]),
              DropDownInput("Queue Max Length", Settings.maxQueueLength, [50, 100, 200, 300, -1]),
              DropDownInput("No Repeat Song For", Settings.noRepeatFor, [0, 1, 2, 5, 10, 20]),
              _UIColorPicker(pickedColor: pickedColor, onColorChange: onColorChange),
              SliderInput("Container Opacity", Settings.containerOpacity, 0, 255, true),
              SliderInput("Background Brightness", Settings.backgroundImageBrightness, 0, 1, false),
              UIBrightnessPicker(),
              BGImageSelect(),
              ImportDatabase(),
              ExportFiles()
            ],
          ),
          if (changed) Align(
            alignment: Alignment.bottomCenter,
            child: ApplyChangeButtons(),
          ),
        ],
      )
    );
  }
  Widget DropDownInput(String label, Settings setting, List<int> options) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label : "),
            RoundDropDown(
              color: Theme.of(context).colorScheme.secondaryContainer,
              options: options.map((option) => (option == -1)?"None":option.toString()).toList(), 
              value: values[setting].toString(), 
              onChanged: (value) {
                if (value == null) return;
                changed = true;
                values[setting] = (value == "None")?-1:int.parse(value);
                setState(() {});
              }
            ),
          ],
        ),
      ),
    );
  }
  Widget SliderInput(String label, Settings setting, int min, int max, bool is_int) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$label : "),
          Text(values[setting].toString()),
          Flexible(
            child: Slider(
              min: min.toDouble(),
              max: max.toDouble(),
              value: is_int?values[setting].toDouble():values[setting],
              onChanged: (value) => {
                setState(() {
                  values[setting] = is_int?value.toInt():(value*100).floor()/100;
                })
              },
              onChangeEnd: (_) {
                setState(() {
                  changed = true;
                });
              },
            ),
          ),
          Text(max.toString()),
        ],
      ),
    );
  }
  Widget UIBrightnessPicker() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Text("Dark Mode : "),
            Switch(
              value: values[Settings.isDarkMode], 
              onChanged: (new_value) {
                setState(() {
                  values[Settings.isDarkMode] = new_value;
                  changed = true;
                });
              },
            )
          ],
        ),
      ),
    );
  }
  Widget ApplyChangeButtons() {
    return AppCard(
      child: Wrap(
        children: [
          TextButton(
            onPressed: button_applyChange, 
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
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
              color: Theme.of(context).colorScheme.secondaryContainer,
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
      ),
    );
  }
  Widget BGImageSelect() {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Background Images : "),
          AppCard(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: TextButton(
              onPressed: button_onSelectImage, 
              child: const Text("Add / Remove Images")
            ),
          )
        ],
      ),
    );
  }
  Widget ImportDatabase() {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Import Database File :"),
          AppCard( 
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: TextButton(
              onPressed: button_importDatabase, 
              child: const Text("Click to Import Database")
            ),
          )
        ],
      ),
    );
  }
  Widget ExportFiles() {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Export Database & Settings File :"),
          AppCard( 
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: TextButton(
              onPressed: button_exportFiles, 
              child: const Text("Click to Export Files")
            ),
          )
        ],
      ),
    );
  }
}
class _UIColorPicker extends StatefulWidget {
  final Color pickedColor;
  final void Function(Color) onColorChange;
  
  const _UIColorPicker({required this.pickedColor, required this.onColorChange});

  @override
  State<_UIColorPicker> createState() => _UIColorPickerState();
}
class _UIColorPickerState extends State<_UIColorPicker> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("UI Theme Color : "),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (!expanded) Container(
                        width: 128,
                        height: 48,
                        color: widget.pickedColor,
                      ),
                      const SizedBox(width: 16),
                      Icon(expanded?Icons.keyboard_arrow_up:Icons.keyboard_arrow_down),
                    ],
                  )
                ],
              ),
            ),
          ),
          if (expanded) ColorPicker(
            pickerColor: widget.pickedColor, 
            onColorChanged: widget.onColorChange
          )
        ],
      ),
    );
  }
}