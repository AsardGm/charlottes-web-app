import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/theme.dart';
import '../../models/category_model.dart';
import '../../models/thread_type_model.dart';
import '../../providers/posts_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/thread_type_provider.dart';
import '../../services/storage_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _storageService = StorageService();
  XFile? _selectedImage;
  bool _isLoading = false;
  CategoryModel? _selectedCategory;
  ThreadTypeModel? _selectedThreadType;
  DateTime? _selectedDeadline;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _storageService.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDeadline ?? DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      if (time != null) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _clearDeadline() {
    setState(() => _selectedDeadline = null);
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Napiste neco...')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadPostImage(_selectedImage!);
      }

      await ref.read(postsProvider.notifier).createPost(
            _contentController.text.trim(),
            imageUrl: imageUrl,
            categoryId: _selectedCategory?.id,
            threadTypeId: _selectedThreadType?.id,
            deadline: _selectedDeadline,
          );

      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prispevek vytvoren!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final threadTypesAsync = ref.watch(threadTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novy prispevek'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        actions: [
          FilledButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publikovat'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thread type selector
            threadTypesAsync.when(
              data: (threadTypes) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Typ vlakna',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: threadTypes.map((threadType) {
                        final isSelected =
                            _selectedThreadType?.id == threadType.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ThreadTypeChip(
                            threadType: threadType,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedThreadType =
                                    isSelected ? null : threadType;
                                // Vymaž deadline pokud typ nepodporuje
                                if (_selectedThreadType?.hasDeadline != true) {
                                  _selectedDeadline = null;
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Category selector
            categoriesAsync.when(
              data: (categories) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategorie',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = _selectedCategory?.id == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory =
                                      isSelected ? null : category;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? category.colorValue.withAlpha(30)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? category.colorValue
                                        : Colors.white.withAlpha(10),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.iconData,
                                      size: 16,
                                      color: isSelected
                                          ? category.colorValue
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? category.colorValue
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Deadline selector (pouze pro typy s deadline)
            if (_selectedThreadType?.hasDeadline == true) ...[
              Text(
                'Termin',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDeadline,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _selectedDeadline != null
                            ? _formatDeadline(_selectedDeadline!)
                            : 'Vybrat termin',
                      ),
                    ),
                  ),
                  if (_selectedDeadline != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearDeadline,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              decoration: InputDecoration(
                hintText: _getHintText(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galerie'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Fotoaparat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getHintText() {
    if (_selectedThreadType == null) {
      return 'Co mate na mysli?';
    }

    switch (_selectedThreadType!.slug) {
      case 'discussion':
        return 'Zacnete diskuzi...';
      case 'question':
        return 'Poloztesvou otazku...';
      case 'case':
        return 'Popiste problem nebo pripad...';
      case 'proposal':
        return 'Popiste svuj navrh nebo napad...';
      case 'announcement':
        return 'Napiste oznameni...';
      default:
        return 'Co mate na mysli?';
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.inDays == 0) {
      return 'Dnes ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Zitra ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
    } else {
      return '${deadline.day}.${deadline.month}. ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _ThreadTypeChip extends StatelessWidget {
  final ThreadTypeModel threadType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThreadTypeChip({
    required this.threadType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? threadType.colorValue.withAlpha(30)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? threadType.colorValue
                  : Colors.white.withAlpha(10),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                threadType.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                threadType.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? threadType.colorValue
                      : AppColors.textSecondary,
                ),
              ),
              if (threadType.hasDeadline) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: isSelected
                      ? threadType.colorValue
                      : AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
