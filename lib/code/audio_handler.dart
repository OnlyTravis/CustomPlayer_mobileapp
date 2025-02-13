import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:song_player/code/file_handler.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';

import 'package:song_player/code/database.dart';

late MusicHandler audio_handler;

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
enum PlayingMode { forward, loopCurrent, loopQueue }

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

  List<Song> song_queue = [];
  int current_queue_index = 0;

  late Playlist playing_playlist;
  bool is_playing_playlist = false;
  PlayingMode playing_mode = PlayingMode.forward;

  bool video_is_inited = false;
  bool is_playing_video = false;
  bool need_sync = false;
  bool app_opened = true;

  Function? _videoPlay;
  Function? _videoPause;
  Function? _videoSeek;
  Function? _videoStop;


  /* INITS */

  MusicHandler() {
    audio_player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _listenForDurationChanges();
    _listenForSongEnd();
    Timer.periodic(const Duration(seconds: 1), (_) => checkSync());
  }

  MediaItem toMediaItem(Song song, Duration duration) {
    return MediaItem(
      id: song.song_path,
      title: song.song_name,
      artist: song.author,
      duration: duration,
    );
  }
  
  void _setVideoFunctions(Function play, Function pause, Function seek, Function stop) {
    _videoPlay = play;
    _videoPause = pause;
    _videoSeek = seek;
    _videoStop = stop;
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

      switch (playing_mode) {
        case PlayingMode.forward: break;
        case PlayingMode.loopCurrent:
          seek(Duration.zero);
          return;
        case PlayingMode.loopQueue:
          if (current_queue_index == song_queue.length-1) {
            skipToIndex(0);
            return;
          }
          break;
      }

      skipToNext();
      if (!app_opened) need_sync = true;
    });
  }

  Future<void> addToQueue(Song song) async {
    song_queue.add(song);
    if (song_queue.length == current_queue_index+1) {
      await playFile(song);
    }

    if (song_queue.length > settings_manager.getSetting(Settings.maxQueueLength)) {
      song_queue.removeAt(0);
      current_queue_index--;
    }

    queue.add(queue.value);
  }
  Future<void> replaceCurrent(Song song) async {
    if (song_queue.isEmpty) {
      song_queue.add(song);
    } else {
      song_queue[current_queue_index] = song;
    }
    await playFile(song);
    queue.add(queue.value);
  }
  Future<void> moveQueueItem(int index, int new_index) async {
    // 1. Check if request is valid
    if (index < 0 || index >= song_queue.length || new_index < 0 || index == new_index) return;
    if (new_index >= song_queue.length) new_index = song_queue.length-1;

    // 2. Update song_queue values
    Song tmp = song_queue[index];
    if (new_index > index) {
      for (int i = index; i < new_index; i++) {
        song_queue[index] = song_queue[index+1];
      }
    } else {
      for (int i = index; i > new_index; i--) {
        song_queue[index] = song_queue[index-1];
      }
    }
    song_queue[new_index] = tmp;

    // 3. Update current_song_index + broadcast change
    if (current_queue_index == index) {
      current_queue_index = new_index;
    } else {
      if (index <= current_queue_index && current_queue_index <= new_index) {
        current_queue_index--;
      } else if (index >= current_queue_index && current_queue_index >= new_index) {
        current_queue_index++;
      }
    }
    await addRandomFromPlaylist();
    queue.add(queue.value);
  }
  Future<void> removeQueueItem_(int index) async {
    if (song_queue.length <= 1) return;

    if (current_queue_index == index) {
      if (current_queue_index != song_queue.length-1) {
        await skipToNext();
        current_queue_index--;
      } else {
        await skipToPrevious();
      }
    } else if (index < current_queue_index) {
      current_queue_index--;
    }
    song_queue.removeAt(index);

    if (is_playing_playlist) await addRandomFromPlaylist();
    queue.add(queue.value);
  }
  Future<void> updateSongsInQueue() async {
    if (song_queue.isEmpty) return;

    List<int> updateIdList = [];
    List<Song> updateSongList = [];
    for (int i = 0; i < song_queue.length; i++) {
      final int index = updateIdList.indexOf(song_queue[i].song_id);
      if (index != -1) {
        song_queue[i] = updateSongList[index];
        continue;
      }

      final Song song = await db.getSongFromId(song_queue[i].song_id);
      updateIdList.add(song_queue[i].song_id);
      updateSongList.add(song);
      song_queue[i] = song;
    }

    mediaItem.add(
      mediaItem.value?.copyWith(
        id: song_queue[current_queue_index].song_path,
        title: song_queue[current_queue_index].song_name,
        artist: song_queue[current_queue_index].author
      )
    );
    await audio_player.setVolume(song_queue[current_queue_index].volume);
  }

  Future<void> playPlaylist(Playlist playlist) async {
    if (playlist.song_id_list.isEmpty) return;

    playing_playlist = playlist;
    song_queue.clear();
    current_queue_index = 0;
    is_playing_playlist = true;

    await addRandomFromPlaylist();
    await playFile(song_queue[0]);
  }
  Future<void> stopPlaylist() async {
    song_queue.clear();
    current_queue_index = 0;
    is_playing_playlist = false;
    await pause();
  }
  Future<void> addRandomFromPlaylist() async {
    int previous = (song_queue.isEmpty)? -1 : song_queue[song_queue.length-1].song_id;
    int max_songs = settings_manager.getSetting(Settings.playlistBufferLength);

    while (song_queue.length - current_queue_index < max_songs) {
      int next_song = Random().nextInt(playing_playlist.song_id_list.length);

      if (playing_playlist.song_id_list.length != 1) {
        while (next_song == previous) next_song = Random().nextInt(playing_playlist.song_id_list.length); 
      }

      song_queue.add(await db.getSongFromId(playing_playlist.song_id_list[next_song]));
      if (song_queue.length > settings_manager.getSetting(Settings.maxQueueLength)) {
        song_queue.removeAt(0);
        current_queue_index--;
      }
      previous = next_song;
    } 
  }

  Future<void> playFile(Song song) async {
    is_playing_video = song.is_video;
    await playFileVideo(song);
    await playFileAudio(song);
    queue.add(queue.value);
  }
  Future<void> playFileAudio(Song song) async {
    await audio_player.setAudioSource(AudioSource.file("${file_handler.root_folder_path}/${song.song_path}"));
    await audio_player.seek(Duration.zero);
    await audio_player.setVolume(song.volume);
    await audio_player.play();
  }
  Future<void> playFileVideo(Song song) async {
    // 1. Remove Current Video Controller
    if (video_is_inited) {
      await video_controller.pause();
      await video_controller.dispose();
    }

    // 2. Init New Video Controller
    video_controller = VideoPlayerController.file(
      File("${file_handler.root_folder_path}/${song.song_path}"),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true
      )
    );
    await video_controller.initialize();
    await video_controller.setVolume(0);
    video_is_inited = true;

    audio_handler._setVideoFunctions(video_controller.play, video_controller.pause, video_controller.seekTo, () {
      video_controller.seekTo(Duration.zero);
      video_controller.pause();
    });

    // 3. Play
    await video_controller.play();
    audio_handler.mediaItem.add(toMediaItem(song, video_controller.value.duration));
  }

  void changePlayMode(PlayingMode mode) {
    playing_mode = mode;
  }

  Future<void> checkSync() async {
    if (!is_playing_video || !app_opened) return;

    Duration video_position = await video_controller.position ?? Duration.zero;
    if (video_position == Duration.zero) return;

    if ((video_position - audio_player.position).abs() > const Duration(milliseconds: 300)) {
      video_controller.seekTo(audio_player.position + const Duration(milliseconds: 350));
    }
  }
  Future<void> syncVideoPlayer() async {
    if (!video_is_inited) return;

    // 1. Sync audio source (might be playing the next song)
    if (need_sync) {
      await playFileVideo(song_queue[current_queue_index]);
    }

    // 2. Sync playing state
    if (audio_player.playing) {
      await video_controller.play();
    } else {
      await video_controller.pause();
    }
    await video_controller.seekTo(audio_player.position + const Duration(milliseconds: 350));
    queue.add(queue.value);
  }
  void setAppOpened(bool is_opened) {
    if (app_opened == is_opened) return;
    app_opened = is_opened;

    if (is_opened) {
      syncVideoPlayer();
      queue.add(queue.value);
    }
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
    if (current_queue_index+1 >= song_queue.length) return false;

    current_queue_index++;
    await playFile(song_queue[current_queue_index]);
    queue.add(queue.value);
    if (is_playing_playlist) await addRandomFromPlaylist();
    if (!app_opened) need_sync = true;

    return true;
  }
  @override Future<bool> skipToPrevious() async {
    if (current_queue_index < 1) return false;

    current_queue_index--;    
    playFile(song_queue[current_queue_index]);
    queue.add(queue.value);
    if (!app_opened) need_sync = true;

    return true;
  }
  Future skipToIndex(int index) async {
    if (index < 0 || index >= song_queue.length) return false;

    current_queue_index = index;
    playFile(song_queue[current_queue_index]);
    queue.add(queue.value);
    if (!app_opened) need_sync = true;

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