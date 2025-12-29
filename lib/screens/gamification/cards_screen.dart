import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/strain_card_model.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/gamification/gamification.dart';

/// Obrazovka kolekce sberatelskych karet
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CardRarity? _selectedRarity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(userCardsProvider);
    final statsAsync = ref.watch(collectionStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Sbirka karet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Vse'),
            Tab(text: 'Common'),
            Tab(text: 'Rare'),
            Tab(text: 'Exotic'),
            Tab(text: 'Legend'),
          ],
          onTap: (index) {
            setState(() {
              _selectedRarity = index == 0
                  ? null
                  : CardRarity.values[index - 1];
            });
          },
        ),
      ),
      body: Column(
        children: [
          // Statistiky kolekce
          statsAsync.when(
            data: (stats) => CollectionStatsBar(
              total: stats.total,
              collected: stats.collected,
              byRarity: stats.byRarity,
            ),
            loading: () => const SizedBox(height: 80),
            error: (_, _) => const SizedBox(height: 80),
          ),

          // Grid karet
          Expanded(
            child: cardsAsync.when(
              data: (cards) {
                final filteredCards = _selectedRarity == null
                    ? cards
                    : cards
                        .where((c) => c.rarity == _selectedRarity)
                        .toList();

                if (filteredCards.isEmpty) {
                  return EmptyCardsState(rarity: _selectedRarity);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    return CardGridItem(
                      card: card,
                      onTap: () => _showCardDetail(card),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Chyba: $error',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCardDetail(StrainCard card) {
    StrainCardDetailDialog.show(context, card, isCollected: true);
  }
}
