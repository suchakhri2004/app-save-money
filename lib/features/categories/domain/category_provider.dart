import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/category_model.dart';
import '../data/category_service.dart';

final categoryServiceProvider =
    Provider<CategoryService>((ref) => CategoryService());

// โหลด categories ทั้งหมดของ user
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(
        CategoriesNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return ref.read(categoryServiceProvider).getCategories();
  }

  Future<void> addCategory({
    required String name,
    required String emoji,
    required List<String> keywords,
  }) async {
    final newCat = await ref.read(categoryServiceProvider).createCategory(
          name: name,
          emoji: emoji,
          keywords: keywords,
        );
    state = AsyncData([...state.value ?? [], newCat]);
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String emoji,
    required List<String> keywords,
  }) async {
    final updated = await ref.read(categoryServiceProvider).updateCategory(
          id: id,
          name: name,
          emoji: emoji,
          keywords: keywords,
        );
    state = AsyncData(
      (state.value ?? []).map((c) => c.id == id ? updated : c).toList(),
    );
  }

  Future<void> deleteCategory(String id) async {
    await ref.read(categoryServiceProvider).deleteCategory(id);
    state = AsyncData(
      (state.value ?? []).where((c) => c.id != id).toList(),
    );
  }
}
