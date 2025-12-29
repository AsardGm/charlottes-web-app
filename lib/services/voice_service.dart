import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Podmíněný import pro file operations
import 'voice_file_helper_stub.dart'
    if (dart.library.io) 'voice_file_helper_io.dart';

/// Service pro nahrávání a přehrávání hlasových zpráv
/// Funguje na iOS i webu
class VoiceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;
  bool _isDisposed = false;

  // Streams
  final _recordingDurationController = StreamController<Duration>.broadcast();
  final _playbackPositionController = StreamController<Duration>.broadcast();
  final _playbackStateController = StreamController<bool>.broadcast();

  Stream<Duration> get recordingDuration => _recordingDurationController.stream;
  Stream<Duration> get playbackPosition => _playbackPositionController.stream;
  Stream<bool> get playbackState => _playbackStateController.stream;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  Timer? _durationTimer;

  VoiceService() {
    _player.onPositionChanged.listen((position) {
      if (!_isDisposed) {
        _playbackPositionController.add(position);
      }
    });

    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentlyPlayingUrl = null;
      if (!_isDisposed) {
        _playbackStateController.add(false);
      }
    });

    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      if (!_isDisposed) {
        _playbackStateController.add(_isPlaying);
      }
    });
  }

  /// Zkontroluje oprávnění pro mikrofon
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Začne nahrávat hlasovou zprávu
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Nemáte oprávnění pro mikrofon');
    }

    if (kIsWeb) {
      // Na webu nahrávání do paměti (blob)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 128000,
          sampleRate: 48000,
        ),
        path: '', // Na webu se ignoruje
      );
    } else {
      // Na mobilech nahrávání do souboru
      _currentRecordingPath = await VoiceFileHelper.getRecordingPath();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );
    }

    _isRecording = true;
    _recordingStartTime = DateTime.now();

    // Timer pro aktualizaci délky nahrávání
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_recordingStartTime != null && !_isDisposed) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        _recordingDurationController.add(duration);
      }
    });
  }

  /// Zastaví nahrávání a vrátí cestu k souboru nebo blob URL na webu
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _durationTimer?.cancel();
    _durationTimer = null;

    final path = await _recorder.stop();
    _isRecording = false;

    return path;
  }

  /// Zruší nahrávání
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _durationTimer?.cancel();
    _durationTimer = null;

    await _recorder.stop();
    _isRecording = false;
    _recordingStartTime = null;

    // Smaž soubor na nativních platformách
    if (_currentRecordingPath != null && !kIsWeb) {
      await VoiceFileHelper.deleteFile(_currentRecordingPath!);
    }
    _currentRecordingPath = null;
  }

  /// Nahraje hlasovou zprávu do Storage a vrátí URL
  Future<VoiceUploadResult> uploadVoiceMessage({
    required String conversationId,
    required String filePath,
  }) async {
    final recordingDuration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!).inSeconds
        : 0;
    _recordingStartTime = null;

    Uint8List bytes;

    if (kIsWeb) {
      // Na webu je filePath blob URL - použijeme fetch API
      bytes = await VoiceFileHelper.readBlobAsBytes(filePath);
    } else {
      // Na mobilech načteme soubor
      bytes = await VoiceFileHelper.readFileAsBytes(filePath);
    }

    final extension = kIsWeb ? 'webm' : 'm4a';
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = 'chat/$conversationId/$fileName';

    await _supabase.storage
        .from('voice-messages')
        .uploadBinary(storagePath, bytes);

    final publicUrl = _supabase.storage
        .from('voice-messages')
        .getPublicUrl(storagePath);

    // Smaž lokální soubor
    if (!kIsWeb) {
      await VoiceFileHelper.deleteFile(filePath);
    }

    return VoiceUploadResult(
      url: publicUrl,
      durationSeconds: recordingDuration,
    );
  }

  /// Přehraje hlasovou zprávu
  Future<void> play(String url) async {
    if (_isPlaying && _currentlyPlayingUrl == url) {
      // Pause
      await _player.pause();
      _isPlaying = false;
      _playbackStateController.add(false);
      return;
    }

    if (_isPlaying) {
      await _player.stop();
    }

    _currentlyPlayingUrl = url;
    await _player.play(UrlSource(url));
    _isPlaying = true;
    _playbackStateController.add(true);
  }

  /// Pozastaví přehrávání
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    _playbackStateController.add(false);
  }

  /// Pokračuje v přehrávání
  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
    _playbackStateController.add(true);
  }

  /// Zastaví přehrávání
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentlyPlayingUrl = null;
    _playbackStateController.add(false);
  }

  /// Přeskočí na pozici
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Získá délku audio souboru
  Future<Duration?> getDuration(String url) async {
    try {
      final tempPlayer = AudioPlayer();
      await tempPlayer.setSourceUrl(url);
      final duration = await tempPlayer.getDuration();
      await tempPlayer.dispose();
      return duration;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _isDisposed = true;
    _durationTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _recordingDurationController.close();
    _playbackPositionController.close();
    _playbackStateController.close();
  }
}

class VoiceUploadResult {
  final String url;
  final int durationSeconds;

  VoiceUploadResult({
    required this.url,
    required this.durationSeconds,
  });
}
