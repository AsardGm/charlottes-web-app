import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../services/voice_service.dart';

/// Widget pro přehrávání hlasové zprávy s waveform vizualizací
class VoiceMessageWidget extends StatefulWidget {
  final String voiceUrl;
  final int durationSeconds;
  final bool isMe;
  final VoiceService voiceService;

  const VoiceMessageWidget({
    super.key,
    required this.voiceUrl,
    required this.durationSeconds,
    required this.isMe,
    required this.voiceService,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _stateSubscription;
  late AnimationController _playButtonController;

  // Simulovaný waveform (v reálné aplikaci by se načítal ze souboru)
  late List<double> _waveformBars;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.durationSeconds);

    // Generuj náhodný waveform pro vizualizaci
    final random = Random(widget.voiceUrl.hashCode);
    _waveformBars = List.generate(30, (_) => 0.2 + random.nextDouble() * 0.8);

    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _positionSubscription = widget.voiceService.playbackPosition.listen((pos) {
      if (widget.voiceService.currentlyPlayingUrl == widget.voiceUrl) {
        setState(() => _position = pos);
      }
    });

    _stateSubscription = widget.voiceService.playbackState.listen((playing) {
      if (widget.voiceService.currentlyPlayingUrl == widget.voiceUrl) {
        setState(() => _isPlaying = playing);
        if (playing) {
          _playButtonController.forward();
        } else {
          _playButtonController.reverse();
        }
      } else {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _playButtonController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _playButtonController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final primaryColor = widget.isMe ? Colors.white : AppColors.primary;
    final mutedColor = widget.isMe
        ? Colors.white.withAlpha(100)
        : AppColors.textMuted.withAlpha(150);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button s animací
          GestureDetector(
            onTap: () => widget.voiceService.play(widget.voiceUrl),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withAlpha(40)
                    : AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withAlpha(60),
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(_isPlaying),
                  color: primaryColor,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Waveform vizualizace
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform bars
                SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_waveformBars.length, (index) {
                      final barProgress = index / _waveformBars.length;
                      final isPlayed = barProgress <= progress;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 3,
                        height: _waveformBars[index] * 24,
                        decoration: BoxDecoration(
                          color: isPlayed ? primaryColor : mutedColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                // Čas a ikona mikrofonu
                Row(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 12,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPlaying
                          ? _formatDuration(_position)
                          : _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: widget.isMe
                            ? Colors.white.withAlpha(200)
                            : AppColors.textMuted,
                      ),
                    ),
                    if (_isPlaying) ...[
                      const SizedBox(width: 4),
                      Text(
                        '/ ${_formatDuration(_duration)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: mutedColor,
                        ),
                      ),
                    ],
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

/// Widget pro nahrávání hlasové zprávy s vylepšeným UI
class VoiceRecordingWidget extends StatefulWidget {
  final VoiceService voiceService;
  final VoidCallback onCancel;
  final Function(String path) onComplete;

  const VoiceRecordingWidget({
    super.key,
    required this.voiceService,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _durationSubscription;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  // Animované waveform bars
  late List<double> _waveBars;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _waveBars = List.generate(20, (_) => 0.3);

    _durationSubscription = widget.voiceService.recordingDuration.listen((d) {
      setState(() {
        _duration = d;
        // Simuluj vlny nahravani
        final random = Random();
        for (int i = 0; i < _waveBars.length; i++) {
          _waveBars[i] = 0.2 + random.nextDouble() * 0.8;
        }
      });
    });
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _stopAndSend() async {
    final path = await widget.voiceService.stopRecording();
    if (path != null) {
      widget.onComplete(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            Container(
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  widget.voiceService.cancelRecording();
                  widget.onCancel();
                },
                icon: Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Zrusit nahravani',
              ),
            ),
            const SizedBox(width: 12),

            // Recording indicator s pulsujici animaci
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withAlpha(
                          (100 + 80 * _pulseController.value).toInt(),
                        ),
                        blurRadius: 8 + 4 * _pulseController.value,
                        spreadRadius: 2 * _pulseController.value,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Waveform animace
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Cas
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Wave vizualizace
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(_waveBars.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 3,
                            height: _waveBars[index] * 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(180),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _stopAndSend,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                tooltip: 'Odeslat hlasovou zpravu',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
