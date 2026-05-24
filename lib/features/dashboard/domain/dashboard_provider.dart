import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_service.dart';
import '../../slip/domain/slip_provider.dart';

final dashboardServiceProvider =
    Provider<DashboardService>((ref) => DashboardService());

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(
        DashboardNotifier.new);

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final month = ref.watch(selectedMonthProvider);
    return ref.read(dashboardServiceProvider).getDashboardData(month);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final month = ref.read(selectedMonthProvider);
      return ref.read(dashboardServiceProvider).getDashboardData(month);
    });
  }
}
