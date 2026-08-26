import 'package:flutter/material.dart';

class QuickCategoryWidget extends StatelessWidget {
  final int activeSubscriptions;
  final int pendingSubscriptions;
  final String pendingRecharges;
  final String successfulRecharges;
  final Function(String category)? onSelectCategory;

  const QuickCategoryWidget({
    super.key,
    this.activeSubscriptions = 1,
    this.pendingSubscriptions = 5,
    this.pendingRecharges = '₹0',
    this.successfulRecharges = '₹185',
    this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dynamic Ultra-Compact Responsive Dimensions (Zero Extra Space)
    final double cardHeight = (screenWidth < 360)
        ? 68.0
        : ((screenWidth > 480) ? 78.0 : 72.0);
    final double titleFontSize = (screenWidth < 360)
        ? 10.0
        : ((screenWidth > 480) ? 11.5 : 10.5);
    final double valueFontSize = (screenWidth < 360)
        ? 15.5
        : ((screenWidth > 480) ? 18.0 : 16.5);
    const double gapSpacing = 6.0;

    return Column(
      children: [
        // Row 1: Active Subscriptions (Card 1) & Pending Subscriptions (Card 2)
        Row(
          children: [
            Expanded(
              child: _buildActiveCard(
                context,
                isDark,
                activeSubscriptions,
                cardHeight,
                titleFontSize,
                valueFontSize,
              ),
            ),
            const SizedBox(width: gapSpacing),
            Expanded(
              child: _buildPendingSubCard(
                context,
                isDark,
                pendingSubscriptions,
                cardHeight,
                titleFontSize,
                valueFontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: gapSpacing),

        // Row 2: Pending Recharges (Card 3) & Successful Recharges (Card 4)
        Row(
          children: [
            Expanded(
              child: _buildPendingRechargesCard(
                context,
                isDark,
                pendingRecharges,
                cardHeight,
                titleFontSize,
                valueFontSize,
              ),
            ),
            const SizedBox(width: gapSpacing),
            Expanded(
              child: _buildSuccessfulRechargesCard(
                context,
                isDark,
                successfulRecharges,
                cardHeight,
                titleFontSize,
                valueFontSize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- CARD 1: Active Subscriptions ---
  Widget _buildActiveCard(
    BuildContext context,
    bool isDark,
    int count,
    double height,
    double titleSize,
    double valueSize,
  ) {
    const accentColor = Color(0xFF8B5CF6);
    final bgColor = isDark ? const Color(0xFF1D1933) : const Color(0xFFF3F0FF);
    final borderColor = isDark ? const Color(0xFF382F5E) : const Color(0xFFE2DBFF);

    return GestureDetector(
      onTap: () => onSelectCategory?.call('active_subscriptions'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Top Right Badge Button
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              // Main Contents
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Active Subscriptions',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: valueSize,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  height: 2.0,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: 0.65,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  height: 8,
                                  child: CustomPaint(
                                    painter: _PulseWavePainter(
                                      color: accentColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD 2: Pending Subscriptions ---
  Widget _buildPendingSubCard(
    BuildContext context,
    bool isDark,
    int count,
    double height,
    double titleSize,
    double valueSize,
  ) {
    const accentColor = Color(0xFFF97316);
    final bgColor = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final borderColor = isDark ? const Color(0xFF382E28) : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: () => onSelectCategory?.call('pending_subscriptions'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Bottom Accent Line
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 2.0,
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),

              // Top Right Badge Button
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: const Icon(
                    Icons.feed_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              // Bottom Right Clipboard Icon Badge
              Positioned(
                right: 5,
                bottom: 4,
                child: IgnorePointer(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: accentColor.withValues(alpha: 0.85),
                      size: 13,
                    ),
                  ),
                ),
              ),

              // Main Contents
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pending Subscriptions',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD 3: Pending Recharges ---
  Widget _buildPendingRechargesCard(
    BuildContext context,
    bool isDark,
    String amount,
    double height,
    double titleSize,
    double valueSize,
  ) {
    const accentColor = Color(0xFFD97706);
    const goldenText = Color(0xFFEAB308);
    const bgColor = Color(0xFF0B132B);

    return GestureDetector(
      onTap: () => onSelectCategory?.call('pending_recharges'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Bottom Golden Accent Line
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 2.0,
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),

              // Top Right Golden Rupee Badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: const Icon(
                    Icons.currency_rupee_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              // Bottom Right Golden Wallet Icon
              Positioned(
                right: 6,
                bottom: 6,
                child: IgnorePointer(
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: goldenText.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
              ),

              // Main Contents
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pending Recharges',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          amount,
                          style: TextStyle(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w900,
                            color: goldenText,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD 4: Successful Recharges ---
  Widget _buildSuccessfulRechargesCard(
    BuildContext context,
    bool isDark,
    String amount,
    double height,
    double titleSize,
    double valueSize,
  ) {
    const accentColor = Color(0xFF22C55E);
    final bgColor = isDark ? const Color(0xFF162B1E) : const Color(0xFFE8F7ED);
    final borderColor = isDark ? const Color(0xFF253B2F) : const Color(0xFFDCFCE7);

    return GestureDetector(
      onTap: () => onSelectCategory?.call('successful_recharges'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Bottom Green Accent Line
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 2.0,
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),

              // Top Right Green Badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: const BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              // Bottom Right Bar Chart & Upward Trend Arrow
              Positioned(
                right: 5,
                bottom: 4,
                width: 38,
                height: 22,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GreenTrendArrowPainter(color: accentColor),
                  ),
                ),
              ),

              // Main Contents
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Successful Recharges',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          amount,
                          style: TextStyle(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sine wave pulse line painter for Card 1
class _PulseWavePainter extends CustomPainter {
  final Color color;
  _PulseWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.9,
      size.width,
      size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) =>
      oldDelegate.color != color;
}

// Green vertical bar chart pillars + upward trend arrow line for Card 4
class _GreenTrendArrowPainter extends CustomPainter {
  final Color color;
  _GreenTrendArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    const barWidth = 4.0;
    const spacing = 2.5;
    final startX = size.width * 0.15;

    // Bar 1 (Shortest)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, size.height * 0.55, barWidth, size.height * 0.45),
        const Radius.circular(1),
      ),
      barPaint,
    );

    // Bar 2 (Medium)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + barWidth + spacing, size.height * 0.35, barWidth, size.height * 0.65),
        const Radius.circular(1),
      ),
      barPaint,
    );

    // Bar 3 (Tallest)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + 2 * (barWidth + spacing), size.height * 0.15, barWidth, size.height * 0.85),
        const Radius.circular(1),
      ),
      barPaint,
    );

    // Upward trend line with arrowhead
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.55,
      size.width * 0.95,
      size.height * 0.05,
    );
    canvas.drawPath(path, linePaint);

    final arrowPath = Path();
    final arrowX = size.width * 0.95;
    final arrowY = size.height * 0.05;
    arrowPath.moveTo(arrowX - 4, arrowY + 2);
    arrowPath.lineTo(arrowX, arrowY);
    arrowPath.lineTo(arrowX - 2, arrowY + 4);
    canvas.drawPath(arrowPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _GreenTrendArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
