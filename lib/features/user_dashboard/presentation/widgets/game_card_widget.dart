import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../models/game/game_card_model.dart';
import '../../../../network/api_client.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

class GameCardWidget extends StatefulWidget {
  final GameCardModel game;
  final VoidCallback onPlay;

  const GameCardWidget({
    super.key,
    required this.game,
    required this.onPlay,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.game.isSubscribed;
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant GameCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.isSubscribed != widget.game.isSubscribed) {
      setState(() {
        _isSubscribed = widget.game.isSubscribed;
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section: Avatar Badge, Game Name, Result Pill, Status Chip
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Code / Image Logo Box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: (widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty)
                        ? Image.network(
                            widget.game.imageUrl!,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                widget.game.code,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
                          )
                        : Text(
                            widget.game.code,
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                  AppSpacing.hGapMd,

                  // Name & Results Box
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.game.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            // Dynamic Status Badge Pill (RUNNING OPEN, RUNNING CLOSE, CLOSED)
                            Builder(
                              builder: (context) {
                               final rawStatus = widget.game.status.trim();
                               final upper = rawStatus.toUpperCase();

                               String displayStatusText = 'Running Open';
                               Color statusBgColor = const Color(0xFFECFDF5);
                               Color statusTextColor = const Color(0xFF059669);
                               Color statusBorderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
                               IconData statusIcon = Icons.play_circle_fill_rounded;

                               if (upper.contains('CLOSE') && !upper.contains('RUNNING CLOSE')) {
                                 displayStatusText = 'Closed';
                                 statusBgColor = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.6) : const Color(0xFFFEF2F2);
                                 statusTextColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
                                 statusBorderColor = const Color(0xFFEF4444).withValues(alpha: 0.5);
                                 statusIcon = Icons.lock_clock_rounded;
                               } else if (_isSubscribed) {
                                 // Subscribed User -> Running Open (Green)
                                 displayStatusText = 'Running Open';
                                 statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFECFDF5);
                                 statusTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
                                 statusBorderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
                                 statusIcon = Icons.play_circle_fill_rounded;
                               } else {
                                 // Unsubscribed User -> Running Close (Amber)
                                 displayStatusText = 'Running Close';
                                 statusBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.6) : const Color(0xFFFFFBEB);
                                 statusTextColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
                                 statusBorderColor = const Color(0xFFF59E0B).withValues(alpha: 0.5);
                                 statusIcon = Icons.timer_rounded;
                               }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusBorderColor, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 11, color: statusTextColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        displayStatusText,
                                        style: TextStyle(
                                          color: statusTextColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10.5,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        AppSpacing.vGapXs,
                        // Golden Yellow Result Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                : const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.game.result,
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.8),

            // Bottom Section: Actions (Subscribe/Play right-aligned)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  const Spacer(),

                  // Right Side: Subscribe Button (if not subscribed) OR Subscribed + Play (if subscribed)
                  if (!_isSubscribed)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showSubscribeDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B2D36),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Subscribe',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Subscribed Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191F2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Subscribed',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Play Button
                    GestureDetector(
                      onTapDown: (_) => _scaleController.forward(),
                      onTapUp: (_) {
                        _scaleController.reverse();
                        _fetchAndShowBookRecord();
                      },
                      onTapCancel: () => _scaleController.reverse(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C2F36), Color(0xFF191B1F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Play',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFFFFD700),
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _resolveUserId() async {
    final currentUser = LocalStorageRepositoryImpl().getUser();
    if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
      final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) {
        return int.tryParse(digitsOnly) ?? 22;
      }
    }
    final storedUserId = await SecureStorageService().read(StorageKeys.userId);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) {
        return int.tryParse(digitsOnly) ?? 22;
      }
    }
    return 22;
  }

  int _resolveBookId() {
    final digitsOnly = widget.game.id.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isNotEmpty) {
      final parsed = int.tryParse(digitsOnly);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  Future<void> _handleSubscribeAction(BuildContext dialogCtx) async {
    Navigator.pop(dialogCtx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Processing subscription for ${widget.game.name}...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF232530),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final apiClient = ApiClient();
      final userId = await _resolveUserId();
      final bookId = _resolveBookId();

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'click_on_book',
          'user_id': userId,
          'book_id': bookId,
        },
      );

      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final isSubscribed = data['is_subscribed'] == true || data['already_subscribed'] == true;
        final msg = data['message']?.toString() ?? 'Subscribe request sent successfully!';

        if (isSubscribed) {
          setState(() {
            _isSubscribed = true;
          });
          final accountData = data['data'] is Map ? data['data'] as Map : {};
          final link = accountData['website_link']?.toString() ?? '';
          final user = accountData['username']?.toString() ?? '';
          final pass = accountData['password']?.toString() ?? '';
          _showAccountDetailsDialog(context, link, user, pass);
        } else {
          setState(() {
            _isSubscribed = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final errMsg = (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to complete subscription request.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<void> _fetchAndShowBookRecord() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                    strokeWidth: 2.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opening ${widget.game.name}...',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Fetching active subscription credentials...',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF14102B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
      ),
    );

    try {
      final apiClient = ApiClient();
      final userId = await _resolveUserId();
      final bookId = _resolveBookId();

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'click_on_book',
          'user_id': userId,
          'book_id': bookId,
        },
      );

      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final accountData = data['data'] is Map ? data['data'] as Map : {};
        final link = accountData['website_link']?.toString() ?? '';
        final user = accountData['username']?.toString() ?? '';
        final pass = accountData['password']?.toString() ?? '';

        _showAccountDetailsDialog(context, link, user, pass);
      } else {
        final errMsg = (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Book record not found or inactive.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading record: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<void> _openWebsiteLink(String urlString) async {
    if (urlString.trim().isEmpty) return;
    try {
      String formattedUrl = urlString.trim();
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        final uri = Uri.parse(urlString.trim());
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening website: $urlString'),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAccountDetailsDialog(BuildContext context, String link, String username, String password) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF121026),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          elevation: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Glowing Success Icon Badge
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 18),

                // Game Name Title & Badge
                Text(
                  widget.game.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Active Subscribed Record',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Credential Rows
                if (link.isNotEmpty) ...[
                  _buildCredentialRow('Website Link', link, icon: Icons.language_rounded, isLink: true),
                  const SizedBox(height: 10),
                ],
                if (username.isNotEmpty) ...[
                  _buildCredentialRow('Username', username, icon: Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                ],
                if (password.isNotEmpty) ...[
                  _buildCredentialRow('Password', password, icon: Icons.lock_outline_rounded),
                  const SizedBox(height: 10),
                ],

                if (link.isEmpty && username.isEmpty && password.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1733),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Subscription active. Login credentials will be assigned shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF221F3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                      ),
                    ),
                    if (link.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              if (link.isNotEmpty) {
                                _openWebsiteLink(link);
                              } else {
                                widget.onPlay();
                              }
                            },
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'Play Game',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCredentialRow(String label, String value, {required IconData icon, bool isLink = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1834),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D294B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF272346),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: isLink ? () => _openWebsiteLink(value) : null,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLink ? const Color(0xFF38BDF8) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: const Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFFFFD700), size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard!'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF100C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Blue Circle Icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF131D38),
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF3B82F6),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                // Title: Subscribe to [Game Name]?
                Text(
                  'Subscribe to ${widget.game.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Game Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'MARKET: ${widget.game.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  "Press OK to subscribe to ${widget.game.name} and unlock active game credentials!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),

                // Actions: Cancel & OK Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF25213B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // OK Button (Vibrant Indigo / Purple Button)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => _handleSubscribeAction(ctx),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
