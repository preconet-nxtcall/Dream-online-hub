import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const VoiceRecorderWidget({
    super.key,
    required this.durationSeconds,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            onPressed: widget.onCancel,
            tooltip: 'Cancel Recording',
          ),
          const SizedBox(width: 4),

          // Red Pulsing Indicator Dot
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController),
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
            _formatDuration(widget.durationSeconds),
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
                    children: List.generate(14, (index) {
                      final val = math.sin(_pulseController.value * math.pi + index * 0.5).abs();
                      final height = 6.0 + (val * 18.0);

                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.6 + (val * 0.4)),
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
              onTap: widget.onSend,
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
