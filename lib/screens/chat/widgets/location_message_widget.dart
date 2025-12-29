import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/theme.dart';

/// Widget pro zobrazení zprávy s polohou
class LocationMessageWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final bool isMe;

  const LocationMessageWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.isMe,
  });

  Future<void> _openInMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openInMaps,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withAlpha(30)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.map,
                      size: 48,
                      color: isMe
                          ? Colors.white.withAlpha(150)
                          : AppColors.textMuted,
                    ),
                  ),
                  // Pin
                  Center(
                    child: Icon(
                      Icons.location_on,
                      size: 32,
                      color: isMe ? Colors.white : AppColors.error,
                    ),
                  ),
                  // Open in maps hint
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Otevrit',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (address != null && address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: isMe ? Colors.white70 : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Coordinates
            const SizedBox(height: 4),
            Text(
              '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withAlpha(150)
                    : AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
