import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/strain_database_model.dart';
import '../../theme/theme.dart';

class ModelOfYearScreen extends StatefulWidget {
  const ModelOfYearScreen({super.key});

  @override
  State<ModelOfYearScreen> createState() => _ModelOfYearScreenState();
}

class _ModelOfYearScreenState extends State<ModelOfYearScreen> {
  AwardCategory? _selectedCategory;
  String? _votedStrainId;

  final List<Map<String, dynamic>> _nominees = [
    {'id': '1', 'name': 'OG Kush', 'emoji': '🌗', 'votes': 847},
    {'id': '2', 'name': 'Blue Dream', 'emoji': '🌗', 'votes': 721},
    {'id': '3', 'name': 'Granddaddy Purple', 'emoji': '🌙', 'votes': 623},
    {'id': '4', 'name': 'Sour Diesel', 'emoji': '☀️', 'votes': 556},
    {'id': '5', 'name': 'Girl Scout Cookies', 'emoji': '🌗', 'votes': 912},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '🏆 Model of the Year 2026',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withAlpha(50), Colors.orange.withAlpha(30)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'Hlasuj pro nejlepší strain roku!',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hlasování končí 31. 12. 2026',
                    style: TextStyle(color: AppColors.functionalMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Categories
            const Text(
              'Vyber kategorii',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AwardCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber.withAlpha(30) : AppColors.functionalSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Nominees
            if (_selectedCategory != null) ...[
              Text(
                'Nominace - ${_selectedCategory!.label}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              ...List.generate(_nominees.length, (index) {
                final nominee = _nominees[index];
                final isVoted = _votedStrainId == nominee['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isVoted ? Colors.amber.withAlpha(20) : AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVoted ? Colors.amber : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          index < 3 ? ['🥇', '🥈', '🥉'][index] : nominee['emoji'],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      nominee['name'],
                      style: TextStyle(
                        color: isVoted ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${nominee['votes']} hlasů',
                      style: TextStyle(color: AppColors.functionalMuted),
                    ),
                    trailing: isVoted
                        ? const Icon(Icons.check_circle, color: Colors.amber)
                        : ElevatedButton(
                            onPressed: () => _vote(nominee['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Hlasovat', style: TextStyle(color: Colors.black)),
                          ),
                    onTap: () => context.push('/strain/${nominee['id']}'),
                  ),
                );
              }),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.functionalSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '👆 Vyber kategorii pro zobrazení nominací',
                    style: TextStyle(color: AppColors.functionalMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Rewards info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎁 Odměny za hlasování',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRewardRow('🎴', 'Exkluzivní karty vítězů'),
                  _buildRewardRow('🏅', 'Voter badge 2026'),
                  _buildRewardRow('📚', 'Přístup k archivnímu obsahu'),
                  _buildRewardRow('✨', '+50 XP za každý hlas'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: AppColors.functionalMuted)),
        ],
      ),
    );
  }

  void _vote(String strainId) {
    setState(() => _votedStrainId = strainId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Hlas zaznamenán! +50 XP'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}