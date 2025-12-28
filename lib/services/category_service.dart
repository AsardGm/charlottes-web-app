import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel?> getCategoryBySlug(String slug) async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('slug', slug)
        .maybeSingle();

    if (response == null) return null;
    return CategoryModel.fromJson(response);
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return CategoryModel.fromJson(response);
  }
}
