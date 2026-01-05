import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import '../../utils/haptic_utils.dart';

/// TextField s podporou @mentions
///
/// Automaticky detekuje @ a zobrazuje popup pro výběr uživatele.
/// Mentions jsou uloženy jako @[username](userId) v textu.
class MentionTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;

  const MentionTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.focusNode,
    this.onChanged,
    this.decoration,
  });

  @override
  ConsumerState<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends ConsumerState<MentionTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String _searchQuery = '';
  int _mentionStartIndex = -1;
  bool _isShowingOverlay = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _removeOverlay();
      return;
    }

    final cursorPos = selection.baseOffset;

    // Najdi @ před kurzorem
    int atIndex = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      final char = text[i];
      if (char == '@') {
        atIndex = i;
        break;
      }
      if (char == ' ' || char == '\n') {
        break;
      }
    }

    if (atIndex >= 0) {
      final query = text.substring(atIndex + 1, cursorPos);
      // Validuj query - pouze písmena, čísla, podtržítka
      if (RegExp(r'^[a-zA-Z0-9_]*$').hasMatch(query)) {
        _mentionStartIndex = atIndex;
        _searchQuery = query;
        _showOverlay();
        // Spusť vyhledávání
        if (query.isNotEmpty) {
          ref.read(userSearchProvider.notifier).search(query);
        }
        return;
      }
    }

    _removeOverlay();
  }

  void _showOverlay() {
    if (_isShowingOverlay) return;
    _isShowingOverlay = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface,
            child: _MentionSuggestions(
              query: _searchQuery,
              onSelect: _insertMention,
              onDismiss: _removeOverlay,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (!_isShowingOverlay) return;
    _isShowingOverlay = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _mentionStartIndex = -1;
    _searchQuery = '';
  }

  void _insertMention(UserModel user) {
    HapticUtils.selectionClick();

    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Nahraď @query za @username
    final before = text.substring(0, _mentionStartIndex);
    final after = text.substring(cursorPos);
    final mention = '@${user.username} ';

    final newText = '$before$mention$after';
    widget.controller.text = newText;

    // Nastav kurzor za mention
    final newCursorPos = _mentionStartIndex + mention.length;
    widget.controller.selection = TextSelection.collapsed(offset: newCursorPos);

    widget.onChanged?.call(newText);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        onChanged: widget.onChanged,
        decoration: widget.decoration ?? InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Widget pro zobrazení návrhů uživatelů
class _MentionSuggestions extends ConsumerWidget {
  final String query;
  final ValueChanged<UserModel> onSelect;
  final VoidCallback onDismiss;

  const _MentionSuggestions({
    required this.query,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(userSearchProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: searchResults.when(
        data: (users) {
          if (users.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                query.isEmpty
                    ? 'Zacnete psat jmeno...'
                    : 'Zadny uzivatel nenalezen',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserTile(
                user: user,
                onTap: () => onSelect(user),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Chyba pri hledani',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

/// Tile pro jednoho uživatele v seznamu
class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              backgroundColor: AppColors.surfaceLight,
              child: user.avatarUrl == null
                  ? Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Text(
                      user.bio!,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility pro parsování mentions a hashtagů v textu
class MentionUtils {
  MentionUtils._();

  /// Regex pro detekci @username
  static final RegExp mentionPattern = RegExp(r'@([a-zA-Z0-9_]+)');

  /// Regex pro detekci #hashtag
  static final RegExp hashtagPattern = RegExp(r'#([a-zA-Z0-9_\u00C0-\u024F]+)');

  /// Kombinovaný pattern pro mentions a hashtagy
  static final RegExp combinedPattern = RegExp(r'(@[a-zA-Z0-9_]+|#[a-zA-Z0-9_\u00C0-\u024F]+)');

  /// Extrahuje všechny username z textu
  static List<String> extractMentions(String text) {
    return mentionPattern
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
  }

  /// Extrahuje všechny hashtagy z textu
  static List<String> extractHashtags(String text) {
    return hashtagPattern
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
  }

  /// Vytvoří TextSpan s klikatelnými mentions a hashtagy
  static List<InlineSpan> buildRichSpans(
    String text, {
    TextStyle? normalStyle,
    TextStyle? mentionStyle,
    TextStyle? hashtagStyle,
    void Function(String username)? onMentionTap,
    void Function(String hashtag)? onHashtagTap,
  }) {
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in combinedPattern.allMatches(text)) {
      // Text před match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: normalStyle,
        ));
      }

      final matchText = match.group(0)!;

      if (matchText.startsWith('@')) {
        // Mention
        final username = matchText.substring(1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: onMentionTap != null ? () => onMentionTap(username) : null,
            child: Text(
              matchText,
              style: mentionStyle ?? TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      } else if (matchText.startsWith('#')) {
        // Hashtag
        final hashtag = matchText.substring(1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: onHashtagTap != null ? () => onHashtagTap(hashtag) : null,
            child: Text(
              matchText,
              style: hashtagStyle ?? TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Text po posledním match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: normalStyle,
      ));
    }

    return spans;
  }
}

/// Widget pro zobrazení textu s klikatelnými mentions a hashtagy
class MentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final void Function(String username)? onMentionTap;
  final void Function(String hashtag)? onHashtagTap;
  final int? maxLines;
  final TextOverflow? overflow;

  const MentionText({
    super.key,
    required this.text,
    this.style,
    this.onMentionTap,
    this.onHashtagTap,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final spans = MentionUtils.buildRichSpans(
      text,
      normalStyle: style,
      mentionStyle: style?.copyWith(
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
      ),
      hashtagStyle: style?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      onMentionTap: onMentionTap,
      onHashtagTap: onHashtagTap,
    );

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
