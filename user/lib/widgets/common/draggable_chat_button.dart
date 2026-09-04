import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A draggable floating chat support button that users can move anywhere on screen
/// with smooth Facebook Messenger style edge snapping using AnimatedPositioned.
class DraggableFloatingChatButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const DraggableFloatingChatButton({
    super.key,
    required this.onTap,
    this.label = 'Chat Support',
    this.icon = Icons.chat_bubble_rounded,
  });

  @override
  State<DraggableFloatingChatButton> createState() => _DraggableFloatingChatButtonState();
}

class _DraggableFloatingChatButtonState extends State<DraggableFloatingChatButton> {
  Offset? _position;
  bool _isDragging = false;
  double _totalDragDistance = 0.0;

  void _snapToNearestEdge(double minX, double maxX, double minY, double maxY, double parentWidth) {
    if (_position == null) return;

    final currentX = _position!.dx;
    final currentY = _position!.dy;

    // Determine nearest edge (Left or Right)
    final targetX = (currentX < parentWidth / 2) ? minX : maxX;
    final targetY = currentY.clamp(minY, maxY).toDouble();

    setState(() {
      _position = Offset(targetX, targetY);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        final parentHeight = constraints.maxHeight;

        // Estimated button dimensions
        const buttonWidth = 145.0;
        const buttonHeight = 48.0;

        // Parent boundaries
        const minX = 12.0;
        final maxX = math.max(minX, parentWidth - buttonWidth - 12.0);
        const minY = 12.0;
        final maxY = math.max(minY, parentHeight - buttonHeight - 16.0);

        // Default starting position (Bottom-Right corner)
        _position ??= Offset(
          maxX,
          maxY,
        );

        // Ensure position remains within valid bounds when not dragging
        if (!_isDragging) {
          final clampedX = _position!.dx.clamp(minX, maxX).toDouble();
          final clampedY = _position!.dy.clamp(minY, maxY).toDouble();
          _position = Offset(clampedX, clampedY);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: _position!.dx,
              top: _position!.dy,
              child: GestureDetector(
                onPanStart: (_) {
                  setState(() {
                    _isDragging = true;
                    _totalDragDistance = 0.0;
                  });
                },
                onPanUpdate: (details) {
                  _totalDragDistance += details.delta.distance;
                  setState(() {
                    final newX = (_position!.dx + details.delta.dx).clamp(minX, maxX).toDouble();
                    final newY = (_position!.dy + details.delta.dy).clamp(minY, maxY).toDouble();
                    _position = Offset(newX, newY);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _isDragging = false;
                  });
                  if (_totalDragDistance < 6.0) {
                    widget.onTap();
                  } else {
                    _snapToNearestEdge(minX, maxX, minY, maxY, parentWidth);
                  }
                },
                onTap: widget.onTap,
                child: AnimatedScale(
                  scale: _isDragging ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7A00), Color(0xFFFF9900), Color(0xFFE66700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A00).withValues(alpha: _isDragging ? 0.7 : 0.45),
                          blurRadius: _isDragging ? 22 : 14,
                          spreadRadius: _isDragging ? 3 : 1,
                          offset: Offset(0, _isDragging ? 6 : 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(widget.icon, color: Colors.white, size: 20),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.label,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
