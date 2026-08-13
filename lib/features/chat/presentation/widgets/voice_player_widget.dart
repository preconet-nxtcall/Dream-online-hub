import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../repositories/chat_repository.dart';
import '../../../../utils/logger.dart';

class VoicePlayerWidget extends StatefulWidget {
  /// Duration string (e.g. "0:18" or "01:23").
  final String durationStr;

  /// S3/CDN URL to the actual audio file. May be null while uploading.
  final String? audioUrl;

  /// Local file path used for playback before cloud upload completes.
  final String? localFilePath;

  final bool isMe;

  const VoicePlayerWidget({
    super.key,
    required this.durationStr,
    this.audioUrl,
    this.localFilePath,
    required this.isMe,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  final GlobalKey _waveformKey = GlobalKey(); // for accurate seek width
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Duration _total = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _playerSub;
  StreamSubscription? _posSub;
  bool _isLoadingAudio = false;
  bool _isInitialized = false;
  bool _loadFailed = false;

  ChatRepository _getChatRepo(BuildContext context) {
    try {
      return context.read<ChatRepository>();
    } catch (_) {
      return ChatRepositoryImpl();
    }
  }

  @override
  void initState() {
    super.initState();
    _total = _parseDuration(widget.durationStr);
    _initPlayer();
  }

  @override
  void didUpdateWidget(VoicePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.audioUrl != oldWidget.audioUrl ||
            widget.localFilePath != oldWidget.localFilePath) &&
        (widget.audioUrl?.isNotEmpty == true || widget.localFilePath?.isNotEmpty == true)) {
      _isInitialized = false;
      _loadFailed = false;
      _isLoadingAudio = false;
      _initPlayer();
    }
  }

