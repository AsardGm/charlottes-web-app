import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Widget pro zobrazení formátovaného textu
/// Podporuje: *bold*, _italic_, `code`, ~strikethrough~
class FormattedTextWidget extends StatelessWidget {
  final String text;
  final bool isMe;
  final double fontSize;

  const FormattedTextWidget({
    super.key,
    required this.text,
    required this.isMe,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parseText(text);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isMe ? Colors.white : AppColors.textPrimary,
          fontSize: fontSize,
          height: 1.3,
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _parseText(String input) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    var i = 0;

    while (i < input.length) {
      // Code block (`)
      if (input[i] == '`') {
        // Flush buffer
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }

        final end = input.indexOf('`', i + 1);
        if (end != -1) {
          final code = input.substring(i + 1, end);
          spans.add(TextSpan(
            text: code,
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: isMe
                  ? Colors.white.withAlpha(30)
                  : AppColors.surfaceLight,
              color: isMe ? Colors.white : AppColors.primary,
            ),
          ));
          i = end + 1;
          continue;
        }
      }

      // Bold (*)
      if (input[i] == '*' && i + 1 < input.length && input[i + 1] != '*') {
        // Flush buffer
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }

        final end = input.indexOf('*', i + 1);
        if (end != -1) {
          final bold = input.substring(i + 1, end);
          spans.add(TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
          i = end + 1;
          continue;
        }
      }

      // Italic (_)
      if (input[i] == '_' && i + 1 < input.length && input[i + 1] != '_') {
        // Flush buffer
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }

        final end = input.indexOf('_', i + 1);
        if (end != -1) {
          final italic = input.substring(i + 1, end);
          spans.add(TextSpan(
            text: italic,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
          i = end + 1;
          continue;
        }
      }

      // Strikethrough (~)
      if (input[i] == '~' && i + 1 < input.length && input[i + 1] != '~') {
        // Flush buffer
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }

        final end = input.indexOf('~', i + 1);
        if (end != -1) {
          final strike = input.substring(i + 1, end);
          spans.add(TextSpan(
            text: strike,
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ));
          i = end + 1;
          continue;
        }
      }

      buffer.write(input[i]);
      i++;
    }

    // Flush remaining buffer
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer.toString()));
    }

    return spans;
  }
}

/// Nápověda pro formátování
class FormattingHelpWidget extends StatelessWidget {
  const FormattingHelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Formatovani textu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildExample('*tucny*', 'tucny', FontWeight.bold, null, null),
          _buildExample('_kurziva_', 'kurziva', null, FontStyle.italic, null),
          _buildExample('~preskrtnuto~', 'preskrtnuto', null, null,
              TextDecoration.lineThrough),
          _buildExample('`kod`', 'kod', null, null, null, isCode: true),
        ],
      ),
    );
  }

  Widget _buildExample(
    String syntax,
    String result,
    FontWeight? weight,
    FontStyle? style,
    TextDecoration? decoration, {
    bool isCode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              syntax,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: isCode
                ? BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              result,
              style: TextStyle(
                fontSize: 13,
                fontWeight: weight,
                fontStyle: style,
                decoration: decoration,
                fontFamily: isCode ? 'monospace' : null,
                color: isCode ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
