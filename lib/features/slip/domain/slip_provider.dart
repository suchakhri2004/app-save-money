import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/slip_model.dart';
import '../data/slip_service.dart';

final slipServiceProvider = Provider<SlipService>((ref) => SlipService());

// Selected month สำหรับ filter
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// Slips ของเดือนที่เลือก
final slipsProvider =
    AsyncNotifierProvider<SlipsNotifier, List<SlipModel>>(SlipsNotifier.new);

class SlipsNotifier extends AsyncNotifier<List<SlipModel>> {
  @override
  Future<List<SlipModel>> build() async {
    final month = ref.watch(selectedMonthProvider);
    return ref.read(slipServiceProvider).getSlips(month: month);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final month = ref.read(selectedMonthProvider);
      return ref.read(slipServiceProvider).getSlips(month: month);
    });
  }

  Future<void> addSlip(SlipModel slip) async {
    state = AsyncData([slip, ...?state.value]);
  }

  Future<void> updateSlipCategory({
    required String slipId,
    required String? categoryId,
  }) async {
    await ref.read(slipServiceProvider).updateCategory(
          slipId: slipId,
          categoryId: categoryId,
        );
    state = AsyncData(
      (state.value ?? [])
          .map((s) => s.id == slipId
              ? s.copyWith(categoryId: categoryId, isMatched: true)
              : s)
          .toList(),
    );
  }
}

// Unmatched slips สำหรับ Tinder Swipe
final unmatchedSlipsProvider =
    AsyncNotifierProvider<UnmatchedSlipsNotifier, List<SlipModel>>(
        UnmatchedSlipsNotifier.new);

class UnmatchedSlipsNotifier extends AsyncNotifier<List<SlipModel>> {
  @override
  Future<List<SlipModel>> build() async {
    return ref.read(slipServiceProvider).getUnmatchedSlips();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(slipServiceProvider).getUnmatchedSlips());
  }

  void removeFirst() {
    final list = state.value ?? [];
    if (list.isNotEmpty) {
      state = AsyncData(list.sublist(1));
    }
  }
}

// Import progress state
class ImportProgress {
  final int total;
  final int processed;
  final int found;
  final bool isRunning;
  final String? currentFile;

  const ImportProgress({
    this.total = 0,
    this.processed = 0,
    this.found = 0,
    this.isRunning = false,
    this.currentFile,
  });

  double get percentage => total == 0 ? 0 : processed / total;

  ImportProgress copyWith({
    int? total,
    int? processed,
    int? found,
    bool? isRunning,
    String? currentFile,
  }) =>
      ImportProgress(
        total: total ?? this.total,
        processed: processed ?? this.processed,
        found: found ?? this.found,
        isRunning: isRunning ?? this.isRunning,
        currentFile: currentFile ?? this.currentFile,
      );
}

final importProgressProvider =
    StateProvider<ImportProgress>((ref) => const ImportProgress());
