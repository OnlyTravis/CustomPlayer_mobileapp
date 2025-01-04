import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/RoundDropdown.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  bool changed = false;
  Map<Settings, dynamic> values = {};

  Color picker_color = const Color(0xff443a49);

  void button_applyChange() {
    values[Settings.interfaceColor] = [(picker_color.r*255).toInt(), (picker_color.g*255).toInt(), (picker_color.b*255).toInt(), (picker_color.a*255).toInt()];
    for (final entry in values.entries) {
      settings_manager.setSetting(entry.key, entry.value);
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

  void setPickerColor(List<int> arr) {
    picker_color = Color.fromARGB(arr[3], arr[0], arr[1], arr[2]);
  }

  void initValues() {
    values[Settings.playlistBufferLength] = settings_manager.getSetting(Settings.playlistBufferLength);
    values[Settings.maxQueueLength] = settings_manager.getSetting(Settings.maxQueueLength);
    values[Settings.interfaceColor] = settings_manager.getSetting(Settings.interfaceColor).cast<int>();
    values[Settings.isDarkMode] = settings_manager.getSetting(Settings.isDarkMode);
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
      padding: EdgeInsets.all(8),
      child: ListView(
        children: [
          DropDownInput("Playlist Buffer Length", Settings.playlistBufferLength, [5, 10, 20, 30]),
          DropDownInput("Queue Max Length", Settings.maxQueueLength, [50, 100, 200, 300, -1]),
          UIColorPicker(),
          UIBrightnessPicker(),
          if (changed) ApplyChangeButtons(),
        ],
      ),
    );
  }
  Widget DropDownInput(String label, Settings setting, List<int> options) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
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
  Widget UIColorPicker() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
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
    return Card(
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
}