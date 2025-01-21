import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';

class BackgroundImagePage extends StatefulWidget {
  const BackgroundImagePage({super.key});

  @override
  State<BackgroundImagePage> createState() => _BackgroundImagePageState();
}
class _BackgroundImagePageState extends State<BackgroundImagePage> {
  String folder_path = "";
  List<String> imagePathList = [];

  Future<void> button_onAddImage() async {
    // 1. Pick Image
    final image_picker = ImagePicker();
    final XFile? picked_file = await image_picker.pickImage(source: ImageSource.gallery);
    if (picked_file == null) return;

    // 2. Copy image to dir & update settings
    final String new_path = "$folder_path/bg_${Random().nextInt(10000000)}.${picked_file.path.split(".").last}";
    final File cache_file = File(picked_file.path);
    await cache_file.copy(new_path);

    imagePathList.add(new_path);
    settings_manager.setSetting(Settings.bgImagePaths, imagePathList);
    settings_manager.updateJsonFile();
    setState(() {});
  }
  Future<void> button_onRemoveImage(String imagePath) async {
    final File imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      alert(context, "The image you are trying to delete does not exist?\n(This shouldn't happen)");
      return;
    }

    await imageFile.delete();
    imagePathList.remove(imagePath);
    settings_manager.setSetting(Settings.bgImagePaths, imagePathList);
    settings_manager.updateJsonFile();
    setState(() {});
  }

  Future<void> init() async {
    final String tmp_path = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      imagePathList = settings_manager.getSetting(Settings.bgImagePaths);
      folder_path = tmp_path;
    });
  }

  @override
  void initState() {
    init();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Background Images", 
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: [
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Background Images : ", textScaler: TextScaler.linear(1.5)),
                Wrap(
                  children: [
                    ...imagePathList.map((imagePath) => _imageCard(imagePath: imagePath))
                  ],
                ),
                _addImageButton()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageCard({ required String imagePath }) {
    return AppCard(
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image(
            height: 128,
            image: FileImage(File(imagePath)),
          ),
          Text(imagePath.split("/").last),
          IconButton(
            onPressed: () => button_onRemoveImage(imagePath),
            icon: Icon(Icons.cancel),
          )
        ],
      ),
    );
  }
  Widget _addImageButton() {
    return TextButton(
      onPressed: button_onAddImage, 
      child: const Wrap(
        children: [
          Icon(Icons.add),
          Text("Add Image")
        ],
      )
    );
  }
}