  Duration _parseDuration(String str) {
    try {
      final parts = str.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return Duration(minutes: m, seconds: s);
      }
    } catch (_) {}
    return const Duration(seconds: 15);
  }

  String? _resolveLocalFilePath(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    String clean = rawPath.trim();
    if (clean.startsWith('file://')) {
      try {
        clean = Uri.parse(clean).toFilePath();
      } catch (_) {
        clean = clean.replaceFirst(RegExp(r'^file://+'), '');
        if (Platform.isWindows && clean.startsWith('/') && clean.length > 2 && clean[2] == ':') {
          clean = clean.substring(1);
        }
      }
    } else if (Platform.isWindows && clean.startsWith('/') && clean.length > 2 && clean[2] == ':') {
      clean = clean.substring(1);
    }

    try {
      final file = File(clean);
      if (file.existsSync()) {
        return clean;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _initPlayer() async {
    if (_isLoadingAudio || _isInitialized) return;

    // Detect if localFilePath OR audioUrl is a valid local file on device
    final validLocalPath = _resolveLocalFilePath(widget.localFilePath) ??
        _resolveLocalFilePath(widget.audioUrl);

    final hasRemote = widget.audioUrl != null &&
        widget.audioUrl!.isNotEmpty &&
        validLocalPath == null;

    if (validLocalPath == null && !hasRemote) {
      return;
    }

    _isLoadingAudio = true;
    _loadFailed = false;

    try {
      if (validLocalPath != null) {
        int retries = 0;
        while (retries < 3) {
          try {
            await _player.setFilePath(validLocalPath);
            break;
          } catch (err) {
            retries++;
            if (retries >= 3) rethrow;
            await Future.delayed(Duration(milliseconds: 150 * retries));
          }
        }
      } else {
        String playbackUrl = widget.audioUrl!;

        // Prepend chatBaseUrl if path is relative
        if (!playbackUrl.startsWith('http://') && !playbackUrl.startsWith('https://')) {
          final baseUrl = ApiEndpoints.chatBaseUrl.endsWith('/')
              ? ApiEndpoints.chatBaseUrl.substring(0, ApiEndpoints.chatBaseUrl.length - 1)
              : ApiEndpoints.chatBaseUrl;
          final path = playbackUrl.startsWith('/') ? playbackUrl : '/$playbackUrl';
          playbackUrl = '$baseUrl$path';
        }

        // Fetch dynamic signed URL from GET /play-url if audioUrl is a cloud fileKey or unsigned URL
        final isSigned = playbackUrl.contains('Signature=') ||
            playbackUrl.contains('X-Amz-Signature=') ||
            playbackUrl.contains('AWSAccessKeyId=');

        if (!isSigned) {
          if (mounted) {
            final repo = _getChatRepo(context);
            final resolved = await repo.getPlayVoiceUrl(widget.audioUrl!);
            if (resolved != null && resolved.isNotEmpty) {
              playbackUrl = resolved;
            }
          }
        }

        if (playbackUrl.isEmpty) {
          if (mounted) setState(() => _loadFailed = true);
          return;
        }

        try {
          await _player.setUrl(playbackUrl);
        } catch (e) {
          bool resolvedSuccess = false;
          // Fallback 1: Try getPlayVoiceUrl from repository
          if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty && mounted) {
            try {
              final repo = _getChatRepo(context);
              final resolvedUrl = await repo.getPlayVoiceUrl(widget.audioUrl!);
              if (resolvedUrl != null &&
                  resolvedUrl.isNotEmpty &&
                  resolvedUrl != playbackUrl) {
                await _player.setUrl(resolvedUrl);
                resolvedSuccess = true;
              }
            } catch (_) {}
          }

          // Fallback 2: If path had no protocol, try API media host or PHP upload root
          if (!resolvedSuccess && widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
            final filename = widget.audioUrl!.split('/').last;
            final hostFallbacks = [
              '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/uploads/photos/$filename',
              '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/uploads/voice/$filename',
              '${ApiEndpoints.chatBaseUrl}/uploads/$filename',
            ];

            for (final fallback in hostFallbacks) {
              if (fallback == playbackUrl) continue;
              try {
                await _player.setUrl(fallback);
                resolvedSuccess = true;
                break;
              } catch (_) {}
            }
          }

          if (!resolvedSuccess) {
            rethrow;
          }
        }
      }

      _total = _player.duration ?? _total;
      _isInitialized = true;

      _playerSub?.cancel();
      _playerSub = _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _position = _total;
            _player.seek(Duration.zero);
          }
        });
      });

      _posSub?.cancel();
      _posSub = _player.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() => _position = pos);
      });
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('aborted') || errStr.contains('interrupted') || errStr.contains('cancel')) {
        AppLogger.info('[VoicePlayerWidget] Player connection aborted during reload, ignoring transient interrupt.');
      } else {
        AppLogger.error('[VoicePlayerWidget] Audio load error: $e');
        if (mounted) setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized || _loadFailed) {
      _loadFailed = false;
      _isInitialized = false;
      _isLoadingAudio = false;
      await _initPlayer();
    }
    if (_loadFailed || !_isInitialized) return;
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (e) {
      AppLogger.error('[VoicePlayerWidget] Play error: $e');
    }
  }

  Future<void> _cycleSpeed() async {
    double next;
    if (_playbackSpeed == 1.0) {
      next = 1.5;
    } else if (_playbackSpeed == 1.5) {
      next = 2.0;
    } else {
      next = 1.0;
    }
    setState(() => _playbackSpeed = next);
    try {
      await _player.setSpeed(next);
    } catch (_) {}
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // High contrast font & UI colors:
    // In light mode: dark black/grey text (#111B21) for 100% visibility on light green & white bubbles
    // In dark mode: crisp white text (#E9EDEF)
    final textColor = isDark
        ? const Color(0xFFE9EDEF)
        : (widget.isMe ? const Color(0xFF111B21) : const Color(0xFF374151));

    final playBtnBg = isDark
        ? const Color(0xFF25D366)
        : (widget.isMe ? const Color(0xFF075E54) : const Color(0xFF075E54));

    const playBtnIconColor = Colors.white;

    final avatarBg = isDark
        ? (widget.isMe ? Colors.white24 : const Color(0xFF25D366).withValues(alpha: 0.2))
        : (widget.isMe ? const Color(0xFF075E54).withValues(alpha: 0.15) : const Color(0xFF075E54).withValues(alpha: 0.1));

    final avatarIconColor = isDark
        ? (widget.isMe ? Colors.white : const Color(0xFF25D366))
        : const Color(0xFF075E54);

    final activeWaveformColor = isDark
        ? (widget.isMe ? const Color(0xFF25D366) : const Color(0xFF25D366))
        : (widget.isMe ? const Color(0xFF075E54) : const Color(0xFF25D366));

    final inactiveWaveformColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : (widget.isMe
            ? const Color(0xFF075E54).withValues(alpha: 0.25)
            : const Color(0xFF075E54).withValues(alpha: 0.2));

    final speedBg = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : (widget.isMe
            ? const Color(0xFF075E54).withValues(alpha: 0.12)
            : const Color(0xFF075E54).withValues(alpha: 0.1));

    final speedTextColor = isDark
        ? const Color(0xFFE9EDEF)
        : const Color(0xFF075E54);

    final double progress = _total.inMilliseconds > 0
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // WhatsApp-style Profile Avatar with Mic Badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarBg,
                  child: Icon(
                    Icons.person_rounded,
                    color: avatarIconColor,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366), // WhatsApp signature green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Play / Pause Circle Button
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: playBtnBg,
                  shape: BoxShape.circle,
                ),
                child: _isLoadingAudio
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: playBtnIconColor,
                        ),
                      )
                    : (_loadFailed
                        ? Icon(Icons.error_outline_rounded,
                            color: Colors.red.shade300, size: 22)
                        : Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: playBtnIconColor,
                            size: 22,
                          )),
              ),
            ),
            const SizedBox(width: 8),

            // Seekable Waveform Bar
            Expanded(
              child: GestureDetector(
                onTapDown: (details) async {
                  if (_loadFailed) return;
                  final box = _waveformKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final ratio =
                      (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                  final targetMs =
                      (ratio * _total.inMilliseconds).round();
                  await _player.seek(Duration(milliseconds: targetMs));
                },
                child: SizedBox(
                  key: _waveformKey,
                  height: 30,
                  child: Row(
                    children: List.generate(20, (index) {
                      final barRatio = (index + 1) / 20.0;
                      final isActive = barRatio <= progress;
                      const heights = [
                        10, 16, 26, 14, 28, 20, 12, 24, 18, 26,
                        14, 22, 12, 18, 28, 16, 22, 14, 20, 12
                      ];
                      final barHeight = heights[index % heights.length].toDouble();
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.2),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isActive
                                ? activeWaveformColor
                                : inactiveWaveformColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Speed Chip (1x / 1.5x / 2x)
            GestureDetector(
              onTap: _cycleSpeed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: speedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_playbackSpeed.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: speedTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Duration Info with WhatsApp Mic Icon
        Padding(
          padding: const EdgeInsets.only(left: 48.0),
          child: Row(
            children: [
              Icon(
                Icons.mic_rounded,
                size: 11,
                color: _loadFailed ? Colors.red.shade300 : const Color(0xFF25D366),
              ),
              const SizedBox(width: 4),
              Text(
                _loadFailed
                    ? 'Audio unavailable'
                    : '${_fmt(_position)} / ${_fmt(_total)}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: _loadFailed ? Colors.red.shade300 : textColor,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
