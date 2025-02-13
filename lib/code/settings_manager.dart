import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

late SettingsManager settings_manager;

Future<void> initSettingsManager() async {
	settings_manager = SettingsManager();
	await settings_manager.initSettings();
}

enum Settings {
	playlistBufferLength(0),
	maxQueueLength(1),
	interfaceColor(2),
	isDarkMode(3),
	containerOpacity(4),
	backgroundImageBrightness(5),
	bgImagePaths(6),
	noRepeatFor(7);

	const Settings(this.value);
	final int value;
}

class SettingsManager {
	Map<int, dynamic> values = {};
	Map<int, ValueNotifier> notifiers = {};
	late File json_file;

	void useDefaultSettings() {
		values[Settings.playlistBufferLength.value] = 10;
		values[Settings.maxQueueLength.value] = 100;
		values[Settings.interfaceColor.value] = [255, 202, 248, 255]; // RGBA
		values[Settings.isDarkMode.value] = false;
		values[Settings.containerOpacity.value] = 200;
		values[Settings.backgroundImageBrightness.value] = 1.0;
		values[Settings.bgImagePaths.value] = [].cast<String>();
		values[Settings.noRepeatFor.value] = 0;
	}
	void constructNotifiers() {
		for (final entry in values.entries) {
			notifiers[entry.key] = ValueNotifier(entry.value);
		}
	}

	Future<void> initSettings() async {
		final Directory dir = await getApplicationDocumentsDirectory();
		json_file = File("${dir.path}/settings.json");

		if (!json_file.existsSync()) {
			useDefaultSettings();
			constructNotifiers();
			updateJsonFile();
			return;
		}
		getFromJsonFile();
		constructNotifiers();
	}

	dynamic getSetting(Settings key) {
		return values[key.value];
	}
	void setSetting(Settings key, dynamic value) {
		if (values[key.value] != value) {
			values[key.value] = value;
			notifiers[key.value]?.value = value; 
		}
	}
	void getFromJsonFile() {
		List<dynamic> tmp = jsonDecode(json_file.readAsStringSync());
		for (int i = 0; i < Settings.values.length; i++) {
			values[i] = tmp[i];
		}
	}
	void updateJsonFile() {
		List<dynamic> tmp = List.filled(Settings.values.length, -1);
		for (final entry in values.entries) {
			tmp[entry.key] = entry.value;
		}
		json_file.writeAsStringSync(jsonEncode(tmp));
	}
}