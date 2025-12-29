import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme.dart';
import '../../../models/poll_model.dart';
import '../../../providers/chat_provider.dart';

/// Widget pro zobrazení ankety
class PollMessageWidget extends ConsumerStatefulWidget {
  final String pollId;
  final bool isMe;

  const PollMessageWidget({
    super.key,
    required this.pollId,
    required this.isMe,
  });

  @override
  ConsumerState<PollMessageWidget> createState() => _PollMessageWidgetState();
}

class _PollMessageWidgetState extends ConsumerState<PollMessageWidget> {
  PollModel? _poll;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final poll = await chatService.getPoll(widget.pollId);
      if (mounted) {
        setState(() {
          _poll = poll;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _vote(String optionId) async {
    if (_poll == null || !_poll!.isActive) return;

    final chatService = ref.read(chatServiceProvider);
    final currentUserId = chatService.currentUserId;
    if (currentUserId == null) return;

    final hasVoted = _poll!.hasUserVoted(currentUserId, optionId);

    try {
      if (hasVoted) {
        await chatService.unvotePoll(widget.pollId, optionId);
      } else {
        // Pro single choice, odeber předchozí hlasy
        if (_poll!.pollType == 'single') {
          for (final option in _poll!.options) {
            if (_poll!.hasUserVoted(currentUserId, option.id)) {
              await chatService.unvotePoll(widget.pollId, option.id);
            }
          }
        }
        await chatService.votePoll(widget.pollId, optionId);
      }
      await _loadPoll();
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_poll == null) {
      return Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Anketa nenalezena',
          style: TextStyle(
            color: widget.isMe ? Colors.white70 : AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final currentUserId = ref.read(chatServiceProvider).currentUserId;
    final totalVotes = _poll!.totalVotes;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll icon and question
          Row(
            children: [
              Icon(
                Icons.poll,
                size: 18,
                color: widget.isMe ? Colors.white70 : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Anketa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isMe ? Colors.white70 : AppColors.primary,
                ),
              ),
              if (_poll!.isAnonymous) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.visibility_off,
                  size: 14,
                  color: widget.isMe ? Colors.white54 : AppColors.textMuted,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Question
          Text(
            _poll!.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.isMe ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Options
          ...(_poll!.options.map((option) {
            final voteCount = _poll!.getVoteCount(option.id);
            final percentage =
                totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
            final hasVoted = currentUserId != null &&
                _poll!.hasUserVoted(currentUserId, option.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _poll!.isActive ? () => _vote(option.id) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: hasVoted
                        ? (widget.isMe
                            ? Colors.white.withAlpha(40)
                            : AppColors.primary.withAlpha(30))
                        : (widget.isMe
                            ? Colors.white.withAlpha(20)
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(8),
                    border: hasVoted
                        ? Border.all(
                            color: widget.isMe
                                ? Colors.white.withAlpha(80)
                                : AppColors.primary.withAlpha(80),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Progress bar
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(
                              widget.isMe
                                  ? Colors.white.withAlpha(20)
                                  : AppColors.primary.withAlpha(20),
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Row(
                        children: [
                          // Radio/Check indicator
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: _poll!.pollType == 'single'
                                  ? BoxShape.circle
                                  : BoxShape.rectangle,
                              borderRadius: _poll!.pollType == 'multiple'
                                  ? BorderRadius.circular(4)
                                  : null,
                              border: Border.all(
                                color: hasVoted
                                    ? (widget.isMe
                                        ? Colors.white
                                        : AppColors.primary)
                                    : (widget.isMe
                                        ? Colors.white54
                                        : AppColors.textMuted),
                                width: 2,
                              ),
                              color: hasVoted
                                  ? (widget.isMe
                                      ? Colors.white
                                      : AppColors.primary)
                                  : Colors.transparent,
                            ),
                            child: hasVoted
                                ? Icon(
                                    Icons.check,
                                    size: 12,
                                    color: widget.isMe
                                        ? AppColors.primary
                                        : Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          // Option text
                          Expanded(
                            child: Text(
                              option.optionText,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.isMe
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Vote count
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isMe
                                  ? Colors.white70
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          })),
          // Footer
          Row(
            children: [
              Text(
                '$totalVotes ${totalVotes == 1 ? 'hlas' : 'hlasu'}',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isMe ? Colors.white54 : AppColors.textMuted,
                ),
              ),
              if (_poll!.expiresAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    color: widget.isMe ? Colors.white54 : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _poll!.isExpired ? 'Ukonceno' : 'Aktivni',
                  style: TextStyle(
                    fontSize: 11,
                    color: _poll!.isExpired
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Dialog pro vytvoření ankety
class CreatePollDialog extends StatefulWidget {
  final String conversationId;
  final Function(String question, List<String> options) onCreate;

  const CreatePollDialog({
    super.key,
    required this.conversationId,
    required this.onCreate,
  });

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _create() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadej otazku a alespon 2 moznosti')),
      );
      return;
    }

    widget.onCreate(question, options);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.poll, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Vytvorit anketu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Question
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Otazka',
                  hintText: 'Napiste svou otazku...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Options
              Text(
                'Moznosti',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Moznost ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeOption(index),
                          icon: Icon(Icons.remove_circle, color: AppColors.error),
                          iconSize: 20,
                        ),
                      ],
                    ],
                  ),
                );
              }),
              // Add option button
              if (_optionControllers.length < 10)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: Icon(Icons.add, color: AppColors.primary),
                  label: Text(
                    'Pridat moznost',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              const SizedBox(height: 20),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Zrusit',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Vytvorit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
