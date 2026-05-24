import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/category_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../slip/domain/slip_provider.dart';
import '../../data/dashboard_service.dart';
import '../../domain/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายจ่ายของฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async =>
                await ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Month Selector ─────────────────────────────────────────
            _MonthSelector(selectedMonth: selectedMonth),
            const SizedBox(height: 16),

            // ─── Summary + Content ──────────────────────────────────────
            dashboardAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
              data: (data) => _DashboardContent(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month Selector ───────────────────────────────────────────────────────────

class _MonthSelector extends ConsumerWidget {
  final DateTime selectedMonth;
  const _MonthSelector({required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(selectedMonth.year, selectedMonth.month - 1),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedMonth,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDatePickerMode: DatePickerMode.year,
              locale: const Locale('th'),
            );
            if (picked != null) {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(picked.year, picked.month);
            }
          },
          child: Text(
            DateFormat('MMMM yyyy', 'th').format(selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: selectedMonth.month == DateTime.now().month &&
                  selectedMonth.year == DateTime.now().year
              ? null
              : () => ref.read(selectedMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month + 1),
        ),
      ],
    );
  }
}

// ─── Dashboard Content ────────────────────────────────────────────────────────

class _DashboardContent extends ConsumerWidget {
  final DashboardData data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Total Card ─────────────────────────────────────────────────
        _TotalCard(data: data),
        const SizedBox(height: 16),

        // ─── Quick Actions ──────────────────────────────────────────────
        if (data.unmatchedCount > 0)
          _UnmatchedBanner(count: data.unmatchedCount),
        const SizedBox(height: 16),

        // ─── Bar Chart ──────────────────────────────────────────────────
        if (data.slips.isNotEmpty) ...[
          const _SectionTitle(title: 'รายจ่ายรายวัน'),
          const SizedBox(height: 8),
          _DailyBarChart(data: data),
          const SizedBox(height: 20),
        ],

        // ─── Category Pie ────────────────────────────────────────────────
        if (data.byCategory.isNotEmpty) ...[
          const _SectionTitle(title: 'แยกตามหมวดหมู่'),
          const SizedBox(height: 8),
          _CategoryPieChart(data: data),
          const SizedBox(height: 20),
        ],

        // ─── Quick Menus ─────────────────────────────────────────────────
        const _SectionTitle(title: 'เมนู'),
        const SizedBox(height: 12),
        const _QuickMenuGrid(),

        // ─── Recent Slips ─────────────────────────────────────────────────
        if (data.slips.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle(title: 'รายการล่าสุด'),
          const SizedBox(height: 8),
          _RecentSlipsList(data: data),
        ],

        if (data.slips.isEmpty)
          const _EmptyState(),
      ],
    );
  }
}

// ─── Total Card ───────────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final DashboardData data;
  const _TotalCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รายจ่ายรวม',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '฿${_fmt(data.totalExpense)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.receipt_long,
                label: '${data.slips.length} Slip',
              ),
              const SizedBox(width: 12),
              if (data.topCategory != null)
                _StatChip(
                  icon: Icons.star_outline,
                  label:
                      '${data.topCategory!.emoji} ${data.topCategory!.name}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Unmatched Banner ─────────────────────────────────────────────────────────

class _UnmatchedBanner extends ConsumerWidget {
  final int count;
  const _UnmatchedBanner({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('/swipe'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.pending_actions, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'มี $count Slip รอจัดหมวดหมู่',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  const Text(
                    'กดเพื่อจัด Slip ด้วย Swipe',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

// ─── Bar Chart (รายวัน) ───────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final DashboardData data;
  const _DailyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final byDay = data.byDay;
    final daysInMonth =
        DateUtils.getDaysInMonth(data.month.year, data.month.month);
    final maxVal =
        byDay.values.isEmpty ? 1.0 : byDay.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    'วันที่ ${group.x + 1}\n฿${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final day = val.toInt() + 1;
                      if (day % 5 == 0 || day == 1) {
                        return Text('$day',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(daysInMonth, (i) {
                final day = i + 1;
                final amount = byDay[day] ?? 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: amount,
                      color: amount > 0
                          ? const Color(0xFF6C63FF)
                          : Colors.transparent,
                      width: 6,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pie Chart (หมวดหมู่) ─────────────────────────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  final DashboardData data;
  const _CategoryPieChart({required this.data});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  final _colors = [
    const Color(0xFF6C63FF), const Color(0xFF03DAC6),
    const Color(0xFFFF6B6B), const Color(0xFFFFB347),
    const Color(0xFF43A047), const Color(0xFF2196F3),
    const Color(0xFFE91E63), const Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final byCategory = widget.data.byCategory;
    final categories = widget.data.categories;
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = widget.data.totalExpense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Pie
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        _touchedIndex =
                            event.isInterestedForInteractions &&
                                    pieTouchResponse?.touchedSection != null
                                ? pieTouchResponse!
                                    .touchedSection!.touchedSectionIndex
                                : -1;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final isTouched = idx == _touchedIndex;
                    return PieChartSectionData(
                      value: e.value.value,
                      color: _colors[idx % _colors.length],
                      radius: isTouched ? 50 : 40,
                      title: '',
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: entries.asMap().entries.map((e) {
                  final idx = e.key;
                  final catId = e.value.key;
                  final amount = e.value.value;
                  final percent = total > 0
                      ? (amount / total * 100).toStringAsFixed(1)
                      : '0';
                  CategoryModel? cat;
                  try {
                    cat = categories.firstWhere((c) => c.id == catId);
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _colors[idx % _colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat != null
                                ? '${cat.emoji} ${cat.name}'
                                : 'ไม่มีหมวด',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Menus ──────────────────────────────────────────────────────────────

class _QuickMenuGrid extends ConsumerWidget {
  const _QuickMenuGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _MenuCard(
          icon: '📸',
          label: 'นำเข้า Slip',
          subtitle: 'ดึงจาก Gallery',
          onTap: () => context.go('/slip-import'),
        ),
        _MenuCard(
          icon: '💘',
          label: 'จัด Slip',
          subtitle: 'ปัดซ้าย/ขวา',
          onTap: () => context.go('/swipe'),
        ),
        _MenuCard(
          icon: '🏷️',
          label: 'หมวดหมู่',
          subtitle: 'จัดการ Keywords',
          onTap: () => context.go('/categories'),
        ),
        _MenuCard(
          icon: '🔄',
          label: 'รีเฟรช',
          subtitle: 'โหลดข้อมูลใหม่',
          onTap: () => ref.read(dashboardProvider.notifier).refresh(),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Slips ─────────────────────────────────────────────────────────────

class _RecentSlipsList extends StatelessWidget {
  final DashboardData data;
  const _RecentSlipsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final recent = data.slips.take(5).toList();
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, index) {
          final slip = recent[index];
          CategoryModel? cat;
          try {
            if (slip.categoryId != null) {
              cat = data.categories.firstWhere((c) => c.id == slip.categoryId);
            }
          } catch (_) {}

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  cat?.emoji ?? '📄',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              slip.note ?? cat?.name ?? 'ไม่มีหมายเหตุ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              DateFormat('d MMM yyyy', 'th').format(slip.date),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '-฿${_fmt(slip.amount)}',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่มีข้อมูลเดือนนี้',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'กด "นำเข้า Slip" เพื่อเริ่มต้น',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/slip-import'),
              icon: const Icon(Icons.add),
              label: const Text('นำเข้า Slip'),
            ),
          ],
        ),
      ),
    );
  }
}
