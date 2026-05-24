import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/slip_model.dart';
import '../../../shared/models/category_model.dart';

class SlipService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ─── Read ────────────────────────────────────────────────────────────────

  Future<List<SlipModel>> getSlips({DateTime? month}) async {
    var query = _client
        .from('slips')
        .select()
        .eq('user_id', _userId);

    if (month != null) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      query = query
          .gte('date', start.toIso8601String())
          .lt('date', end.toIso8601String());
    }

    final res = await query.order('date', ascending: false);
    return (res as List).map((e) => SlipModel.fromJson(e)).toList();
  }

  Future<List<SlipModel>> getUnmatchedSlips() async {
    final res = await _client
        .from('slips')
        .select()
        .eq('user_id', _userId)
        .eq('is_matched', false)
        .isFilter('category_id', null)
        .order('date', ascending: false);
    return (res as List).map((e) => SlipModel.fromJson(e)).toList();
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<SlipModel> createSlip({
    required double amount,
    required DateTime date,
    String? note,
    String? localAssetId,
    String? imageUrl,
    String? categoryId,
  }) async {
    final res = await _client.from('slips').insert({
      'user_id': _userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'local_asset_id': localAssetId,
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_matched': categoryId != null,
    }).select().single();
    return SlipModel.fromJson(res);
  }

  Future<void> updateCategory({
    required String slipId,
    required String? categoryId,
  }) async {
    await _client.from('slips').update({
      'category_id': categoryId,
      'is_matched': true,
    }).eq('id', slipId).eq('user_id', _userId);
  }

  Future<void> dismissSlip(String slipId) async {
    await _client.from('slips').update({
      'is_matched': true,
    }).eq('id', slipId).eq('user_id', _userId);
  }

  Future<void> deleteSlip(String slipId) async {
    await _client.from('slips').delete()
        .eq('id', slipId)
        .eq('user_id', _userId);
  }

  // ─── Auto-categorize ─────────────────────────────────────────────────────

  /// หาหมวดหมู่ที่ตรงกับ note มากที่สุด
  String? findMatchingCategory(
      String? note, List<CategoryModel> categories) {
    if (note == null || note.isEmpty) return null;
    for (final cat in categories) {
      if (cat.matchesNote(note)) return cat.id;
    }
    return null;
  }

  // ─── Stats ───────────────────────────────────────────────────────────────

  Future<Map<String, double>> getMonthlyTotal(DateTime month) async {
    final slips = await getSlips(month: month);
    final total = slips.fold<double>(0, (sum, s) => sum + s.amount);
    final byCategory = <String, double>{};
    for (final slip in slips) {
      if (slip.categoryId != null) {
        byCategory[slip.categoryId!] =
            (byCategory[slip.categoryId!] ?? 0) + slip.amount;
      }
    }
    return {'total': total, ...byCategory};
  }
}
