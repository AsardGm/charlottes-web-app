import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/scan_result_model.dart';
import '../../providers/strain_provider.dart';
import '../../theme/theme.dart';

/// Obrazovka historie skenů
///
/// Zobrazuje grid všech skenů uživatele s možností
/// filtrování oblíbených a mazání.
class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(scanHistoryNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        title: const Text('Historie skenů'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/scanner'),
        ),
        actions: [
          // Filtr oblíbených
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
            tooltip: _showFavoritesOnly ? 'Zobrazit vše' : 'Pouze oblíbené',
          ),
        ],
      ),
      body: historyAsync.when(
        data: (scans) {
          // Filtrovat podle oblíbených
          final filteredScans = _showFavoritesOnly
              ? scans.where((s) => s.isFavorite).toList()
              : scans;

          if (filteredScans.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(scanHistoryNotifierProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredScans.length,
              itemBuilder: (context, index) {
                return _ScanCard(
                  scan: filteredScans[index],
                  onTap: () =>
                      context.push('/scanner/result/${filteredScans[index].id}'),
                  onDelete: () => _confirmDelete(filteredScans[index]),
                  onToggleFavorite: () => ref
                      .read(scanHistoryNotifierProvider.notifier)
                      .toggleFavorite(filteredScans[index].id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Chyba: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(scanHistoryNotifierProvider.notifier).refresh(),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showFavoritesOnly ? Icons.favorite_border : Icons.history,
              size: 64,
              color: AppColors.functionalMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _showFavoritesOnly
                  ? 'Žádné oblíbené skeny'
                  : 'Zatím žádné skeny',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showFavoritesOnly
                  ? 'Označte skeny srdíčkem pro rychlý přístup'
                  : 'Začněte skenováním první rostliny',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.functionalMuted),
            ),
            if (!_showFavoritesOnly) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/scanner'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Skenovat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ScanResultModel scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Smazat sken?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Opravdu chcete smazat tento sken? Tuto akci nelze vrátit.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: AppColors.functionalMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Smazat', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(scanHistoryNotifierProvider.notifier).deleteScan(scan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sken byl smazán')),
        );
      }
    }
  }
}

/// Karta skenu v gridu
class _ScanCard extends StatelessWidget {
  final ScanResultModel scan;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _ScanCard({
    required this.scan,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.functionalBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Obrázek
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: scan.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.functionalBorder,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.functionalBorder,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                  // Oblíbené srdíčko
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          scan.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: scan.isFavorite ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Type badge
                  if (scan.strainType != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _TypeBadgeMini(type: scan.strainType!),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Název
                    Text(
                      scan.identified
                          ? (scan.strainName ?? 'Neznámá')
                          : 'Neidentifikováno',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Confidence
                    if (scan.confidence != null)
                      Row(
                        children: [
                          Icon(Icons.analytics, size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            scan.confidencePercent,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Datum
                    Text(
                      _formatDate(scan.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.functionalMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.functionalSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.functionalBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Otevřít'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: Icon(
                scan.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: scan.isFavorite ? Colors.red : null,
              ),
              title: Text(scan.isFavorite
                  ? 'Odebrat z oblíbených'
                  : 'Přidat do oblíbených'),
              onTap: () {
                Navigator.pop(context);
                onToggleFavorite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title:
                  const Text('Smazat', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Dnes ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Včera';
    } else if (diff.inDays < 7) {
      return 'Před ${diff.inDays} dny';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Mini badge pro typ v gridu
class _TypeBadgeMini extends StatelessWidget {
  final String type;

  const _TypeBadgeMini({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (type.toLowerCase()) {
      case 'indica':
        bgColor = Colors.purple;
        break;
      case 'sativa':
        bgColor = Colors.green;
        break;
      case 'hybrid':
        bgColor = AppColors.accent;
        break;
      default:
        bgColor = AppColors.functionalSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
