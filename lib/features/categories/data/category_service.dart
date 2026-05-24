import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/category_model.dart';

class CategoryService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<CategoryModel>> getCategories() async {
    final res = await _client
        .from('categories')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return (res as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String emoji,
    required List<String> keywords,
  }) async {
    final res = await _client.from('categories').insert({
      'user_id': _userId,
      'name': name,
      'emoji': emoji,
      'keywords': keywords,
    }).select().single();
    return CategoryModel.fromJson(res);
  }

  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String emoji,
    required List<String> keywords,
  }) async {
    final res = await _client
        .from('categories')
        .update({'name': name, 'emoji': emoji, 'keywords': keywords})
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return CategoryModel.fromJson(res);
  }

  Future<void> deleteCategory(String id) async {
    await _client
        .from('categories')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
