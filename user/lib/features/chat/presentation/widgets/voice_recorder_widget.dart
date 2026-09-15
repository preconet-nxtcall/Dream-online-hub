import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/logger.dart';

class VoiceRecorderWidget extends StatefulWidget {
  /// Called when the user cancels recording.
  final VoidCallback onCancel;

  /// Called with the recorded file path and duration string when user taps Send.
  final void Function(String filePath, String durationStr) onSend;

  const VoiceRecorderWidget({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late AnimationController _pulseController;

  bool _isRecording = false;
  int _durationSeconds = 0;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Request microphone permission at runtime
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      widget.onCancel();
      return;
    }

    final dir = await getTemporaryDirectory();
    bool isAacSupported = true;
    try {
      isAacSupported = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    } catch (_) {}

    final encoder = isAacSupported ? AudioEncoder.aacLc : AudioEncoder.pcm16bits;
    final ext = isAacSupported ? 'm4a' : 'wav';
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _recordingPath = path;

    if (!mounted) return;
    setState(() => _isRecording = true);

    // Tick duration counter every second
    _tickDuration();
  }

  void _tickDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isRecording) return;
      setState(() => _durationSeconds++);
      _tickDuration();
    });
  }

  Future<void> _cancel() async {
    _isRecording = false;
    await _recorder.stop();
    // Delete temp file on cancel
    if (_recordingPath != null) {
      try {
        await File(_recordingPath!).delete();
      } catch (_) {}
    }
    widget.onCancel();
  }

  Future<void> _send() async {
    if (!_isRecording) return;
    _isRecording = false;
    final path = await _recorder.stop();
    // Allow OS recorder process to flush and release file handle lock completely
    await Future.delayed(const Duration(milliseconds: 150));

    if (path == null || path.isEmpty) {
      widget.onCancel();
      return;
    }

    try {
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() == 0) {
        AppLogger.warning('[VoiceRecorderWidget] Recorded file is missing or 0 bytes: $path');
        widget.onCancel();
        return;
      }
    } catch (e) {
      AppLogger.error('[VoiceRecorderWidget] File check error: $e');
    }

    final mins = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_durationSeconds % 60).toString().padLeft(2, '0');
    final durationStr = '$mins:$secs';
    widget.onSend(path, durationStr);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232730) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Cancel / Trash Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 22),
            onPressed: _cancel,
            tooltip: 'Cancel Recording',
          ),
          const SizedBox(width: 4),

          // Red Pulsing Indicator Dot
          FadeTransition(
            opacity:
                Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Recording Time Counter
          Text(
            _formatDuration(_durationSeconds),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),

          // Animated Waveform Bars
          Expanded(
            child: SizedBox(
              height: 24,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(8, (index) {
                      final val = math
                          .sin(_pulseController.value * math.pi + index * 0.5)
                          .abs();
                      final height = 6.0 + (val * 18.0);
                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.error
                              .withValues(alpha: 0.6 + (val * 0.4)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send Recording Action Button
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _send,
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
