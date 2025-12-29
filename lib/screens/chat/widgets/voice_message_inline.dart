import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/theme.dart';

/// Inline widget pro prehravani hlasove zpravy v bublině
class VoiceMessageInline extends StatefulWidget {
  final String voiceUrl;
  final int durationSeconds;
  final bool isMe;

  const VoiceMessageInline({
    super.key,
    required this.voiceUrl,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoiceMessageInline> createState() => _VoiceMessageInlineState();
}

class _VoiceMessageInlineState extends State<VoiceMessageInline> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;

  // Generované výšky pro waveform
  late List<double> _waveformHeights;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _duration = Duration(seconds: widget.durationSeconds);

    // Generuj náhodné výšky pro waveform
    _waveformHeights = List.generate(20, (i) {
      final seed = widget.voiceUrl.hashCode + i;
      return 4 + (seed % 16).toDouble();
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) {
        setState(() => _duration = dur);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      setState(() => _isLoading = true);
      try {
        if (_position == Duration.zero) {
          await _player.play(UrlSource(widget.voiceUrl));
        } else {
          await _player.resume();
        }
      } catch (e) {
        debugPrint('Voice playback error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final activeColor = widget.isMe ? Colors.white : AppColors.primary;
    final inactiveColor = widget.isMe ? Colors.white.withAlpha(80) : AppColors.primary.withAlpha(80);

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withAlpha(30) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isMe ? AppColors.primary : Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? AppColors.primary : Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Waveform and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(20, (i) {
                      final barProgress = i / 20;
                      final isActive = barProgress <= progress;
                      return Container(
                        width: 3,
                        height: _waveformHeights[i],
                        decoration: BoxDecoration(
                          color: isActive ? activeColor : inactiveColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                // Time
                Row(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 12,
                      color: widget.isMe ? Colors.white.withAlpha(150) : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPlaying || _position.inSeconds > 0
                          ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                          : _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isMe ? Colors.white.withAlpha(180) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
