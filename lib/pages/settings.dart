import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/code/utils.dart';
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

  Color picker_color = const Color(0xff443a49);

  Future<void> button_applyChange() async {
    values[Settings.interfaceColor] = [(picker_color.r*255).toInt(), (picker_color.g*255).toInt(), (picker_color.b*255).toInt(), (picker_color.a*255).toInt()];
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
  void button_exportFiles() {
    confirm(context
      , "Confirm Export", "Are you sure you want to export the database & settings file?\n(The files will be exported to /Music)"
      , () async {
        await db.exportDatabase();
        if (mounted) alert(context, "Database & Settings Exported!");
      }
      , () => {}
    );
  }

  void setPickerColor(List<int> arr) {
    picker_color = Color.fromARGB(arr[3], arr[0], arr[1], arr[2]);
  }

  void initValues() {
    values[Settings.playlistBufferLength] = settings_manager.getSetting(Settings.playlistBufferLength);
    values[Settings.maxQueueLength] = settings_manager.getSetting(Settings.maxQueueLength);
    values[Settings.interfaceColor] = settings_manager.getSetting(Settings.interfaceColor).cast<int>();
    values[Settings.isDarkMode] = settings_manager.getSetting(Settings.isDarkMode);
    values[Settings.containerOpacity] = settings_manager.getSetting(Settings.containerOpacity);
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
      page_name: "Settings", 
      page: Pages.settingsPage,
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          ListView(
            children: [
              DropDownInput("Playlist Buffer Length", Settings.playlistBufferLength, [5, 10, 20, 30]),
              DropDownInput("Queue Max Length", Settings.maxQueueLength, [50, 100, 200, 300, -1]),
              UIColorPicker(),
              SliderInput("Container Opacity", Settings.containerOpacity, 0, 255),
              UIBrightnessPicker(),
              BGImageSelect("Default BG Image", Settings.defaultImagePath),
              BGImageSelect("Song List Page BG Image", Settings.songListImagePath),
              BGImageSelect("Player Page BG Image", Settings.playerImagePath),
              BGImageSelect("Queue Page BG Image", Settings.queueImagePath),
              BGImageSelect("Playlist Page BG Image", Settings.playlistImagePath),
              BGImageSelect("Tags Page BG Image", Settings.tagImagePath),
              BGImageSelect("Settings Page BG Image", Settings.settingImagePath),
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
  Widget SliderInput(String label, Settings setting, int min, int max) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$label : "),
          Text(values[Settings.containerOpacity].toString()),
          SizedBox(
            width: 175,
            child: Slider(
              min: min.toDouble(),
              max: max.toDouble(),
              value: values[Settings.containerOpacity].toDouble(),
              onChanged: (value) => {
                setState(() {
                  values[Settings.containerOpacity] = value.toInt();
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
  Widget UIColorPicker() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("UI Theme Color : "),
            ColorPicker(
              pickerColor: picker_color, 
              onColorChanged: (Color color) {
                setState(() { 
                  picker_color = color;
                  changed = true;
                });
              }
            )
          ],
        ),
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
  Widget BGImageSelect(String label, Settings setting) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text("$label : "),
          AppCard(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: TextButton(
              onPressed: () => button_pickImage(setting),
              child: const Text("Select Image"),
            ),
          ),
          if (settings_manager.getSetting(setting) != "") AppCard(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: IconButton(
              onPressed: () => button_removeImage(setting),
              icon: const Icon(Icons.cancel),
            ),
          ),
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