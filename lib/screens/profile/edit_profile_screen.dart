import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

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

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar aktualizovan')),
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
        setState(() => _isUploadingAvatar = false);
      }
    }
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
          const SnackBar(content: Text('Profil ulozen')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upravit profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ulozit'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Neprihlaseny uzivatel'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                          child: _isUploadingAvatar
                              ? Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : UserAvatar(
                                  imageUrl: user.avatarUrl,
                                  name: user.username,
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
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Uzivatelske jmeno',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
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

                  const SizedBox(height: 16),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: Icon(Icons.info_outline),
                      hintText: 'Neco o tobe...',
                    ),
                    maxLines: 3,
                    maxLength: 160,
                  ),

                  const SizedBox(height: 16),

                  // Website
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Webova stranka',
                      prefixIcon: Icon(Icons.link),
                      hintText: 'https://...',
                    ),
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lokace',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'Praha, CZ',
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Chyba: ${error.toString()}')),
      ),
    );
  }
}
