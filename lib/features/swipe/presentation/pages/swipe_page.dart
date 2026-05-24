import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/slip_model.dart';
import '../../../categories/domain/category_provider.dart';
import '../../../slip/domain/slip_provider.dart';
import '../widgets/swipe_card.dart';
import '../widgets/category_picker_sheet.dart';

class SwipePage extends ConsumerStatefulWidget {
  const SwipePage({super.key});

  @override
  ConsumerState<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends ConsumerState<SwipePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  static const double _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimations();
  }

  void _resetAnimations() {
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
    _rotateAnim = Tween<double>(begin: 0, end: 0).animate(_animController);
    _fadeAnim = Tween<double>(begin: 1, end: 0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Drag Handlers ───────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _animController.reset();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  void _onDragEnd(DragEndDetails details) {
    final dx = _dragOffset.dx;
    if (dx.abs() >= _swipeThreshold) {
      _triggerSwipe(dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = Offset.zero;
      });
    }
  }

  // ─── Swipe Logic ─────────────────────────────────────────────────────────

  void _triggerSwipe(SwipeDirection dir) async {
    final slips = ref.read(unmatchedSlipsProvider).value ?? [];
    if (slips.isEmpty) return;

    final current = slips.first;

    // Animate card out
    final endOffset = dir == SwipeDirection.right
        ? const Offset(2.0, 0)
        : const Offset(-2.0, 0);

    _slideAnim = Tween<Offset>(
      begin: _dragOffset / MediaQuery.of(context).size.width,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _rotateAnim = Tween<double>(
      begin: _dragOffset.dx / 800,
      end: dir == SwipeDirection.right ? 0.3 : -0.3,
    ).animate(_animController);

    _fadeAnim = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animController);

    setState(() => _isDragging = false);
    await _animController.forward();

    if (!mounted) return;

    if (dir == SwipeDirection.right) {
      // ✅ Match — เลือกหมวดหมู่
      await _showCategoryPicker(current);
    } else {
      // ❌ ไม่ match — dismiss
      await ref.read(slipServiceProvider).dismissSlip(current.id);
      ref.read(unmatchedSlipsProvider.notifier).removeFirst();
    }

    // Reset
    setState(() => _dragOffset = Offset.zero);
    _animController.reset();
    _resetAnimations();
  }

  Future<void> _showCategoryPicker(SlipModel slip) async {
    final categories = ref.read(categoriesProvider).value ?? [];

    final selectedCategoryId = await showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerSheet(
        slip: slip,
        categories: categories,
      ),
    );

    if (selectedCategoryId != null && mounted) {
      await ref.read(slipServiceProvider).updateCategory(
            slipId: slip.id,
            categoryId: selectedCategoryId,
          );
    } else {
      // ปิด sheet โดยไม่เลือก → dismiss
      await ref.read(slipServiceProvider).dismissSlip(slip.id);
    }
    ref.read(unmatchedSlipsProvider.notifier).removeFirst();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final slipsAsync = ref.watch(unmatchedSlipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัด Slip'),
        actions: [
          slipsAsync.whenOrNull(
            data: (slips) => slips.isNotEmpty
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${slips.length} รายการ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: slipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
        data: (slips) => slips.isEmpty
            ? _buildDoneView()
            : _buildSwipeView(slips),
      ),
    );
  }

  Widget _buildSwipeView(List<SlipModel> slips) {
    final size = MediaQuery.of(context).size;
    final dragPercent = (_dragOffset.dx / size.width).clamp(-1.0, 1.0);

    return Column(
      children: [
        // ─── Hint labels ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HintLabel(
                label: '✕  ข้าม',
                color: Colors.red,
                opacity: dragPercent < 0 ? dragPercent.abs() : 0,
              ),
              _HintLabel(
                label: 'จัดหมวด  ✓',
                color: Colors.green,
                opacity: dragPercent > 0 ? dragPercent : 0,
              ),
            ],
          ),
        ),

        // ─── Card Stack ──────────────────────────────────────────────────
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Next card (behind)
              if (slips.length > 1)
                Transform.scale(
                  scale: 0.93 + (dragPercent.abs() * 0.07),
                  child: SwipeCard(
                    slip: slips[1],
                    isTop: false,
                  ),
                ),

              // Top card (draggable)
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final offset = _isDragging
                      ? _dragOffset / size.width
                      : _slideAnim.value;
                  final rotate = _isDragging
                      ? _dragOffset.dx / 800
                      : _rotateAnim.value;
                  final opacity =
                      _animController.isAnimating ? _fadeAnim.value : 1.0;

                  return Transform.translate(
                    offset: Offset(offset.dx * size.width, offset.dy * size.width),
                    child: Transform.rotate(
                      angle: rotate,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: SwipeCard(
                    slip: slips.first,
                    isTop: true,
                    dragPercent: dragPercent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Action Buttons ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: Colors.red,
                label: 'ข้าม',
                onTap: () => _triggerSwipe(SwipeDirection.left),
              ),
              _ActionButton(
                icon: Icons.check,
                color: Colors.green,
                label: 'จัดหมวด',
                onTap: () => _triggerSwipe(SwipeDirection.right),
                large: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'จัด Slip ครบแล้ว!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'ไม่มี Slip ที่รอจัดหมวดหมู่แล้ว',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(unmatchedSlipsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('โหลดใหม่'),
          ),
        ],
      ),
    );
  }
}

enum SwipeDirection { left, right, none }

// ─── Sub Widgets ─────────────────────────────────────────────────────────────

class _HintLabel extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;

  const _HintLabel({
    required this.label,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool large;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: large ? 32 : 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
