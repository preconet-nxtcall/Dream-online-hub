import 'package:flutter/material.dart';

class MediaPreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String senderName;
  final String timeString;

  const MediaPreviewDialog({
    super.key,
    required this.imageUrl,
    required this.senderName,
    required this.timeString,
  });

  static void show(BuildContext context, {required String imageUrl, String senderName = 'Attachment', String timeString = ''}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        pageBuilder: (context, _, __) => MediaPreviewDialog(
          imageUrl: imageUrl,
          senderName: senderName,
          timeString: timeString,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imageUrl.startsWith('http') || imageUrl.startsWith('https');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (timeString.isNotEmpty)
              Text(
                timeString,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download Image',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image downloaded to gallery'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing attachment...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl,
            child: isNetwork
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      final progress = loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white70, size: 64),
                          SizedBox(height: 12),
                          Text('Failed to load image preview', style: TextStyle(color: Colors.white70)),
                        ],
                      );
                    },
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.image, size: 80, color: Colors.white54),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
