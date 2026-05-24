import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/category_model.dart';
import '../../domain/category_provider.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryModel? category;
  const CategoryFormSheet({super.key, this.category});

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedEmoji = '📦';
  List<String> _keywords = [];
  bool _isLoading = false;

  final _emojiOptions = [
    '🍔', '🚗', '🏠', '👕', '💊', '📚', '🎮', '✈️',
    '☕', '🛒', '💪', '🎵', '💈', '🐾', '🎁', '📦',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedEmoji = widget.category!.emoji;
      _keywords = List.from(widget.category!.keywords);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final kw = _keywordController.text.trim();
    if (kw.isEmpty) return;
    if (_keywords.contains(kw)) {
      _keywordController.clear();
      return;
    }
    setState(() {
      _keywords.add(kw);
      _keywordController.clear();
    });
  }

  void _removeKeyword(String kw) {
    setState(() => _keywords.remove(kw));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.category == null) {
        await ref.read(categoriesProvider.notifier).addCategory(
              name: _nameController.text.trim(),
              emoji: _selectedEmoji,
              keywords: _keywords,
            );
      } else {
        await ref.read(categoriesProvider.notifier).updateCategory(
              id: widget.category!.id,
              name: _nameController.text.trim(),
              emoji: _selectedEmoji,
              keywords: _keywords,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Text(
                isEdit ? 'แก้ไขหมวดหมู่' : 'สร้างหมวดหมู่ใหม่',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Emoji picker
              const Text('เลือก Emoji',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiOptions.map((emoji) {
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF6C63FF), width: 2)
                            : null,
                      ),
                      child: Center(
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อหมวดหมู่',
                  hintText: 'เช่น อาหาร, เดินทาง, ช้อปปิ้ง',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อหมวดหมู่' : null,
              ),
              const SizedBox(height: 20),

              // Keywords
              const Text('Keywords (ใช้จับคู่กับโน้ตใน Slip)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              const Text(
                'เช่น ถ้าหมวด "อาหาร" ใส่ keyword: KFC, ข้าว, ส้มตำ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Keyword input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordController,
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ keyword แล้วกด +',
                        prefixIcon: Icon(Icons.tag, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: (_) => _addKeyword(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addKeyword,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Keywords display
              if (_keywords.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _keywords
                      .map((kw) => Chip(
                            label: Text(kw),
                            onDeleted: () => _removeKeyword(kw),
                            backgroundColor:
                                const Color(0xFF6C63FF).withOpacity(0.1),
                            labelStyle: const TextStyle(
                                color: Color(0xFF6C63FF), fontSize: 13),
                            deleteIconColor: const Color(0xFF6C63FF),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              if (_keywords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'ยังไม่มี keyword (Slip จะต้องจัดเองผ่าน Swipe)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'บันทึกการแก้ไข' : 'สร้างหมวดหมู่'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
