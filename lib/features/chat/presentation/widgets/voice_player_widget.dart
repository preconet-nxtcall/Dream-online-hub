import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class VoicePlayerWidget extends StatefulWidget {
  final String durationStr;
  final bool isMe;

  const VoicePlayerWidget({
    super.key,
    required this.durationStr,
    required this.isMe,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;
  int _totalSeconds = 15;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseDuration(widget.durationStr);
  }

  int _parseDuration(String str) {
    try {
      final parts = str.split(':');
      if (parts.length == 2) {
        return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      } else if (parts.length == 1) {
        return int.tryParse(parts[0]) ?? 15;
      }
    } catch (_) {}
    return 15;
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    _playbackTimer?.cancel();
    if (_isPlaying) {
      if (_playbackProgress >= 1.0) {
        _playbackProgress = 0.0;
      }

      final intervalMs = (100 / _playbackSpeed).round();
      final totalSteps = (_totalSeconds * 1000) / intervalMs;
      final stepIncrement = 1.0 / totalSteps;

      _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _playbackProgress += stepIncrement;
          if (_playbackProgress >= 1.0) {
            _playbackProgress = 1.0;
            _isPlaying = false;
            timer.cancel();
          }
        });
      });
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });

    if (_isPlaying) {
      _togglePlayPause();
      _togglePlayPause();
    }
  }

  String _formatSeconds(int secs) {
    final m = (secs ~/ 60).toString();
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMe ? Colors.white : AppColors.primary;
    final inactiveColor = widget.isMe ? Colors.white.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.25);
    final textColor = widget.isMe ? Colors.white70 : Colors.grey[700];

    final elapsedSeconds = (_playbackProgress * _totalSeconds).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Play / Pause Circle Button
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: activeColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Animated Interactive Waveform Seekbar
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final localPos = details.localPosition.dx;
                    final ratio = (localPos / box.size.width).clamp(0.0, 1.0);
                    setState(() {
                      _playbackProgress = ratio;
                    });
                  }
                },
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: List.generate(20, (index) {
                      final barRatio = (index + 1) / 20.0;
                      final isActive = barRatio <= _playbackProgress;
                      final heights = [10, 16, 26, 14, 28, 20, 12, 24, 18, 26, 14, 22, 12, 18, 28, 16, 22, 14, 20, 12];
                      final barHeight = heights[index % heights.length].toDouble();

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.2),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isActive ? activeColor : inactiveColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Speed Control Chip Button (1x / 1.5x / 2x)
            GestureDetector(
              onTap: _cycleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isMe ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_playbackSpeed.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Duration Info Timer (e.g. 0:05 / 0:18)
        Padding(
          padding: const EdgeInsets.only(left: 44.0),
          child: Text(
            '${_formatSeconds(elapsedSeconds)} / ${_formatSeconds(_totalSeconds)}',
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
