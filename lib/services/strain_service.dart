import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/strain_model.dart';
import '../models/scan_result_model.dart';
import 'strain_scanner_service.dart';

/// Služba pro práci s odrůdami a historií skenů
///
/// Zajišťuje CRUD operace pro tabulky strains a scan_history
/// a integraci se skenerem.
class StrainService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StrainScannerService _scanner = StrainScannerService();
  final ImagePicker _picker = ImagePicker();

  static const String _bucketName = 'Strain';

  // ==================== ODRŮDY ====================

  /// Načte všechny odrůdy z katalogu
  Future<List<StrainModel>> getStrains() async {
    final response = await _supabase
        .from('strains')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => StrainModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Vyhledá odrůdu podle názvu
  Future<StrainModel?> getStrainByName(String name) async {
    try {
      final response = await _supabase
          .from('strains')
          .select()
          .ilike('name', '%$name%')
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return StrainModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Vyhledá odrůdu podle slug
  Future<StrainModel?> getStrainBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('strains')
          .select()
          .eq('slug', slug)
          .maybeSingle();

      if (response == null) return null;
      return StrainModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Vyhledá odrůdy podle typu
  Future<List<StrainModel>> getStrainsByType(String type) async {
    final response = await _supabase
        .from('strains')
        .select()
        .eq('type', type)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => StrainModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== SKENOVÁNÍ ====================

  /// Vybere obrázek z galerie
  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Vyfotí obrázek kamerou
  Future<XFile?> takePhoto() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Nahraje obrázek skenu do storage
  Future<String> _uploadScanImage(XFile file) async {
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    // Jednodušší cesta - přímo do scans/
    final path = 'scans/${userId}_$timestamp.$extension';

    await _supabase.storage.from(_bucketName).upload(
          path,
          File(file.path),
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }

  /// Provede kompletní skenování
  ///
  /// 1. Nahraje obrázek do storage
  /// 2. Pošle na AI analýzu
  /// 3. Uloží výsledek do databáze
  /// 4. Vrátí kompletní ScanResultModel
  Future<ScanResultModel> scanImage(XFile file) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StrainScannerException(
        'Pro skenování musíte být přihlášeni',
        code: 'not_authenticated',
      );
    }

    // 1. Nahrát obrázek
    // ignore: avoid_print
    print('[StrainService] Nahrávám obrázek...');
    final imageUrl = await _uploadScanImage(file);

    // 2. Načíst bytes pro AI
    final imageBytes = await file.readAsBytes();

    // 3. AI analýza
    // ignore: avoid_print
    print('[StrainService] Spouštím AI analýzu...');
    final result = await _scanner.scanAndCreateResult(
      userId: userId,
      imageUrl: imageUrl,
      imageBytes: imageBytes,
    );

    // 4. Uložit do databáze
    // ignore: avoid_print
    print('[StrainService] Ukládám výsledek...');
    final savedResult = await saveScanResult(result);

    return savedResult;
  }

  // ==================== HISTORIE SKENŮ ====================

  /// Uloží výsledek skenu do databáze
  Future<ScanResultModel> saveScanResult(ScanResultModel result) async {
    final response = await _supabase
        .from('scan_history')
        .insert(result.toInsertJson())
        .select()
        .single();

    return ScanResultModel.fromJson(response);
  }

  /// Načte historii skenů aktuálního uživatele
  Future<List<ScanResultModel>> getScanHistory({
    bool favoritesOnly = false,
    int limit = 50,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Sestavíme dotaz - filtry před order/limit
    final baseQuery = _supabase.from('scan_history').select().eq('user_id', userId);

    final List<dynamic> response;
    if (favoritesOnly) {
      response = await baseQuery
          .eq('is_favorite', true)
          .order('created_at', ascending: false)
          .limit(limit);
    } else {
      response = await baseQuery
          .order('created_at', ascending: false)
          .limit(limit);
    }

    return response
        .map((json) => ScanResultModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Načte konkrétní sken podle ID
  Future<ScanResultModel?> getScanById(String scanId) async {
    try {
      final response = await _supabase
          .from('scan_history')
          .select()
          .eq('id', scanId)
          .maybeSingle();

      if (response == null) return null;
      return ScanResultModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Přepne oblíbenost skenu
  Future<ScanResultModel> toggleFavorite(String scanId) async {
    // Nejprve načti aktuální stav
    final current = await getScanById(scanId);
    if (current == null) {
      throw Exception('Sken nebyl nalezen');
    }

    // Přepni stav
    final newValue = !current.isFavorite;

    final response = await _supabase
        .from('scan_history')
        .update({'is_favorite': newValue})
        .eq('id', scanId)
        .select()
        .single();

    return ScanResultModel.fromJson(response);
  }

  /// Smaže sken z historie
  Future<void> deleteScan(String scanId) async {
    // Nejprve získej URL obrázku pro smazání ze storage
    final scan = await getScanById(scanId);

    // Smaž z databáze
    await _supabase.from('scan_history').delete().eq('id', scanId);

    // Smaž obrázek ze storage
    if (scan != null) {
      await _deleteImageFromStorage(scan.imageUrl);
    }
  }

  /// Smaže obrázek ze storage
  Future<void> _deleteImageFromStorage(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucketName).remove([path]);
      }
    } catch (_) {
      // Ignoruj chyby při mazání
    }
  }

  /// Počet skenů uživatele
  Future<int> getScanCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('scan_history')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  }

  /// Počet oblíbených skenů
  Future<int> getFavoriteCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('scan_history')
        .select('id')
        .eq('user_id', userId)
        .eq('is_favorite', true) as List;

    return response.length;
  }
}
