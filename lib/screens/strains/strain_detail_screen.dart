import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/strain_database_model.dart';
import '../../theme/theme.dart';

class StrainDetailScreen extends StatelessWidget {
  final String strainId;

  const StrainDetailScreen({super.key, required this.strainId});

  StrainDatabaseModel? get _strain {
    final strains = {
      '1': StrainDatabaseModel(
        id: '1',
        name: 'OG Kush',
        aka: 'Ocean Grown Kush',
        type: StrainType.hybrid,
        difficulty: DifficultyLevel.intermediate,
        breeder: 'Unknown',
        genetics: ['Chemdawg', 'Lemon Thai', 'Hindu Kush'],
        terpeneProfile: {'Myrcene': 0.45, 'Limonene': 0.28, 'Caryophyllene': 0.18},
        effects: {'Relaxed': 85, 'Happy': 78, 'Euphoric': 72, 'Uplifted': 65},
        riskFactors: [RiskFactor.drymouth, RiskFactor.anxietyProne],
        medicalUses: ['Stress', 'Pain', 'Insomnia', 'Depression'],
        flavors: ['Earthy', 'Pine', 'Woody', 'Citrus'],
        description: 'OG Kush je legendární hybrid známý pro silné účinky a zemitou vůni.',
        thcMin: 19.0,
        thcMax: 26.0,
        averageRating: 4.7,
        totalVotes: 2847,
      ),
      '2': StrainDatabaseModel(
        id: '2',
        name: 'Blue Dream',
        type: StrainType.hybrid,
        difficulty: DifficultyLevel.beginner,
        breeder: 'DJ Short',
        genetics: ['Blueberry', 'Haze'],
        terpeneProfile: {'Myrcene': 0.52, 'Pinene': 0.22, 'Caryophyllene': 0.14},
        effects: {'Creative': 88, 'Euphoric': 82, 'Relaxed': 75, 'Happy': 80},
        riskFactors: [RiskFactor.drymouth],
        medicalUses: ['Depression', 'Pain', 'Stress', 'Fatigue'],
        flavors: ['Blueberry', 'Sweet', 'Berry'],
        description: 'Blue Dream je oblíbený strain pro začátečníky.',
        thcMin: 17.0,
        thcMax: 24.0,
        averageRating: 4.5,
        totalVotes: 3521,
      ),
    };
    return strains[strainId];
  }

  @override
  Widget build(BuildContext context) {
    final strain = _strain;
    
    if (strain == null) {
      return Scaffold(
        backgroundColor: AppColors.functionalBg,
        appBar: AppBar(
          backgroundColor: AppColors.functionalBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Strain nenalezen', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(strain.name, style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(strain.typeEmoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            
            // Name & Rating
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strain.name,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      if (strain.aka != null)
                        Text('aka ${strain.aka}', style: TextStyle(color: AppColors.functionalMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        strain.averageRating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(strain.typeLabel, AppColors.accent),
                _buildTag(strain.difficultyLabel, strain.difficultyColor),
                _buildTag('THC ${strain.thcRange}', Colors.purple),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            if (strain.description != null) ...[
              Text(strain.description!, style: TextStyle(color: AppColors.functionalMuted, fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
            ],

            // Terpenes
            _buildSectionTitle('🌿 Terpenový profil'),
            const SizedBox(height: 12),
            ...strain.terpeneProfile.entries.map((e) => _buildProgressRow(e.key, e.value, Colors.teal)),

            const SizedBox(height: 24),

            // Effects
            _buildSectionTitle('✨ Efekty'),
            const SizedBox(height: 12),
            ...strain.effects.entries.map((e) => _buildProgressRow(e.key, e.value / 100, AppColors.accent)),

            const SizedBox(height: 24),

            // Medical
            if (strain.medicalUses.isNotEmpty) ...[
              _buildSectionTitle('🏥 Medicínské využití'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: strain.medicalUses.map((m) => _buildTag(m, Colors.teal)).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Flavors
            if (strain.flavors.isNotEmpty) ...[
              _buildSectionTitle('👅 Chutě'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: strain.flavors.map((f) => _buildTag(f, Colors.orange)).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Vote button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/model-of-year'),
                icon: const Icon(Icons.emoji_events, color: Colors.black),
                label: const Text('Hlasovat pro Model of the Year', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.functionalSurface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(value * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}