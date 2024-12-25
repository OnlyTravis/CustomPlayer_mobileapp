import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';

import 'package:song_player/code/permission.dart';
import 'package:song_player/code/database.dart';

late MusicHandler audio_handler;

final List<String> accepted_formats = [".m4a", ".mp3", ".mp4"];

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}


Future<void> initAudioHandler() async {
  audio_handler = await AudioService.init(
    builder: () => MusicHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MusicHandler extends BaseAudioHandler with SeekHandler {
  late VideoPlayerController video_controller;
  AudioPlayer audio_player = AudioPlayer();

  late StreamSubscription<PlaybackState> subscription;
  late StreamController<PlaybackState> streamController;
  List<Song> song_queue = [];
  int current_queue_index = 0;
  bool need_sync = false;
  bool app_opened = true;

  String music_folder_path = "";
  List<String> song_path_list = [];
  List<Song> song_list = [];

  Function? _videoPlay;
  Function? _videoPause;
  Function? _videoSeek;
  Function? _videoStop;


  /* INITS */

  MusicHandler() {
    audio_player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _listenForDurationChanges();
    _listenForSongEnd();
    updateSongList();

    video_controller = VideoPlayerController.asset("assets/a.mp4");
  }
  
  void setVideoFunctions(Function play, Function pause, Function seek, Function stop) {
    _videoPlay = play;
    _videoPause = pause;
    _videoSeek = seek;
    _videoStop = stop;
  }
  
  void initializeStreamController(VideoPlayerController? videoPlayerController) {
    bool _isPlaying() => videoPlayerController?.value.isPlaying ?? false;

    AudioProcessingState _processingState() {
      if (videoPlayerController == null) return AudioProcessingState.idle;
      if (videoPlayerController.value.isInitialized) return AudioProcessingState.ready;
      return AudioProcessingState.idle;
    }

    Duration _bufferedPosition() {
      DurationRange? currentBufferedRange = videoPlayerController?.value.buffered.firstWhere((durationRange) {
        Duration position = videoPlayerController.value.position;
        bool isCurrentBufferedRange = durationRange.start < position && durationRange.end > position;
        return isCurrentBufferedRange;
      });
      if (currentBufferedRange == null) return Duration.zero;
      return currentBufferedRange.end;
    }

    void _addVideoEvent() {
      streamController.add(PlaybackState(
        controls: [
          MediaControl.rewind,
          if (_isPlaying()) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _processingState(),
        playing: _isPlaying(),
        updatePosition: videoPlayerController?.value.position ?? Duration.zero,
        bufferedPosition: _bufferedPosition(),
        speed: videoPlayerController?.value.playbackSpeed ?? 1.0,
      ));
    }

    void startStream() {
      videoPlayerController?.addListener(_addVideoEvent);
    }

    void stopStream() {
      videoPlayerController?.removeListener(_addVideoEvent);
      streamController.close();
    }

    streamController = StreamController<PlaybackState>(onListen: startStream, onPause: stopStream, onResume: startStream, onCancel: stopStream);
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
    song_path_list = file_list;

    // 4. Setup song list
    List<Song> tmp_list = [];
    for (final file_path in file_list) {
      tmp_list.add(await db.getSongFromPath(file_path));
    }
    song_list = tmp_list;
  }
  
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (audio_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
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
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    });
  }
  
  void _listenForSongEnd() {
    audio_player.playerStateStream.listen((playerState) {
      if (playerState.processingState != ProcessingState.completed) return;

      skipToNext();
      if (app_opened) need_sync = true;
    });
  }


  /* FUNCTIONS */

  // Adds a song to the end of queue
  void addToQueue(Song song) async {
    song_queue.add(song);
    if (song_queue.length == current_queue_index+1) {
      await playFile(song);
    }
    queue.add(queue.value);
  }
  
  void replaceCurrent(Song song) async {
    song_queue[current_queue_index] = song;
    await playFile(song);
    queue.add(queue.value);
  }

  void setAppOpened(bool is_opened) {
    if (app_opened != is_opened) return;
    app_opened = is_opened;

    if (is_opened) {
      syncVideoPlayer();
    } else {
      
    }
  }


  /* UTILS */

  // Checks if a file is of media file format (e.g. mp3, m4a...)
  bool isMediaFile(String file_path) {
    for (final format in accepted_formats) {
      if (file_path.endsWith(format)) return true;
    }
    return false;
  }

  // Converts file path into file name
  String toFileName(String file_path) {
    return file_path.split("/").last;
  }

  // Creates a MediaItem from file name
  MediaItem toMediaItem(Song song, Duration duration) {
    return MediaItem(
      id: song.song_path,
      title: song.song_name,
      duration: duration,
    );
  }

  // Plays a Media file
  Future<void> playFile(Song song) async {
    await playFileVideo(song);
    await playFileAudio(song);
    queue.add(queue.value);
  }

  Future<void> playFileAudio(Song song) async {
    await audio_player.setAudioSource(AudioSource.file("$music_folder_path/${song.song_path}"));
    await audio_player.seek(Duration.zero);

    audio_handler.mediaItem.add(toMediaItem(song, video_controller.value.duration));
    await audio_player.play();
  }

  Future<void> playFileVideo(Song song) async {
    // 1. Remove Current Video Controller
    await video_controller.pause();
    await video_controller.dispose();

    // 2. Init New Video Controller
    video_controller = VideoPlayerController.file(
      File("$music_folder_path/${song.song_path}"),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true
      )
    );
    await video_controller.initialize();
    await video_controller.setVolume(0);

    audio_handler.setVideoFunctions(video_controller.play, video_controller.pause, video_controller.seekTo, () {
      video_controller.seekTo(Duration.zero);
      video_controller.pause();
    });

    // 3. Play
    await video_controller.play();
  }

  Future<void> syncVideoPlayer() async {
    // 1. Sync audio source (might be playing the next song)
    if (need_sync) {
      await playFileVideo(song_queue[current_queue_index]);
    } else {
      await video_controller.pause();
    }

    // 2. Sync playing state
    await video_controller.seekTo(audio_player.position);
    if (audio_player.playing) await video_controller.play();
  }
 
  @override Future<void> play() async {
    _videoPlay!();
    audio_player.play();
  }
  @override Future<void> pause() async {
    _videoPause!();
    audio_player.pause();
  }
  @override Future<void> seek(Duration position) async {
    _videoSeek!(position);
    audio_player.seek(position);
  }
  @override Future<void> stop() async {
    _videoStop!();
    audio_player.pause();
    audio_player.seek(Duration.zero);
  }
  @override Future<bool> skipToNext() async {
    if (song_queue.length < current_queue_index+1) return false;

    current_queue_index++;    
    await playFile(song_queue[current_queue_index]);
    queue.add(queue.value);

    return true;
  }
  @override Future<bool> skipToPrevious() async {
    if (current_queue_index < 1) return false;

    current_queue_index--;    
    playFile(song_queue[current_queue_index]);
    queue.add(queue.value);

    return true;
  }

  Stream<MediaState> get mediaStateStream {
    return Rx.combineLatest2<MediaItem?, Duration, MediaState>(
      audio_handler.mediaItem,
      AudioService.position,
      (mediaItem, position) => MediaState(mediaItem, position)
    );
  }
}