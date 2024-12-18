import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';

import 'package:song_player/code/permission.dart';

late MusicHandler audio_handler;
final List<String> accepted_formats = [".m4a", ".mp3", ".mp4"];

Future<void> initAudioHandler() async {
  audio_handler = await AudioService.init(
    builder: () => MusicHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio playback',
    ),
  );
}

class MusicHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer audio_player = AudioPlayer();

  final playlist = ConcatenatingAudioSource(children: []);
  String music_folder_path = "";
  List<String> song_file_list = [];

  MusicHandler() {
    audio_player.setAudioSource(playlist);

    updateSongList();

    _listenForDurationChanges();
    audio_player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  Future<void> updateSongList() async {
    // 1. Get Permission for song files
    if (!await requestPermission(Permission.manageExternalStorage)) return;

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
    music_folder_path = folder_path;

    // 3. Fetch files inside the folder
    List<String> file_list = Directory(folder_path)
      .listSync(recursive: true)
      .where((obj) => isMediaFile(obj.path))
      .map((obj) => obj.path.substring(folder_path.length+1))
      .toList();
    song_file_list = file_list;
  }

  bool isMediaFile(String file_path) {
    for (final format in accepted_formats) {
      if (file_path.endsWith(format)) return true;
    }
    return false;
  }

  MediaItem toMediaItem(UriAudioSource audio_source, String file_name) {
    return MediaItem(
      id: file_name, 
      title: file_name.split(".")[0],
    );
  }

  Future<void> replaceCurrentSong(String file_name) async {
    final UriAudioSource audio_source = AudioSource.file("$music_folder_path/$file_name");
    playlist.add(audio_source);

    //final newQueue = queue.value..removeAt(0)..insert(0, toMediaItem(file_name));
    queue.add([toMediaItem(audio_source, file_name)]);
    queue.add(queue.value);

    await audio_player.play();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (audio_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[audio_player.processingState]!,
      playing: audio_player.playing,
      updatePosition: audio_player.position,
      bufferedPosition: audio_player.bufferedPosition,
      speed: audio_player.speed,
      queueIndex: event.currentIndex,
    );
  }

  void _listenForDurationChanges() {
    audio_player.durationStream.listen((duration) {
      final index = audio_player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  @override Future<void> play() => audio_player.play();
  @override Future<void> pause() => audio_player.pause();
  @override Future<void> seek(Duration position) => audio_player.seek(position);
  @override Future<void> stop() => audio_player.stop();
}

Stream<MediaState> get mediaStateStream =>
  Rx.combineLatest2<MediaItem?, Duration, MediaState>(
    audio_handler.mediaItem,
    AudioService.position,
    (mediaItem, position) => MediaState(mediaItem, position)
  );

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}