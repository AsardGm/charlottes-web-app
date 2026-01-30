import 'package:flutter/material.dart';
import '../../theme/holotrop_colors.dart';

/// Radek terminalu s prefixem a textem
class TerminalLine {
  final String prefix;
  final String text;
  final Color? color;

  const TerminalLine({
    this.prefix = '>',
    required this.text,
    this.color,
  });
}

/// Terminalovy textovy vystup s typing efektem pro bio-hacks sekci
class TerminalText extends StatefulWidget {
  final List<TerminalLine> lines;
  final Duration lineDelay;
  final Duration charDelay;
  final VoidCallback? onComplete;

  const TerminalText({
    super.key,
    required this.lines,
    this.lineDelay = const Duration(milliseconds: 800),
    this.charDelay = const Duration(milliseconds: 25),
    this.onComplete,
  });

  @override
  State<TerminalText> createState() => _TerminalTextState();
}

class _TerminalTextState extends State<TerminalText> {
  final List<String> _displayedLines = [];
  int _currentLineIndex = 0;
  String _currentTypingText = '';
  bool _isTyping = false;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _startTyping();
    _startCursorBlink();
  }

  void _startCursorBlink() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    }
  }

  void _startTyping() async {
    for (int i = 0; i < widget.lines.length; i++) {
      if (!mounted) return;

      _currentLineIndex = i;
      _isTyping = true;
      final fullText = '${widget.lines[i].prefix} ${widget.lines[i].text}';

      for (int j = 0; j <= fullText.length; j++) {
        if (!mounted) return;
        await Future.delayed(widget.charDelay);
        if (mounted) {
          setState(() {
            _currentTypingText = fullText.substring(0, j);
          });
        }
      }

      _isTyping = false;
      if (mounted) {
        setState(() {
          _displayedLines.add(fullText);
          _currentTypingText = '';
        });
      }

      if (i < widget.lines.length - 1) {
        await Future.delayed(widget.lineDelay);
      }
    }

    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HolotropColors.terminalBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HolotropColors.terminalGreen.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HolotropColors.terminalGreen,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HOLOTROP_SYSTEM v1.0',
                style: TextStyle(
                  color: HolotropColors.terminalGreen.withAlpha(120),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Completed lines
          for (int i = 0; i < _displayedLines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _displayedLines[i],
                style: TextStyle(
                  color: _getLineColor(i),
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          // Currently typing line
          if (_currentTypingText.isNotEmpty || _isTyping)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _currentTypingText,
                    style: TextStyle(
                      color: _getLineColor(_currentLineIndex),
                      fontSize: 13,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                  if (_showCursor)
                    TextSpan(
                      text: '_',
                      style: TextStyle(
                        color: HolotropColors.terminalGreen,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          // Idle cursor when done
          if (!_isTyping &&
              _displayedLines.length == widget.lines.length &&
              _showCursor)
            Text(
              '_',
              style: TextStyle(
                color: HolotropColors.terminalGreen,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Color _getLineColor(int index) {
    if (index < widget.lines.length && widget.lines[index].color != null) {
      return widget.lines[index].color!;
    }
    return HolotropColors.terminalGreen;
  }
}
