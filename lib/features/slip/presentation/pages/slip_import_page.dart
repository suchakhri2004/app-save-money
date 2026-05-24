import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';

import '../../../categories/domain/category_provider.dart';
import '../../data/slip_parser.dart';
import '../../domain/slip_provider.dart';

class SlipImportPage extends ConsumerStatefulWidget {
  const SlipImportPage({super.key});

  @override
  ConsumerState<SlipImportPage> createState() => _SlipImportPageState();
}

class _SlipImportPageState extends ConsumerState<SlipImportPage> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  bool _hasPermission = false;
  bool _isDone = false;
  int _importedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    setState(() => _hasPermission = result.isAuth || result.hasAccess);
  }

  Future<void> _startImport() async {
    if (!_hasPermission) {
      await PhotoManager.openSetting();
      return;
    }

    final categories = ref.read(categoriesProvider).value ?? [];
    final slipService = ref.read(slipServiceProvider);
    // ใช้ latin script (ครอบคลุมตัวเลขและภาษาอังกฤษในสลิป)
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    // ใช้ chinese script เป็น fallback (รองรับหลายภาษา)
    final thaiRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

    // รีเซ็ต progress
    ref.read(importProgressProvider.notifier).state = const ImportProgress(
      isRunning: true,
    );

    try {
      // ดึงรูปทั้งหมดตั้งแต่เดือนที่เลือก
      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isEmpty) return;

      final allPhotos = albums.first;
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);

      // ดึงรูปทีละ batch
      final assets = await allPhotos.getAssetListRange(start: 0, end: 10000);
      final filtered = assets.where((a) {
        final date = a.createDateTime;
        return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
      }).toList();

      ref.read(importProgressProvider.notifier).state = ImportProgress(
        total: filtered.length,
        isRunning: true,
      );

      int found = 0;

      for (int i = 0; i < filtered.length; i++) {
        final asset = filtered[i];

        ref.read(importProgressProvider.notifier).state = ImportProgress(
          total: filtered.length,
          processed: i + 1,
          found: found,
          isRunning: true,
          currentFile: 'รูปที่ ${i + 1}/${filtered.length}',
        );

        try {
          final file = await asset.file;
          if (file == null) continue;

          final inputImage = InputImage.fromFile(file);

          // ลอง recognize ทั้งสองภาษา แล้วเอาที่มี text มากกว่า
          final result1 = await textRecognizer.processImage(inputImage);
          final result2 = await thaiRecognizer.processImage(inputImage);

          final text1 = result1.text;
          final text2 = result2.text;
          final rawText = text1.length > text2.length ? text1 : text2;

          if (rawText.isEmpty) continue;

          // ตรวจสอบว่าน่าจะเป็น Slip โอนเงินหรือเปล่า
          if (!_isLikelySlip(rawText)) continue;

          final parsed = SlipParser.parse(rawText);
          if (!parsed.isValid) continue;

          // หาหมวดหมู่ที่ตรงกับ keyword
          final categoryId = slipService.findMatchingCategory(
            parsed.note,
            categories,
          );

          // บันทึกลง Supabase
          final slip = await slipService.createSlip(
            amount: parsed.amount!,
            date: parsed.date ?? asset.createDateTime,
            note: parsed.note,
            localAssetId: asset.id,
            categoryId: categoryId,
          );

          ref.read(slipsProvider.notifier).addSlip(slip);
          found++;

          ref.read(importProgressProvider.notifier).state = ImportProgress(
            total: filtered.length,
            processed: i + 1,
            found: found,
            isRunning: true,
          );
        } catch (_) {
          continue; // ข้ามรูปที่ error
        }
      }

      _importedCount = found;
      setState(() => _isDone = true);
    } finally {
      textRecognizer.close();
      thaiRecognizer.close();
      ref.read(importProgressProvider.notifier).state =
          const ImportProgress(isRunning: false);
    }
  }

  /// ตรวจสอบว่า OCR text น่าจะเป็น Slip โอนเงินหรือเปล่า
  bool _isLikelySlip(String text) {
    final keywords = [
      'โอนเงิน', 'โอนสำเร็จ', 'transfer', 'payment',
      'บาท', '฿', 'สำเร็จ', 'PromptPay', 'พร้อมเพย์',
      'KBank', 'SCB', 'BBL', 'KTB', 'TTB', 'BAY',
      'ธนาคาร', 'จำนวน',
    ];
    final lower = text.toLowerCase();
    return keywords.any((kw) => lower.contains(kw.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(importProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('นำเข้า Slip')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isDone
              ? _buildDoneView()
              : progress.isRunning
                  ? _buildProgressView(progress)
                  : _buildSetupView(),
        ),
      ),
    );
  }

  // ─── Setup View ──────────────────────────────────────────────────────────

  Widget _buildSetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📸', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text(
          'นำเข้า Slip จาก Gallery',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'แอพจะสแกนรูปภาพ Slip โอนเงินในคลังรูปของคุณ\nและอ่านข้อมูลอัตโนมัติ (ฟรี ไม่ส่งข้อมูลออกไป)',
          style: TextStyle(color: Colors.grey, height: 1.6),
        ),
        const SizedBox(height: 32),

        // เลือกเดือนเริ่มต้น
        const Text(
          'เริ่มดึงตั้งแต่เดือน',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickMonth,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6C63FF)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF6C63FF).withOpacity(0.05),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF6C63FF)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM yyyy', 'th').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF6C63FF)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (!_hasPermission) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.photo_library_outlined,
                    color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ต้องการสิทธิ์เข้าถึง Photo Library\nกดปุ่มด้านล่างเพื่อเปิดสิทธิ์',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        const Spacer(),
        ElevatedButton.icon(
          onPressed: _startImport,
          icon: const Icon(Icons.search),
          label: Text(_hasPermission ? 'เริ่มสแกน Slip' : 'เปิดสิทธิ์ Photo Library'),
        ),
        const SizedBox(height: 12),
        const Text(
          '* OCR ทำงานบนอุปกรณ์ ข้อมูลไม่ถูกส่งออก',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Progress View ───────────────────────────────────────────────────────

  Widget _buildProgressView(ImportProgress progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔍', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 24),
        const Text(
          'กำลังสแกน Slip...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          progress.currentFile ?? 'กำลังเตรียม...',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: progress.percentage,
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xFF6C63FF),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.processed}/${progress.total} รูป',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'พบ ${progress.found} Slip',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF43A047),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'กรุณารอสักครู่\nกำลังอ่านข้อมูลจาก Slip...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
      ],
    );
  }

  // ─── Done View ───────────────────────────────────────────────────────────

  Widget _buildDoneView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        const Text(
          'สแกนเสร็จแล้ว!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'พบ Slip ทั้งหมด $_importedCount รายการ',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('กลับหน้าหลัก'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isDone = false;
              _importedCount = 0;
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('สแกนอีกครั้ง'),
        ),
      ],
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'เลือกเดือนเริ่มต้น',
      locale: const Locale('th'),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }
}
