import 'package:flutter/material.dart';

/// Vstupní pole pro psaní komentáře
///
/// Obsahuje textové pole a tlačítko pro odeslání.
/// Podporuje stav načítání během odesílání.
class CommentInput extends StatelessWidget {
  /// Controller pro textové pole
  final TextEditingController controller;

  /// Probíhá odesílání?
  final bool isPosting;

  /// Callback pro odeslání komentáře
  final VoidCallback onPost;

  const CommentInput({
    super.key,
    required this.controller,
    required this.isPosting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Textové pole
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Napište komentář...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            // Tlačítko odeslat
            IconButton.filled(
              onPressed: isPosting ? null : onPost,
              icon: isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
