import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/category_provider.dart';
import '../../../../shared/models/category_model.dart';
import '../widgets/category_form_sheet.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('หมวดหมู่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context, ref, null),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
        data: (categories) => categories.isEmpty
            ? _buildEmpty(context, ref)
            : _buildList(context, ref, categories),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มหมวดหมู่'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏷️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'ยังไม่มีหมวดหมู่',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'สร้างหมวดหมู่และใส่ keyword\nเพื่อให้แอพจัด Slip ให้อัตโนมัติ',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openForm(context, ref, null),
            icon: const Icon(Icons.add),
            label: const Text('สร้างหมวดหมู่แรก'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<CategoryModel> categories) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: cat.keywords.isEmpty
                ? const Text('ยังไม่มี keyword',
                    style: TextStyle(color: Colors.grey, fontSize: 12))
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: cat.keywords
                        .take(4)
                        .map((kw) => _KeywordChip(keyword: kw))
                        .toList()
                      ..addAll(cat.keywords.length > 4
                          ? [
                              _KeywordChip(
                                  keyword: '+${cat.keywords.length - 4}')
                            ]
                          : []),
                  ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _openForm(context, ref, cat);
                if (value == 'delete') _confirmDelete(context, ref, cat);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('แก้ไข')
                    ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('ลบ', style: TextStyle(color: Colors.red))
                    ])),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, CategoryModel? cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryFormSheet(category: cat),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบหมวดหมู่'),
        content: Text('ต้องการลบ "${cat.emoji} ${cat.name}" ใช่ไหม?\nSlip ที่อยู่ในหมวดนี้จะไม่มีหมวดหมู่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).deleteCategory(cat.id);
              Navigator.pop(context);
            },
            child:
                const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  final String keyword;
  const _KeywordChip({required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        keyword,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF)),
      ),
    );
  }
}
