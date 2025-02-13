import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/permission.dart';

class FileEntity {
	String file_name;
	String file_directory;
	FileType file_type;

	FileEntity(this.file_name, this.file_directory, this.file_type);

	String getFullPath() {
		return file_directory+file_name;
	}
	String getFileName() {
		final arr = file_name.split(".");
		arr.removeLast();
		return arr.join(".");
	}

	@override
	String toString() {
		return 'FileEntity{file_name : "$file_name", file_directory = "$file_directory", file_type = "$file_type"}';
	}
}
enum FileType {audio, video, folder}


late FileHandler file_handler;
Future<void> initFileHandler() async {
	file_handler = FileHandler();
	await file_handler.initFileHandler();
}

class FileHandler {
	static const List<String> acceptedFormats = [".m4a", ".mp3", ".mp4"];
	static const List<FileType> respectiveFileType = [FileType.audio, FileType.audio, FileType.video];

	String root_folder_path = "";
	List<FileEntity> file_list = [];

	Future<void> initFileHandler() async {
		// 1. Get Permission for song files
		if (!await requestPermission(Permission.audio)) return;
		if (!await requestPermission(Permission.videos)) return;

		// 2. Set "Music" folder directory
		String path = (await getExternalStorageDirectory())?.path ?? "";
		if (path == "") return;

		List<String> arr = path.split("/"); 
		String folder_path = "";
		for (int i = 1; i < arr.length; i++) {
			if (arr[i] == "Android") break;
			folder_path += "/${arr[i]}";
		}
		folder_path += "/Music";
		root_folder_path = folder_path;

		// 3. Fetch files & directories inside the folder
		List<FileSystemEntity> entity_list = Directory(folder_path).listSync(recursive: true);
		file_list = entity_list.where((entity) => isMediaFile(entity.path))
			.map((file) {
				final String file_name = file.path.split("/").last;
				int i;
				for (i = 0; i < acceptedFormats.length; i++) {
					if (file_name.endsWith(acceptedFormats[i])) break;
				}
				return FileEntity(file_name, file.path.substring(folder_path.length+1, file.path.length-file_name.length), respectiveFileType[i]);
			})
			.toList();
		file_list.addAll(entity_list
			.whereType<Directory>()
			.map((directory) {
				final String folder_name = directory.path.split("/").last;
				return FileEntity(folder_name, directory.path.substring(folder_path.length+1, directory.path.length-folder_name.length), FileType.folder);
			})
		);
		file_list.removeWhere((entity) => entity.file_name == ".thumbnails");

		// 4. Update song list in Database & Call update song list in audio_handler
		await db.updateSongDatabase(file_list.where((entity) => (entity.file_type == FileType.audio)||entity.file_type == FileType.video).toList());
	}

	List<FileEntity> getFilesInDirectory(String path) {
		return file_list.where((entity) => entity.file_directory == path)
			.toList()
			..sort((entity_1, entity_2) {
				if ((entity_1.file_type == FileType.folder && entity_2.file_type == FileType.folder) || (entity_1.file_type != FileType.folder && entity_2.file_type != FileType.folder)) {
					return entity_1.file_name.toLowerCase().compareTo(entity_2.file_name.toLowerCase());
				}
				return (entity_1.file_type == FileType.folder)?-1:1;
			});
	}

	bool isMediaFile(String file_path) {
		for (final format in acceptedFormats) {
			if (file_path.endsWith(format)) return true;
		}
		return false;
	}
}