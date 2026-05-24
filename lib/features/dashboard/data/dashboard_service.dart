import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/slip_model.dart';
import '../../../shared/models/category_model.dart';

class DashboardService {
  final _client = Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  Future<DashboardData> getDashboardData(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    // ดึง slips + categories พร้อมกัน
    final results = await Future.wait([
      _client
          .from('slips')
          .select()
          .eq('user_id', _userId)
          .gte('date', start.toIso8601String())
          .lt('date', end.toIso8601String())
          .order('date', ascending: false),
      _client
          .from('categories')
          .select()
          .eq('user_id', _userId),
      _client
          .from('slips')
          .select()
          .eq('user_id', _userId)
          .eq('is_matched', false)
          .isFilter('category_id', null),
    ]);

    final slips = (results[0] as List)
        .map((e) => SlipModel.fromJson(e))
        .toList();
    final categories = (results[1] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
    final unmatched = (results[2] as List).length;

    return DashboardData(
      slips: slips,
      categories: categories,
      unmatchedCount: unmatched,
      month: month,
    );
  }
}

class DashboardData {
  final List<SlipModel> slips;
  final List<CategoryModel> categories;
  final int unmatchedCount;
  final DateTime month;

  DashboardData({
    required this.slips,
    required this.categories,
    required this.unmatchedCount,
    required this.month,
  });

  double get totalExpense =>
      slips.fold(0, (sum, s) => sum + s.amount);

  // จำนวนเงินต่อหมวดหมู่
  Map<String, double> get byCategory {
    final map = <String, double>{};
    for (final slip in slips) {
      if (slip.categoryId != null) {
        map[slip.categoryId!] = (map[slip.categoryId!] ?? 0) + slip.amount;
      }
    }
    return map;
  }

  // สรุปต่อวัน (สำหรับ bar chart)
  Map<int, double> get byDay {
    final map = <int, double>{};
    for (final slip in slips) {
      final day = slip.date.day;
      map[day] = (map[day] ?? 0) + slip.amount;
    }
    return map;
  }

  // หาหมวดที่ใช้เงินมากสุด
  CategoryModel? get topCategory {
    if (byCategory.isEmpty || categories.isEmpty) return null;
    final topId = byCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    try {
      return categories.firstWhere((c) => c.id == topId);
    } catch (_) {
      return null;
    }
  }
}
