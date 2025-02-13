import 'dart:io';
import 'dart:math';

import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/widgets/NavigationBar.dart';
import 'package:video_player/video_player.dart';

enum Pages {
	otherPage, 
	songListPage,
	playerPage,
	queuePage,
	playlistPage,
	tagsPage,
	settingsPage,
}

class AppNavigationWrap extends StatefulWidget {
	final Widget child;
	final String pageName;
	final Pages page;
	final Widget? pageIcon;
	final EdgeInsetsGeometry? padding;
	final List<Widget> actions;
	final bool pipOnLeave;

	const AppNavigationWrap({
		super.key, 
		required this.pageName, 
		this.page = Pages.otherPage, 
		this.pageIcon, 
		this.padding, 
		this.actions = const [], 
		this.pipOnLeave = false,
		required this.child
	});

	@override
	State<StatefulWidget> createState() => _AppNavigationWrapState();
}
class _AppNavigationWrapState extends State<AppNavigationWrap> {
	String imageBackgroundPath = "";
	double backgroundBrightness = 1;

	String getBackgroundImagePath() {
		final List<String> imageList = settings_manager.getSetting(Settings.bgImagePaths).cast<String>();
		if (imageList.isEmpty) return "";

		return imageList[Random().nextInt(imageList.length)];
	}

	@override
	void initState() {
		settings_manager.notifiers[Settings.backgroundImageBrightness.value]?.addListener(onBGBrightnessChange);
		settings_manager.notifiers[Settings.bgImagePaths.value]?.addListener(onBGChange);

		setState(() {
			imageBackgroundPath = getBackgroundImagePath();
			backgroundBrightness = settings_manager.getSetting(Settings.backgroundImageBrightness);
		});
		super.initState();
	}

	void onBGBrightnessChange() {
		setState(() {
			backgroundBrightness = settings_manager.getSetting(Settings.backgroundImageBrightness);
		});
	}
	void onBGChange() {
		final List<dynamic> list = settings_manager.getSetting(Settings.bgImagePaths);

		if (list.isEmpty || list.length == 1) {
			setState(() {
				imageBackgroundPath = getBackgroundImagePath();
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return widget.pipOnLeave ? PiPSwitcher(
			childWhenDisabled: mainScaffold(), 
			childWhenEnabled: Center(
				child: audio_handler.is_playing_video ? AspectRatio(
						aspectRatio: audio_handler.video_controller.value.aspectRatio,
						child: VideoPlayer(audio_handler.video_controller),
				) : AspectRatio(
					aspectRatio: 4/3,
					child: Container(
						color: const Color.fromARGB(255, 86, 86, 86),
						child: const Center(
							child: Icon(
								Icons.music_note,
								size: 32,
							),
						),
					),
				),
			),
		) : mainScaffold();
	}
	Widget mainScaffold() {
		return Scaffold(
			appBar: AppBar(
				backgroundColor: Theme.of(context).colorScheme.primaryContainer,
				leading: widget.pageIcon,
				title: Text(widget.pageName),
				actions: widget.actions,
			),
			body: Column(
				children: [
					Expanded(
						child: Container(
							padding: widget.padding,
							width: double.infinity,
							decoration: imageBackgroundPath.isNotEmpty?BoxDecoration(
								color: Colors.black,
								image: DecorationImage(
									opacity: backgroundBrightness,
									image: FileImage(File(imageBackgroundPath)),
									fit: BoxFit.cover,
								),
							):null,
							child: widget.child,
						)
					),
					const CommonNavigationBar()
				]
			),
		);
	}

	@override
	void dispose() {
		settings_manager.notifiers[Settings.backgroundImageBrightness.value]?.removeListener(onBGBrightnessChange);
		settings_manager.notifiers[Settings.bgImagePaths.value]?.removeListener(onBGChange);
		super.dispose();
	}
}