import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lab/lab_grow_model.dart';
import '../models/lab/lab_timeline_model.dart';
import '../models/lab/lab_nutrient_model.dart';
import '../models/lab/lab_diagnostic_model.dart';

/// Sluzba pro Lab feature - CRUD operace pro grows, timeline, nutrients, diagnostiky
class LabService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  static const String _bucketName = 'lab';

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==================== GROWS ====================

  /// Nacte vsechny grows aktualniho uzivatele
  Future<List<LabGrowModel>> getGrows({bool activeOnly = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query = _supabase.from('lab_grows').select().eq('user_id', userId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => LabGrowModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Nacte konkretni grow podle ID
  Future<LabGrowModel?> getGrowById(String growId) async {
    try {
      final response = await _supabase
          .from('lab_grows')
          .select()
          .eq('id', growId)
          .maybeSingle();

      if (response == null) return null;
      return LabGrowModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Nacte aktivni grow (posledni aktivni)
  Future<LabGrowModel?> getActiveGrow() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('lab_grows')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return LabGrowModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Vytvori novy grow
  Future<LabGrowModel> createGrow(LabGrowModel grow) async {
    final response = await _supabase
        .from('lab_grows')
        .insert(grow.toInsertJson())
        .select()
        .single();

    return LabGrowModel.fromJson(response);
  }

  /// Aktualizuje grow
  Future<LabGrowModel> updateGrow(String growId, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('lab_grows')
        .update(updates)
        .eq('id', growId)
        .select()
        .single();

    return LabGrowModel.fromJson(response);
  }

  /// Zmeni fazi growu
  Future<LabGrowModel> changePhase(String growId, GrowPhase newPhase) async {
    final updates = <String, dynamic>{'phase': newPhase.name};

    // Pokud je faze completed, nastav end_date
    if (newPhase == GrowPhase.completed) {
      updates['end_date'] = DateTime.now().toIso8601String().split('T').first;
      updates['is_active'] = false;
    }

    return updateGrow(growId, updates);
  }

  /// Smaze grow
  Future<void> deleteGrow(String growId) async {
    await _supabase.from('lab_grows').delete().eq('id', growId);
  }

  // ==================== TIMELINE ====================

  /// Nacte timeline zaznamy pro grow
  Future<List<LabTimelineEntryModel>> getTimelineEntries(String growId) async {
    final response = await _supabase
        .from('lab_timeline_entries')
        .select()
        .eq('grow_id', growId)
        .order('day_number', ascending: false);

    return (response as List)
        .map((json) => LabTimelineEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Prida timeline zaznam
  Future<LabTimelineEntryModel> addTimelineEntry(LabTimelineEntryModel entry) async {
    final response = await _supabase
        .from('lab_timeline_entries')
        .insert(entry.toInsertJson())
        .select()
        .single();

    return LabTimelineEntryModel.fromJson(response);
  }

  /// Smaze timeline zaznam
  Future<void> deleteTimelineEntry(String entryId) async {
    await _supabase.from('lab_timeline_entries').delete().eq('id', entryId);
  }

  // ==================== NUTRIENTS ====================

  /// Nacte nutrient logy pro grow
  Future<List<LabNutrientLogModel>> getNutrientLogs(String growId) async {
    final response = await _supabase
        .from('lab_nutrient_logs')
        .select()
        .eq('grow_id', growId)
        .order('day_number', ascending: false);

    return (response as List)
        .map((json) => LabNutrientLogModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Prida nutrient log
  Future<LabNutrientLogModel> addNutrientLog(LabNutrientLogModel log) async {
    final response = await _supabase
        .from('lab_nutrient_logs')
        .insert(log.toInsertJson())
        .select()
        .single();

    return LabNutrientLogModel.fromJson(response);
  }

  /// Smaze nutrient log
  Future<void> deleteNutrientLog(String logId) async {
    await _supabase.from('lab_nutrient_logs').delete().eq('id', logId);
  }

  // ==================== DIAGNOSTIKY ====================

  /// Nacte diagnostiky pro grow
  Future<List<LabDiagnosticModel>> getDiagnostics(String growId) async {
    final response = await _supabase
        .from('lab_ai_diagnostics')
        .select()
        .eq('grow_id', growId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LabDiagnosticModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Ulozi diagnostiku
  Future<LabDiagnosticModel> saveDiagnostic(LabDiagnosticModel diagnostic) async {
    final response = await _supabase
        .from('lab_ai_diagnostics')
        .insert(diagnostic.toInsertJson())
        .select()
        .single();

    return LabDiagnosticModel.fromJson(response);
  }

  /// Smaze diagnostiku
  Future<void> deleteDiagnostic(String diagnosticId) async {
    await _supabase.from('lab_ai_diagnostics').delete().eq('id', diagnosticId);
  }

  // ==================== FEEDING SCHEDULES ====================

  /// Nacte dostupne feeding schedules
  Future<List<FeedingScheduleModel>> getFeedingSchedules() async {
    final userId = currentUserId;

    final response = await _supabase
        .from('lab_feeding_schedules')
        .select()
        .or('is_system.eq.true,is_public.eq.true${userId != null ? ',user_id.eq.$userId' : ''}')
        .order('is_system', ascending: false);

    return (response as List)
        .map((json) => FeedingScheduleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Vytvori vlastni schedule
  Future<FeedingScheduleModel> createSchedule(FeedingScheduleModel schedule) async {
    final response = await _supabase
        .from('lab_feeding_schedules')
        .insert(schedule.toInsertJson())
        .select()
        .single();

    return FeedingScheduleModel.fromJson(response);
  }

  // ==================== STORAGE ====================

  /// Nahraje obrazek do Lab bucketu
  Future<String> uploadImage(XFile file, {String? subfolder}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Uzivatel neni prihlasen');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    final folder = subfolder ?? 'photos';
    final path = '$userId/$folder/$timestamp.$extension';

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

  /// Vybere obrazek z galerie
  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Smaze obrazek ze storage
  Future<void> deleteImage(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucketName).remove([path]);
      }
    } catch (_) {
      // Ignoruj chyby pri mazani
    }
  }

  // ==================== STATISTIKY ====================

  /// Pocet grows uzivatele
  Future<int> getGrowCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    final response = await _supabase
        .from('lab_grows')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  }

  /// Pocet timeline zaznamu pro grow
  Future<int> getTimelineCount(String growId) async {
    final response = await _supabase
        .from('lab_timeline_entries')
        .select('id')
        .eq('grow_id', growId);

    return (response as List).length;
  }
}
