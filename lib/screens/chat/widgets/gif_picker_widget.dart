import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/theme.dart';

/// Widget pro výběr GIFu z Tenor API
class GifPickerWidget extends StatefulWidget {
  final Function(String gifUrl) onGifSelected;

  const GifPickerWidget({
    super.key,
    required this.onGifSelected,
  });

  @override
  State<GifPickerWidget> createState() => _GifPickerWidgetState();
}

class _GifPickerWidgetState extends State<GifPickerWidget> {
  final _searchController = TextEditingController();
  List<GifItem> _gifs = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(
        'https://tenor.googleapis.com/v2/featured'
        '?key=${ApiConfig.tenorApiKey}'
        '&client_key=${ApiConfig.tenorClientKey}'
        '&limit=30',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List)
            .map((r) => GifItem.fromJson(r))
            .toList();
        setState(() => _gifs = results);
      }
    } catch (_) {
      // Fallback - prázdný seznam
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadTrending();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(
        'https://tenor.googleapis.com/v2/search'
        '?key=${ApiConfig.tenorApiKey}'
        '&client_key=${ApiConfig.tenorClientKey}'
        '&q=${Uri.encodeComponent(query)}'
        '&limit=30',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List)
            .map((r) => GifItem.fromJson(r))
            .toList();
        setState(() => _gifs = results);
      }
    } catch (_) {
      // Ignore errors
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hledat GIF...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // GIF grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gifs.isEmpty
                    ? Center(
                        child: Text(
                          'Zadne GIFy',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _gifs.length,
                        itemBuilder: (context, index) {
                          final gif = _gifs[index];
                          return GestureDetector(
                            onTap: () => widget.onGifSelected(gif.url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                gif.previewUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: AppColors.surfaceLight,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: progress.expectedTotalBytes !=
                                                null
                                            ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stack) {
                                  return Container(
                                    color: AppColors.surfaceLight,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: AppColors.textMuted,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Powered by Tenor
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by ',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Tenor',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GifItem {
  final String id;
  final String url;
  final String previewUrl;

  GifItem({
    required this.id,
    required this.url,
    required this.previewUrl,
  });

  factory GifItem.fromJson(Map<String, dynamic> json) {
    final mediaFormats = json['media_formats'] as Map<String, dynamic>;

    // Použij gif formát pro odeslání
    final gifData = mediaFormats['gif'] as Map<String, dynamic>?;
    final gifUrl = gifData?['url'] as String? ?? '';

    // Použij tinygif pro náhled
    final tinyGifData = mediaFormats['tinygif'] as Map<String, dynamic>?;
    final previewUrl = tinyGifData?['url'] as String? ?? gifUrl;

    return GifItem(
      id: json['id'] as String,
      url: gifUrl,
      previewUrl: previewUrl,
    );
  }
}
