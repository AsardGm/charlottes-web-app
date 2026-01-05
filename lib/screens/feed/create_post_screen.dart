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
import '../../widgets/common/mention_text_field.dart';

/// Obrazovka pro vytvoreni noveho prispevku - Functional Dark design
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.functionalSurface,
          ),
          dialogBackgroundColor: AppColors.functionalBg,
        ),
        child: child!,
      ),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDeadline ?? DateTime.now().add(const Duration(hours: 1)),
        ),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.functionalSurface,
            ),
            dialogBackgroundColor: AppColors.functionalBg,
          ),
          child: child!,
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
        SnackBar(
          content: const Text('Napiste neco...'),
          backgroundColor: AppColors.functionalSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                const Text('Prispevek vytvoren!'),
              ],
            ),
            backgroundColor: AppColors.functionalSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: ${e.toString()}'),
            backgroundColor: AppColors.functionalSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        elevation: 0,
        title: const Text(
          'Novy prispevek',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.functionalMuted),
          onPressed: () => context.go('/'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isLoading ? null : _createPost,
              style: TextButton.styleFrom(
                backgroundColor: _isLoading
                    ? AppColors.functionalBorder
                    : AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.functionalMuted,
                      ),
                    )
                  : const Text(
                      'Publikovat',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.functionalBorder.withAlpha(128),
          ),
        ),
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
                      color: AppColors.functionalMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
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
                      color: AppColors.functionalMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
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
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent.withAlpha(25)
                                      : AppColors.functionalSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.iconData,
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.functionalMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.accent
                                            : Colors.white,
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
                  const SizedBox(height: 20),
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
                  color: AppColors.functionalMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectDeadline,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.functionalSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedDeadline != null
                                  ? AppColors.accent.withAlpha(100)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 18,
                                color: _selectedDeadline != null
                                    ? AppColors.accent
                                    : AppColors.functionalMuted,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDeadline != null
                                    ? _formatDeadline(_selectedDeadline!)
                                    : 'Vybrat termin',
                                style: TextStyle(
                                  color: _selectedDeadline != null
                                      ? Colors.white
                                      : AppColors.functionalMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedDeadline != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _clearDeadline,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.functionalSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.functionalMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Text input
            Container(
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MentionTextField(
                controller: _contentController,
                maxLines: null,
                minLines: 6,
                hintText: _getHintText(),
                decoration: InputDecoration(
                  hintText: _getHintText(),
                  hintStyle: TextStyle(
                    color: AppColors.functionalMuted,
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.functionalSurface,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected image preview
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _removeImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Image picker buttons
            Row(
              children: [
                Expanded(
                  child: _MediaButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galerie',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MediaButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Fotoaparat',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
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

/// Tlacitko pro vyber media - Functional Dark design
class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.functionalSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.functionalMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.functionalMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thread type chip - Functional Dark design
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
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withAlpha(25)
                : AppColors.functionalSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 1.5,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.accent : Colors.white,
                ),
              ),
              if (threadType.hasDeadline) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: isSelected ? AppColors.accent : AppColors.functionalMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
