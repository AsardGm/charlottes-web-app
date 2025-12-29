import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/theme.dart';

/// Widget pro zobrazení zprávy se souborem
class FileMessageWidget extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final bool isMe;

  const FileMessageWidget({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.isMe,
  });

  IconData _getFileIcon() {
    if (mimeType.startsWith('application/pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.startsWith('application/msword') ||
        mimeType.contains('wordprocessingml')) {
      return Icons.description;
    } else if (mimeType.startsWith('application/vnd.ms-excel') ||
        mimeType.contains('spreadsheetml')) {
      return Icons.table_chart;
    } else if (mimeType.startsWith('application/vnd.ms-powerpoint') ||
        mimeType.contains('presentationml')) {
      return Icons.slideshow;
    } else if (mimeType.startsWith('application/zip') ||
        mimeType.startsWith('application/x-rar') ||
        mimeType.startsWith('application/x-7z')) {
      return Icons.folder_zip;
    } else if (mimeType.startsWith('text/')) {
      return Icons.article;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    if (mimeType.startsWith('application/pdf')) {
      return Colors.red;
    } else if (mimeType.startsWith('application/msword') ||
        mimeType.contains('wordprocessingml')) {
      return Colors.blue;
    } else if (mimeType.startsWith('application/vnd.ms-excel') ||
        mimeType.contains('spreadsheetml')) {
      return Colors.green;
    } else if (mimeType.startsWith('application/vnd.ms-powerpoint') ||
        mimeType.contains('presentationml')) {
      return Colors.orange;
    } else if (mimeType.startsWith('application/zip') ||
        mimeType.startsWith('application/x-rar') ||
        mimeType.startsWith('application/x-7z')) {
      return Colors.amber;
    }
    return AppColors.primary;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _openFile() async {
    final url = Uri.parse(fileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withAlpha(30)
                    : _getFileColor().withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(),
                color: isMe ? Colors.white : _getFileColor(),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFileSize(fileSize),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? Colors.white.withAlpha(180)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Download icon
            Icon(
              Icons.download,
              size: 20,
              color: isMe ? Colors.white70 : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
