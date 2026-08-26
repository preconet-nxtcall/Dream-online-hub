import 'package:flutter/material.dart';

class ChatMessageSkeletonWidget extends StatefulWidget {
  const ChatMessageSkeletonWidget({super.key});

  @override
  State<ChatMessageSkeletonWidget> createState() =>
      _ChatMessageSkeletonWidgetState();
}

class _ChatMessageSkeletonWidgetState extends State<ChatMessageSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final skeletonItems = [
      {'isMe': false, 'width': 190.0, 'lines': 1},
      {'isMe': true, 'width': 230.0, 'lines': 2},
      {'isMe': false, 'width': 150.0, 'lines': 1},
      {'isMe': true, 'width': 210.0, 'lines': 2},
      {'isMe': false, 'width': 260.0, 'lines': 3},
      {'isMe': true, 'width': 170.0, 'lines': 1},
      {'isMe': false, 'width': 220.0, 'lines': 2},
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerPercent = _controller.value;
        final baseColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
        final myBubbleColor = isDark ? const Color(0xFF005C4B) : const Color(0xFFE2F7CB);

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          itemCount: skeletonItems.length,
          itemBuilder: (context, index) {
            final item = skeletonItems[index];
            final isMe = item['isMe'] as bool;
            final width = item['width'] as double;
            final lines = item['lines'] as int;

            final bubbleBg = isMe ? myBubbleColor : baseColor;

            final shimmerGradient = LinearGradient(
              begin: Alignment(-1.0 + (shimmerPercent * 3.0), -0.3),
              end: Alignment(-0.2 + (shimmerPercent * 3.0), 0.3),
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.06),
                    ],
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 3),
                      bottomRight: Radius.circular(isMe ? 3 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: width * 0.75,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: shimmerGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (lines >= 2) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: width * 0.55,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: shimmerGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                      if (lines >= 3) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: width * 0.35,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: shimmerGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 34,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: shimmerGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
