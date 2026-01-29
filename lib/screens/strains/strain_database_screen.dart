import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/strain_database_model.dart';
import '../../theme/theme.dart';

class StrainDatabaseScreen extends StatefulWidget {
  const StrainDatabaseScreen({super.key});

  @override
  State<StrainDatabaseScreen> createState() => _StrainDatabaseScreenState();
}

class _StrainDatabaseScreenState extends State<StrainDatabaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  StrainType? _selectedType;
  DifficultyLevel? _selectedDifficulty;
  String _sortBy = 'name';

  // Mock data - později nahradíš daty z databáze
 final List<StrainDatabaseModel> _allStrains = [
    StrainDatabaseModel(
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
      flavors: ['Earthy', 'Pine', 'Woody'],
      description: 'Legendární hybrid známý pro silné účinky a charakteristickou zemitou vůni.',
      thcMin: 19.0,
      thcMax: 26.0,
      averageRating: 4.7,
      totalVotes: 2847,
    ),
    StrainDatabaseModel(
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
      description: 'Oblíbený strain pro začátečníky s vyváženými účinky a sladkou chutí.',
      thcMin: 17.0,
      thcMax: 24.0,
      averageRating: 4.5,
      totalVotes: 3521,
    ),
    StrainDatabaseModel(
      id: '3',
      name: 'Granddaddy Purple',
      aka: 'GDP',
      type: StrainType.indica,
      difficulty: DifficultyLevel.beginner,
      breeder: 'Ken Estes',
      genetics: ['Purple Urkle', 'Big Bud'],
      terpeneProfile: {'Myrcene': 0.62, 'Pinene': 0.15, 'Caryophyllene': 0.12},
      effects: {'Relaxed': 92, 'Sleepy': 85, 'Happy': 70, 'Hungry': 68},
      riskFactors: [RiskFactor.sleepy, RiskFactor.hunger],
      medicalUses: ['Insomnia', 'Pain', 'Stress', 'Appetite Loss'],
      flavors: ['Grape', 'Berry', 'Sweet'],
      description: 'Silná indica ideální na večer a spánek s charakteristickou fialovou barvou.',
      thcMin: 17.0,
      thcMax: 23.0,
      averageRating: 4.6,
      totalVotes: 1923,
    ),
    StrainDatabaseModel(
      id: '4',
      name: 'Sour Diesel',
      aka: 'Sour D',
      type: StrainType.sativa,
      difficulty: DifficultyLevel.advanced,
      breeder: 'Unknown',
      genetics: ['Chemdawg 91', 'Super Skunk'],
      terpeneProfile: {'Caryophyllene': 0.38, 'Limonene': 0.32, 'Myrcene': 0.18},
      effects: {'Energetic': 90, 'Creative': 85, 'Focused': 78, 'Uplifted': 82},
      riskFactors: [RiskFactor.anxietyProne, RiskFactor.paranoiaProne],
      medicalUses: ['Depression', 'Fatigue', 'Stress', 'Pain'],
      flavors: ['Diesel', 'Pungent', 'Citrus'],
      description: 'Energizující sativa s charakteristickou dieselovou vůní. Pro zkušené.',
      thcMin: 20.0,
      thcMax: 25.0,
      averageRating: 4.4,
      totalVotes: 2156,
    ),
    StrainDatabaseModel(
      id: '5',
      name: 'Girl Scout Cookies',
      aka: 'GSC',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Cookie Fam',
      genetics: ['OG Kush', 'Durban Poison'],
      terpeneProfile: {'Caryophyllene': 0.42, 'Limonene': 0.28, 'Humulene': 0.15},
      effects: {'Euphoric': 88, 'Happy': 85, 'Relaxed': 80, 'Creative': 72},
      riskFactors: [RiskFactor.drymouth, RiskFactor.hunger],
      medicalUses: ['Stress', 'Depression', 'Pain', 'Nausea'],
      flavors: ['Sweet', 'Earthy', 'Mint'],
      description: 'Populární hybrid se sladkou chutí a silnými euforickými účinky.',
      thcMin: 25.0,
      thcMax: 28.0,
      averageRating: 4.8,
      totalVotes: 4102,
    ),
    StrainDatabaseModel(
      id: '6',
      name: 'Northern Lights',
      type: StrainType.indica,
      difficulty: DifficultyLevel.beginner,
      breeder: 'Sensi Seeds',
      genetics: ['Afghani', 'Thai'],
      terpeneProfile: {'Myrcene': 0.58, 'Caryophyllene': 0.22, 'Pinene': 0.12},
      effects: {'Relaxed': 95, 'Sleepy': 88, 'Happy': 75, 'Euphoric': 70},
      riskFactors: [RiskFactor.sleepy],
      medicalUses: ['Insomnia', 'Pain', 'Stress', 'Depression'],
      flavors: ['Earthy', 'Pine', 'Sweet'],
      description: 'Klasická indica vhodná pro začátečníky. Ideální na večerní relaxaci.',
      thcMin: 16.0,
      thcMax: 21.0,
      averageRating: 4.5,
      totalVotes: 2789,
    ),
    StrainDatabaseModel(
      id: '7',
      name: 'White Widow',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.beginner,
      breeder: 'Green House Seeds',
      genetics: ['Brazilian Sativa', 'South Indian Indica'],
      terpeneProfile: {'Myrcene': 0.35, 'Caryophyllene': 0.28, 'Limonene': 0.20},
      effects: {'Euphoric': 85, 'Creative': 80, 'Energetic': 75, 'Happy': 82},
      riskFactors: [RiskFactor.drymouth],
      medicalUses: ['Stress', 'Depression', 'Pain', 'Fatigue'],
      flavors: ['Earthy', 'Woody', 'Pungent'],
      description: 'Legendární holandský strain s bílými trichomy a vyváženými účinky.',
      thcMin: 18.0,
      thcMax: 25.0,
      averageRating: 4.6,
      totalVotes: 3210,
    ),
    StrainDatabaseModel(
      id: '8',
      name: 'Jack Herer',
      type: StrainType.sativa,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Sensi Seeds',
      genetics: ['Haze', 'Northern Lights #5', 'Shiva Skunk'],
      terpeneProfile: {'Terpinolene': 0.45, 'Caryophyllene': 0.22, 'Pinene': 0.18},
      effects: {'Creative': 92, 'Energetic': 88, 'Focused': 85, 'Happy': 80},
      riskFactors: [RiskFactor.anxietyProne],
      medicalUses: ['Depression', 'Fatigue', 'Stress', 'ADHD'],
      flavors: ['Pine', 'Earthy', 'Citrus'],
      description: 'Pojmenován po legendárním aktivistovi. Skvělá pro kreativitu a fokus.',
      thcMin: 18.0,
      thcMax: 24.0,
      averageRating: 4.7,
      totalVotes: 2567,
    ),
    StrainDatabaseModel(
      id: '9',
      name: 'Gelato',
      aka: 'Larry Bird',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Cookie Fam',
      genetics: ['Sunset Sherbet', 'Thin Mint GSC'],
      terpeneProfile: {'Limonene': 0.38, 'Caryophyllene': 0.32, 'Myrcene': 0.22},
      effects: {'Relaxed': 85, 'Euphoric': 88, 'Happy': 82, 'Creative': 75},
      riskFactors: [RiskFactor.drymouth, RiskFactor.hunger],
      medicalUses: ['Pain', 'Stress', 'Insomnia', 'Depression'],
      flavors: ['Sweet', 'Citrus', 'Berry'],
      description: 'Dezertový strain s intenzivní chutí a vyváženými účinky.',
      thcMin: 20.0,
      thcMax: 25.0,
      averageRating: 4.8,
      totalVotes: 3890,
    ),
    StrainDatabaseModel(
      id: '10',
      name: 'AK-47',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Serious Seeds',
      genetics: ['Colombian', 'Mexican', 'Thai', 'Afghani'],
      terpeneProfile: {'Myrcene': 0.42, 'Caryophyllene': 0.25, 'Limonene': 0.18},
      effects: {'Relaxed': 80, 'Happy': 85, 'Euphoric': 78, 'Uplifted': 75},
      riskFactors: [RiskFactor.drymouth, RiskFactor.paranoiaProne],
      medicalUses: ['Stress', 'Depression', 'Pain', 'Anxiety'],
      flavors: ['Earthy', 'Pungent', 'Sour'],
      description: 'Navzdory názvu přináší klidnou, dlouhotrvající euforii.',
      thcMin: 13.0,
      thcMax: 20.0,
      averageRating: 4.4,
      totalVotes: 2134,
    ),
    StrainDatabaseModel(
      id: '11',
      name: 'Gorilla Glue',
      aka: 'GG4',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.advanced,
      breeder: 'GG Strains',
      genetics: ['Chem Sister', 'Sour Dubb', 'Chocolate Diesel'],
      terpeneProfile: {'Caryophyllene': 0.48, 'Myrcene': 0.32, 'Limonene': 0.15},
      effects: {'Relaxed': 95, 'Euphoric': 88, 'Happy': 82, 'Sleepy': 75},
      riskFactors: [RiskFactor.drymouth, RiskFactor.sleepy],
      medicalUses: ['Pain', 'Stress', 'Insomnia', 'Depression'],
      flavors: ['Pungent', 'Earthy', 'Pine'],
      description: 'Extrémně silný hybrid. Název odkazuje na lepivé trichomy.',
      thcMin: 25.0,
      thcMax: 32.0,
      averageRating: 4.7,
      totalVotes: 4521,
    ),
    StrainDatabaseModel(
      id: '12',
      name: 'Pineapple Express',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.beginner,
      breeder: 'G13 Labs',
      genetics: ['Trainwreck', 'Hawaiian'],
      terpeneProfile: {'Myrcene': 0.38, 'Pinene': 0.28, 'Caryophyllene': 0.20},
      effects: {'Happy': 90, 'Euphoric': 85, 'Energetic': 78, 'Creative': 75},
      riskFactors: [RiskFactor.drymouth],
      medicalUses: ['Depression', 'Stress', 'Pain', 'Fatigue'],
      flavors: ['Pineapple', 'Tropical', 'Sweet'],
      description: 'Tropický strain proslavený filmem. Skvělý pro dobrou náladu.',
      thcMin: 17.0,
      thcMax: 24.0,
      averageRating: 4.5,
      totalVotes: 2987,
    ),
    StrainDatabaseModel(
      id: '13',
      name: 'Purple Haze',
      type: StrainType.sativa,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Unknown',
      genetics: ['Purple Thai', 'Haze'],
      terpeneProfile: {'Terpinolene': 0.42, 'Myrcene': 0.25, 'Caryophyllene': 0.18},
      effects: {'Euphoric': 92, 'Creative': 88, 'Energetic': 82, 'Happy': 85},
      riskFactors: [RiskFactor.anxietyProne],
      medicalUses: ['Depression', 'Stress', 'Fatigue', 'ADHD'],
      flavors: ['Berry', 'Earthy', 'Sweet'],
      description: 'Legendární sativa inspirovaná písní Jimiho Hendrixe.',
      thcMin: 14.0,
      thcMax: 20.0,
      averageRating: 4.5,
      totalVotes: 1876,
    ),
    StrainDatabaseModel(
      id: '14',
      name: 'Wedding Cake',
      aka: 'Pink Cookies',
      type: StrainType.indica,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Seed Junky',
      genetics: ['Triangle Kush', 'Animal Mints'],
      terpeneProfile: {'Limonene': 0.45, 'Caryophyllene': 0.35, 'Myrcene': 0.18},
      effects: {'Relaxed': 88, 'Euphoric': 85, 'Happy': 80, 'Hungry': 70},
      riskFactors: [RiskFactor.drymouth, RiskFactor.hunger],
      medicalUses: ['Pain', 'Insomnia', 'Depression', 'Appetite Loss'],
      flavors: ['Sweet', 'Vanilla', 'Earthy'],
      description: 'Dezertový indica dominant s bohatou, sladkou chutí.',
      thcMin: 22.0,
      thcMax: 27.0,
      averageRating: 4.8,
      totalVotes: 3654,
    ),
    StrainDatabaseModel(
      id: '15',
      name: 'Zkittlez',
      type: StrainType.indica,
      difficulty: DifficultyLevel.beginner,
      breeder: '3rd Gen Family',
      genetics: ['Grape Ape', 'Grapefruit'],
      terpeneProfile: {'Caryophyllene': 0.38, 'Linalool': 0.28, 'Humulene': 0.18},
      effects: {'Relaxed': 90, 'Happy': 85, 'Sleepy': 78, 'Euphoric': 75},
      riskFactors: [RiskFactor.sleepy],
      medicalUses: ['Stress', 'Anxiety', 'Pain', 'Insomnia'],
      flavors: ['Sweet', 'Berry', 'Tropical'],
      description: 'Ovocný strain jako duha bonbónů. Relaxující a uklidňující.',
      thcMin: 15.0,
      thcMax: 23.0,
      averageRating: 4.6,
      totalVotes: 2543,
    ),
    StrainDatabaseModel(
      id: '16',
      name: 'Amnesia Haze',
      type: StrainType.sativa,
      difficulty: DifficultyLevel.advanced,
      breeder: 'Soma Seeds',
      genetics: ['Jamaican Sativa', 'Laotian Sativa', 'Afghan Hawaiian'],
      terpeneProfile: {'Terpinolene': 0.48, 'Myrcene': 0.22, 'Limonene': 0.18},
      effects: {'Euphoric': 95, 'Creative': 90, 'Energetic': 88, 'Focused': 82},
      riskFactors: [RiskFactor.anxietyProne, RiskFactor.paranoiaProne],
      medicalUses: ['Depression', 'Fatigue', 'Stress', 'ADHD'],
      flavors: ['Citrus', 'Lemon', 'Earthy'],
      description: 'Silná sativa s psychedelickými účinky. Pro zkušené uživatele.',
      thcMin: 20.0,
      thcMax: 25.0,
      averageRating: 4.6,
      totalVotes: 2234,
    ),
    StrainDatabaseModel(
      id: '17',
      name: 'Bubba Kush',
      type: StrainType.indica,
      difficulty: DifficultyLevel.beginner,
      breeder: 'Unknown',
      genetics: ['OG Kush', 'Unknown Indica'],
      terpeneProfile: {'Myrcene': 0.55, 'Caryophyllene': 0.25, 'Limonene': 0.12},
      effects: {'Relaxed': 95, 'Sleepy': 90, 'Happy': 70, 'Hungry': 65},
      riskFactors: [RiskFactor.sleepy, RiskFactor.hunger],
      medicalUses: ['Insomnia', 'Pain', 'Stress', 'Anxiety'],
      flavors: ['Coffee', 'Earthy', 'Sweet'],
      description: 'Těžká indica pro večerní použití. Perfektní na spánek.',
      thcMin: 15.0,
      thcMax: 22.0,
      averageRating: 4.5,
      totalVotes: 1987,
    ),
    StrainDatabaseModel(
      id: '18',
      name: 'Green Crack',
      aka: 'Green Cush',
      type: StrainType.sativa,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Unknown',
      genetics: ['Skunk #1', 'Unknown Indica'],
      terpeneProfile: {'Myrcene': 0.42, 'Caryophyllene': 0.28, 'Limonene': 0.22},
      effects: {'Energetic': 95, 'Focused': 90, 'Happy': 85, 'Creative': 80},
      riskFactors: [RiskFactor.anxietyProne],
      medicalUses: ['Fatigue', 'Depression', 'Stress', 'ADHD'],
      flavors: ['Citrus', 'Mango', 'Sweet'],
      description: 'Intenzivní energizující sativa. Skvělá náhrada za kávu.',
      thcMin: 15.0,
      thcMax: 25.0,
      averageRating: 4.4,
      totalVotes: 2654,
    ),
    StrainDatabaseModel(
      id: '19',
      name: 'Cheese',
      aka: 'UK Cheese',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.beginner,
      breeder: 'Big Buddha Seeds',
      genetics: ['Skunk #1'],
      terpeneProfile: {'Caryophyllene': 0.45, 'Myrcene': 0.30, 'Limonene': 0.15},
      effects: {'Relaxed': 85, 'Happy': 82, 'Euphoric': 78, 'Creative': 70},
      riskFactors: [RiskFactor.drymouth],
      medicalUses: ['Stress', 'Pain', 'Depression', 'Anxiety'],
      flavors: ['Cheese', 'Pungent', 'Earthy'],
      description: 'Charakteristická sýrová vůně. Britská klasika.',
      thcMin: 14.0,
      thcMax: 20.0,
      averageRating: 4.3,
      totalVotes: 1765,
    ),
    StrainDatabaseModel(
      id: '20',
      name: 'Runtz',
      type: StrainType.hybrid,
      difficulty: DifficultyLevel.intermediate,
      breeder: 'Cookies',
      genetics: ['Zkittlez', 'Gelato'],
      terpeneProfile: {'Limonene': 0.42, 'Caryophyllene': 0.32, 'Linalool': 0.18},
      effects: {'Euphoric': 90, 'Happy': 88, 'Relaxed': 85, 'Creative': 75},
      riskFactors: [RiskFactor.drymouth],
      medicalUses: ['Stress', 'Depression', 'Pain', 'Anxiety'],
      flavors: ['Sweet', 'Tropical', 'Candy'],
      description: 'Prémiový hybrid kombinující nejlepší vlastnosti rodičů.',
      thcMin: 19.0,
      thcMax: 29.0,
      averageRating: 4.9,
      totalVotes: 4876,
    ),
  
  ];

  List<StrainDatabaseModel> get _filteredStrains {
    var filtered = _allStrains.where((strain) {
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        if (!strain.name.toLowerCase().contains(query) &&
            !(strain.aka?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      // Type filter
      if (_selectedType != null && strain.type != _selectedType) {
        return false;
      }
      // Difficulty filter
      if (_selectedDifficulty != null && strain.difficulty != _selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'votes':
        filtered.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
        break;
      case 'thc':
        filtered.sort((a, b) => (b.thcMax ?? 0).compareTo(a.thcMax ?? 0));
        break;
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          '🌿 Strain Database',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            onPressed: () => context.push('/model-of-year'),
            tooltip: 'Model of the Year',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          _buildSearchAndFilters(),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredStrains.length} strains',
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 14),
                ),
                const Spacer(),
                // Sort dropdown
                DropdownButton<String>(
                  value: _sortBy,
                  dropdownColor: AppColors.functionalSurface,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  underline: const SizedBox(),
                  icon: Icon(Icons.sort, color: AppColors.accent, size: 18),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('A-Z')),
                    DropdownMenuItem(value: 'rating', child: Text('⭐ Rating')),
                    DropdownMenuItem(value: 'votes', child: Text('🔥 Popular')),
                    DropdownMenuItem(value: 'thc', child: Text('💪 THC')),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ],
            ),
          ),

          // Strain list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredStrains.length,
              itemBuilder: (context, index) {
                return _buildStrainCard(_filteredStrains[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalBg,
        border: Border(
          bottom: BorderSide(color: AppColors.functionalBorder.withAlpha(100)),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Hledat strain...',
                hintStyle: TextStyle(color: AppColors.functionalMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.accent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type filters
                _buildFilterChip(
                  label: '🌙 Indica',
                  isSelected: _selectedType == StrainType.indica,
                  onTap: () => setState(() {
                    _selectedType = _selectedType == StrainType.indica ? null : StrainType.indica;
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '☀️ Sativa',
                  isSelected: _selectedType == StrainType.sativa,
                  onTap: () => setState(() {
                    _selectedType = _selectedType == StrainType.sativa ? null : StrainType.sativa;
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '🌗 Hybrid',
                  isSelected: _selectedType == StrainType.hybrid,
                  onTap: () => setState(() {
                    _selectedType = _selectedType == StrainType.hybrid ? null : StrainType.hybrid;
                  }),
                ),
                const SizedBox(width: 16),
                // Difficulty filters
                _buildFilterChip(
                  label: '🟢 Beginner',
                  isSelected: _selectedDifficulty == DifficultyLevel.beginner,
                  onTap: () => setState(() {
                    _selectedDifficulty = _selectedDifficulty == DifficultyLevel.beginner ? null : DifficultyLevel.beginner;
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '🔴 Advanced',
                  isSelected: _selectedDifficulty == DifficultyLevel.advanced,
                  onTap: () => setState(() {
                    _selectedDifficulty = _selectedDifficulty == DifficultyLevel.advanced ? null : DifficultyLevel.advanced;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withAlpha(30) : AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStrainCard(StrainDatabaseModel strain) {
    return GestureDetector(
      onTap: () => context.push('/strain/${strain.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.functionalBorder.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Type emoji
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(strain.typeEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strain.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (strain.aka != null)
                        Text(
                          strain.aka!,
                          style: TextStyle(color: AppColors.functionalMuted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        strain.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag(strain.typeLabel, AppColors.accent),
                _buildTag(strain.difficultyLabel, strain.difficultyColor),
                _buildTag('THC ${strain.thcRange}', Colors.purple),
              ],
            ),

            const SizedBox(height: 12),

            // Terpene preview
            if (strain.terpeneProfile.isNotEmpty) ...[
              Text(
                'Top terpeny:',
                style: TextStyle(color: AppColors.functionalMuted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Row(
                children: strain.terpeneProfile.entries.take(3).map((e) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${e.key} ${(e.value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.teal, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Effects preview
            Row(
              children: [
                ...strain.effects.entries.take(3).map((e) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${e.value}%',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          e.key,
                          style: TextStyle(color: AppColors.functionalMuted, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(width: 16),
                Text(
                  '${strain.totalVotes} votes',
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: AppColors.functionalMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}