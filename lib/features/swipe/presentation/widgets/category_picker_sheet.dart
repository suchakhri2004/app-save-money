import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/slip_model.dart';

class CategoryPickerSheet extends StatelessWidget {
  final SlipModel slip;
  final List<CategoryModel> categories;

  const CategoryPickerSheet({
    super.key,
    required this.slip,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Slip summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long,
                      color: Color(0xFF6C63FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '฿${_formatAmount(slip.amount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (slip.note != null)
                        Text(
                          slip.note!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('d MMM', 'th').format(slip.date),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'เลือกหมวดหมู่',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ยังไม่มีหมวดหมู่\nไปสร้างที่เมนู "หมวดหมู่" ก่อนนะ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, cat.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat.emoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          cat.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('ข้ามไปก่อน',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }
}
