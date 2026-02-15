import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/theme.dart';

/// Ghost Protocol - bezpecnostni nastaveni Lab sekce
class GhostProtocolScreen extends ConsumerStatefulWidget {
  const GhostProtocolScreen({super.key});

  @override
  ConsumerState<GhostProtocolScreen> createState() =>
      _GhostProtocolScreenState();
}

class _GhostProtocolScreenState extends ConsumerState<GhostProtocolScreen> {
  bool _exifStrip = true;
  bool _localOnly = false;
  bool _burnerMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: Column(
        children: [
          // Custom header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(30),
                  AppColors.functionalBg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.functionalBorder,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shield icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.shield,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        'GHOST PROTOCOL',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card with scanline effect
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4A1A1A),
                            const Color(0xFF1A0D0D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Icon with radial glow
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(60),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(Icons.shield, color: AppColors.primary, size: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'GHOST PROTOCOL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bezpecnostni nastaveni pro tvoje grows',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scanline effect
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: List.generate(
                            20,
                            (index) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                color: Colors.black.withAlpha(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // EXIF Strip
                _buildToggleCard(
                  icon: Icons.image_not_supported,
                  title: 'EXIF Strip',
                  subtitle: 'Automaticky odstrani metadata (GPS, cas, zarizeni) z fotek pred uploadem',
                  value: _exifStrip,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setState(() => _exifStrip = v),
                ),
                const SizedBox(height: 12),

                // Local Only
                _buildToggleCard(
                  icon: Icons.cloud_off,
                  title: 'Local Only',
                  subtitle: 'Nove grows budou ulozeny pouze lokalne na zarizeni (nesynchovano do cloudu)',
                  value: _localOnly,
                  activeColor: AppColors.warning,
                  onChanged: (v) => setState(() => _localOnly = v),
                ),
                const SizedBox(height: 12),

                // Burner Mode
                _buildToggleCard(
                  icon: Icons.local_fire_department,
                  title: 'Burner Mode',
                  subtitle: 'Panicke tlacitko - smaze vsechny Lab data z cloudoveho uctu behem sekund',
                  value: _burnerMode,
                  activeColor: AppColors.error,
                  onChanged: (v) => setState(() => _burnerMode = v),
                ),
                const SizedBox(height: 24),

                // Panic button
                if (_burnerMode) ...[
                  Text(
                    'PANIC BUTTON',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Warning stripe
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.warning,
                          AppColors.error,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPanicConfirmation(context),
                        icon: const Icon(Icons.warning_amber, size: 24),
                        label: const Text(
                          'SMAZAT VSE',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toto smaze vsechna Lab data (grows, timeline, nutrients, diagnostiky) z cloudu. Tato akce je NEVRATNA.',
                    style: TextStyle(
                      color: AppColors.error.withAlpha(180),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // Info with shield watermark
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.functionalBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Bezpecnostni info',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow('Chat zpravy jsou sifrovane E2EE (X25519 + AES-256-GCM)'),
                          _buildInfoRow('Lab fotky mohou mit stripnuta EXIF metadata'),
                          _buildInfoRow('Burner mode smaze pouze Lab data, ne profil'),
                          _buildInfoRow('Local Only data se nesynchuji do Supabase'),
                        ],
                      ),
                    ),
                    // Shield watermark
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Opacity(
                        opacity: 0.08,
                        child: Icon(
                          Icons.shield,
                          size: 80,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withAlpha(10)
            : AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withAlpha(60) : AppColors.functionalBorder,
          width: value ? 2 : 1,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: activeColor.withAlpha(30),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activeColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: value
                  ? Border.all(
                      color: activeColor.withAlpha(100),
                      width: 2,
                    )
                  : null,
            ),
            child: Icon(icon, color: activeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor.withAlpha(120),
            thumbColor: WidgetStatePropertyAll(value ? activeColor : AppColors.functionalMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPanicConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.error.withAlpha(80),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'SMAZAT VSE?',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ),
        content: Text(
          'Tato akce smaze VSECHNA Lab data z cloudu. Grows, timeline zaznamy, nutrient logy, diagnostiky - vse bude TRVALE smazano. Tuto akci NELZE vratit.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Zrusit', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                // Delete all lab-related data for user
                final supabase = Supabase.instance.client;
                await Future.wait([
                  supabase.from('lab_grows').delete().eq('user_id', userId),
                  supabase.from('lab_timeline').delete().eq('user_id', userId),
                  supabase.from('lab_nutrients').delete().eq('user_id', userId),
                  supabase.from('lab_diagnostics').delete().eq('user_id', userId),
                ]);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Vsechna Lab data byla smazana'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chyba: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('SMAZAT VSE'),
          ),
        ],
      ),
    );
  }
}
