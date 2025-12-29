import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';

/// Widget pro zobrazeni bio s podporou tagu, emoji a odkazu
class ProfileBio extends StatelessWidget {
  /// Text bio
  final String bio;

  /// Callback pri kliknuti na tag
  final ValueChanged<String>? onTagTap;

  /// Callback pri kliknuti na zminka (@user)
  final ValueChanged<String>? onMentionTap;

  /// Max pocet radku (null = bez limitu)
  final int? maxLines;

  /// Zobrazit "vice" pro zkraceny text?
  final bool showExpand;

  const ProfileBio({
    super.key,
    required this.bio,
    this.onTagTap,
    this.onMentionTap,
    this.maxLines,
    this.showExpand = true,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
      text: _buildTextSpan(context),
    );
  }

  TextSpan _buildTextSpan(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'(#\w+)|(@\w+)|(https?://[^\s]+)|(\n)',
      caseSensitive: false,
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(bio)) {
      // Text pred matchem
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: bio.substring(lastEnd, match.start),
          style: _defaultStyle,
        ));
      }

      final matched = match.group(0)!;

      if (matched.startsWith('#')) {
        // Hashtag
        spans.add(TextSpan(
          text: matched,
          style: _tagStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onTagTap?.call(matched.substring(1)),
        ));
      } else if (matched.startsWith('@')) {
        // Zminka
        spans.add(TextSpan(
          text: matched,
          style: _mentionStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onMentionTap?.call(matched.substring(1)),
        ));
      } else if (matched.startsWith('http')) {
        // URL
        spans.add(TextSpan(
          text: _shortenUrl(matched),
          style: _linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(matched),
        ));
      } else if (matched == '\n') {
        spans.add(const TextSpan(text: '\n'));
      }

      lastEnd = match.end;
    }

    // Zbytek textu
    if (lastEnd < bio.length) {
      spans.add(TextSpan(
        text: bio.substring(lastEnd),
        style: _defaultStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  TextStyle get _defaultStyle => TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  TextStyle get _tagStyle => TextStyle(
        fontSize: 14,
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _mentionStyle => TextStyle(
        fontSize: 14,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      );

  TextStyle get _linkStyle => TextStyle(
        fontSize: 14,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      var display = uri.host;
      if (uri.path.isNotEmpty && uri.path != '/') {
        display += uri.path.length > 15 ? '${uri.path.substring(0, 15)}...' : uri.path;
      }
      return display;
    } catch (_) {
      return url.length > 30 ? '${url.substring(0, 30)}...' : url;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Prednastavene tagy pro bio
class BioTags {
  static const List<BioTag> suggestions = [
    // Typy
    BioTag(emoji: '🌿', label: 'Indica Lover'),
    BioTag(emoji: '☀️', label: 'Sativa Fan'),
    BioTag(emoji: '⚖️', label: 'Hybrid'),

    // Aktivity
    BioTag(emoji: '📸', label: 'Photographer'),
    BioTag(emoji: '🎨', label: 'Artist'),
    BioTag(emoji: '🎵', label: 'Music Lover'),
    BioTag(emoji: '🎮', label: 'Gamer'),

    // Lokace
    BioTag(emoji: '🏙️', label: 'Prague'),
    BioTag(emoji: '🌲', label: 'Nature'),
    BioTag(emoji: '🏠', label: 'Homegrower'),

    // Komunita
    BioTag(emoji: '🕷️', label: 'OG Member'),
    BioTag(emoji: '🆕', label: 'Newbie'),
    BioTag(emoji: '🔥', label: 'Active'),
  ];
}

class BioTag {
  final String emoji;
  final String label;

  const BioTag({required this.emoji, required this.label});

  String get formatted => '$emoji $label';
}

/// Widget pro vyber tagu do bio
class BioTagPicker extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<String> onTagToggle;
  final int maxTags;

  const BioTagPicker({
    super.key,
    required this.selectedTags,
    required this.onTagToggle,
    this.maxTags = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vyber tagy (max $maxTags)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BioTags.suggestions.map((tag) {
            final isSelected = selectedTags.contains(tag.formatted);
            final canSelect = selectedTags.length < maxTags || isSelected;

            return GestureDetector(
              onTap: canSelect ? () => onTagToggle(tag.formatted) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(30)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      tag.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.primary
                            : canSelect
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Widget pro editaci bio s tagy
class BioEditor extends StatefulWidget {
  final String initialBio;
  final List<String> initialTags;
  final ValueChanged<String> onBioChanged;
  final ValueChanged<List<String>> onTagsChanged;
  final int maxBioLength;
  final int maxTags;

  const BioEditor({
    super.key,
    this.initialBio = '',
    this.initialTags = const [],
    required this.onBioChanged,
    required this.onTagsChanged,
    this.maxBioLength = 150,
    this.maxTags = 5,
  });

  @override
  State<BioEditor> createState() => _BioEditorState();
}

class _BioEditorState extends State<BioEditor> {
  late TextEditingController _controller;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBio);
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < widget.maxTags) {
        _selectedTags.add(tag);
      }
    });
    widget.onTagsChanged(_selectedTags);
  }

  String get _fullBio {
    final tagLine = _selectedTags.join(' | ');
    if (tagLine.isEmpty) return _controller.text;
    if (_controller.text.isEmpty) return tagLine;
    return '${_controller.text}\n$tagLine';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text input
        TextField(
          controller: _controller,
          maxLength: widget.maxBioLength,
          maxLines: 3,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Napis neco o sobe...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(color: AppColors.textMuted),
          ),
          onChanged: (value) {
            widget.onBioChanged(_fullBio);
          },
        ),

        const SizedBox(height: 16),

        // Tag picker
        BioTagPicker(
          selectedTags: _selectedTags,
          onTagToggle: _toggleTag,
          maxTags: widget.maxTags,
        ),

        const SizedBox(height: 16),

        // Preview
        Text(
          'Nahled:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ProfileBio(bio: _fullBio),
        ),
      ],
    );
  }
}

/// Zobrazeni lokace a webu
class ProfileInfoRow extends StatelessWidget {
  final String? location;
  final String? website;
  final VoidCallback? onWebsiteTap;

  const ProfileInfoRow({
    super.key,
    this.location,
    this.website,
    this.onWebsiteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (location == null && website == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (location != null && location!.isNotEmpty)
          _buildItem(
            icon: Icons.location_on,
            text: location!,
            color: AppColors.textMuted,
          ),
        if (website != null && website!.isNotEmpty)
          GestureDetector(
            onTap: onWebsiteTap ?? () => _launchUrl(website!),
            child: _buildItem(
              icon: Icons.link,
              text: _formatWebsite(website!),
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }

  String _formatWebsite(String url) {
    var display = url.replaceAll(RegExp(r'^https?://'), '');
    display = display.replaceAll(RegExp(r'^www\.'), '');
    if (display.endsWith('/')) {
      display = display.substring(0, display.length - 1);
    }
    return display;
  }

  Future<void> _launchUrl(String url) async {
    var finalUrl = url;
    if (!url.startsWith('http')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
