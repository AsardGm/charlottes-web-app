import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/thread_type_model.dart';

/// Služba pro práci s typy vláken
///
/// Zajišťuje načítání typů vláken (Diskuze, Otázka, Oznámení).
class ThreadTypeService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Získá seznam aktivních typů vláken
  ///
  /// Seřazeno podle sort_order.
  Future<List<ThreadTypeModel>> getThreadTypes() async {
    final response = await _supabase
        .from('thread_types')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((json) => ThreadTypeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Získá typ vlákna podle ID
  Future<ThreadTypeModel?> getThreadType(String id) async {
    final response = await _supabase
        .from('thread_types')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ThreadTypeModel.fromJson(response);
  }

  /// Získá typy vláken dostupné pro danou roli
  ///
  /// Filtruje typy podle oprávnění role vytvářet daný typ.
  Future<List<ThreadTypeModel>> getThreadTypesForRole(String role) async {
    final allTypes = await getThreadTypes();
    return allTypes.where((type) => type.canRoleCreate(role)).toList();
  }
}
