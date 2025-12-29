import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _usernameController.text = user.username;
      _bioController.text = user.bio ?? '';
      _websiteController.text = user.website ?? '';
      _locationController.text = user.location ?? '';
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: Text(
                'Vyfotit',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                'Pouzij fotoaparat',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: AppColors.info),
              ),
              title: Text(
                'Vybrat z galerie',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                'Vyber existujici fotku',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, color: AppColors.error),
              ),
              title: Text(
                'Odstranit fotku',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeAvatar();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final bytes = await image.readAsBytes();
      await ref.read(profileNotifierProvider.notifier).uploadAvatar(
            bytes,
            image.name,
          );

      if (mounted) {
        // Avatar se uploadoval uspesne, profil uz je aktualizovan v databazi
        // Muzeme rovnou zavrit obrazovku
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Fotka profilu aktualizovana'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Nastavime hasChanges na false, protoze avatar uz je ulozen
        // A umoznime uzivateli odejit bez dalsich zmen
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    // TODO: Implement avatar removal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Odstraneni fotky - pripravujeme')),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check username availability if changed
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null &&
          _usernameController.text != currentUser.username) {
        final isAvailable = await ref
            .read(profileNotifierProvider.notifier)
            .isUsernameAvailable(_usernameController.text);

        if (!isAvailable) {
          setState(() {
            _errorMessage = 'Toto uzivatelske jmeno je jiz obsazeno';
            _isLoading = false;
          });
          return;
        }
      }

      await ref.read(profileNotifierProvider.notifier).updateProfile(
            username: _usernameController.text,
            bio: _bioController.text.isEmpty ? null : _bioController.text,
            website:
                _websiteController.text.isEmpty ? null : _websiteController.text,
            location:
                _locationController.text.isEmpty ? null : _locationController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil ulozen'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Naviguj zpet na profil
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Zahodit zmeny?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Mas neulozenych zmen. Opravdu chces odejit?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrusit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Zahodit'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go('/profile');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (!shouldPop) return;
              }
              if (context.mounted) {
                context.go('/profile');
              }
            },
          ),
          title: Text(
            'Upravit profil',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: (_isLoading || !_hasChanges) ? null : _saveProfile,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Hotovo',
                      style: TextStyle(
                        color: _hasChanges ? AppColors.primary : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Neprihlaseny uzivatel'));
            }

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                onChanged: _onFieldChanged,
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Avatar section
                    _AvatarSection(
                      avatarUrl: user.avatarUrl,
                      username: user.username,
                      isUploading: _isUploadingAvatar,
                      onTap: _showImageSourcePicker,
                    ),

                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_errorMessage != null) const SizedBox(height: 16),

                    // Form fields
                    _FormSection(
                      children: [
                        _FormField(
                          controller: _usernameController,
                          label: 'Uzivatelske jmeno',
                          placeholder: 'vasejmeno',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Zadej uzivatelske jmeno';
                            }
                            if (value.length < 3) {
                              return 'Minimalne 3 znaky';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                              return 'Pouze pismena, cisla a podtrzitko';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    _FormSection(
                      children: [
                        _FormField(
                          controller: _bioController,
                          label: 'Bio',
                          placeholder: 'Neco o sobe...',
                          maxLines: 4,
                          maxLength: 160,
                        ),
                      ],
                    ),

                    _FormSection(
                      children: [
                        _FormField(
                          controller: _websiteController,
                          label: 'Webova stranka',
                          placeholder: 'www.example.com',
                          keyboardType: TextInputType.url,
                        ),
                        _FormField(
                          controller: _locationController,
                          label: 'Lokace',
                          placeholder: 'Praha, CZ',
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Additional options
                    _OptionsSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Chyba: ${error.toString()}')),
        ),
      ),
    );
  }
}

/// Avatar section with edit button
class _AvatarSection extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool isUploading;
  final VoidCallback onTap;

  const _AvatarSection({
    this.avatarUrl,
    required this.username,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(50),
                    width: 3,
                  ),
                ),
                child: isUploading
                    ? Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : UserAvatar(
                        imageUrl: avatarUrl,
                        name: username,
                        size: 100,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Zmenit fotku profilu',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Form section with title
class _FormSection extends StatelessWidget {
  final List<Widget> children;

  const _FormSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 16,
                color: AppColors.textMuted.withAlpha(20),
              ),
          ],
        ],
      ),
    );
  }
}

/// Individual form field
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.placeholder,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              maxLength: maxLength,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withAlpha(100),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Additional options section
class _OptionsSection extends StatelessWidget {
  const _OptionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _OptionTile(
            icon: Icons.lock_outline,
            title: 'Soukromy ucet',
            subtitle: 'Pouze schvaleni uzivatele te uvidí',
            trailing: Switch(
              value: false,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pripravujeme...')),
                );
              },
              activeTrackColor: AppColors.primary,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.textMuted;
              }),
            ),
          ),
          Divider(height: 1, indent: 56, color: AppColors.textMuted.withAlpha(20)),
          _OptionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifikace',
            subtitle: 'Nastaveni upozorneni',
            onTap: () => context.go('/settings'),
          ),
          Divider(height: 1, indent: 56, color: AppColors.textMuted.withAlpha(20)),
          _OptionTile(
            icon: Icons.security,
            title: 'Soukromi a bezpecnost',
            subtitle: 'Heslo, 2FA, prihlaseni',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pripravujeme...')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Option tile
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
